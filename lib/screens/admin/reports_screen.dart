import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/search_fields.dart';
import 'widgets/admin_widgets.dart';

enum _Report {
  guests('Khách đến / đi'),
  availability('Phòng trống'),
  revenue('Doanh thu');

  const _Report(this.label);
  final String label;
}

/// Báo cáo: khách đến/đi, phòng trống và doanh thu (doanh thu chỉ Quản lý xem)
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _Report _report = _Report.guests;

  @override
  Widget build(BuildContext context) {
    final isManager = context.watch<AuthProvider>().isManager;
    return AdminPage(
      title: 'Báo cáo thống kê',
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final r in _Report.values)
            if (r != _Report.revenue || isManager)
              ChoiceChip(
                label: Text(r.label),
                selected: _report == r,
                onSelected: (_) => setState(() => _report = r),
              ),
        ]),
        const SizedBox(height: 20),
        switch (_report) {
          _Report.guests => const _GuestReport(),
          _Report.availability => const _AvailabilityReport(),
          _Report.revenue => const _RevenueReport(),
        },
      ],
    );
  }
}

/// Khách sẽ nhận / trả phòng hôm nay và ngày mai
class _GuestReport extends StatelessWidget {
  const _GuestReport();

  Widget _table(String title, List<Booking> list) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(title),
          AdminTable(
            emptyText: 'Không có khách',
            columns: const ['Mã đơn', 'Khách', 'Điện thoại', 'Phòng'],
            rows: [
              for (final b in list)
                DataRow(cells: [
                  DataCell(Text(Fmt.bookingCode(b.id))),
                  DataCell(Text(b.guestName)),
                  DataCell(Text(b.guestPhone)),
                  DataCell(Text('${b.roomNumber} · ${b.roomTypeName}')),
                ]),
            ],
          ),
          const SizedBox(height: 20),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookingProvider>();
    final today = Fmt.today;
    final tomorrow = today.add(const Duration(days: 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _table('Nhận phòng hôm nay', prov.arrivals(today)),
        _table('Trả phòng hôm nay', prov.departures(today)),
        _table('Nhận phòng ngày mai', prov.arrivals(tomorrow)),
        _table('Trả phòng ngày mai', prov.departures(tomorrow)),
      ],
    );
  }
}

/// Phòng trống theo khoảng ngày và loại phòng
class _AvailabilityReport extends StatefulWidget {
  const _AvailabilityReport();

  @override
  State<_AvailabilityReport> createState() => _AvailabilityReportState();
}

class _AvailabilityReportState extends State<_AvailabilityReport> {
  DateTime _checkIn = Fmt.today;
  DateTime _checkOut = Fmt.today.add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final hotels = context.watch<HotelProvider>();
    final prov = context.watch<BookingProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 340,
            child: DateRangeField(
              checkIn: _checkIn,
              checkOut: _checkOut,
              onChanged: (r) => setState(() {
                _checkIn = r.start;
                _checkOut = r.end;
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AdminTable(
          columns: const ['Loại phòng', 'Số phòng trống', 'Các phòng', 'Giá/đêm'],
          rows: [
            for (final t in hotels.activeRoomTypes)
              () {
                final free = prov.freeRooms(t.id, _checkIn, _checkOut);
                return DataRow(cells: [
                  DataCell(Text(t.name)),
                  DataCell(Text('${free.length}')),
                  DataCell(Text(free.isEmpty
                      ? '-'
                      : free.map((r) => r.number).join(', '))),
                  DataCell(Text(Fmt.vnd(t.pricePerNight))),
                ]);
              }(),
          ],
        ),
      ],
    );
  }
}

/// Doanh thu theo thời gian và theo loại phòng
class _RevenueReport extends StatefulWidget {
  const _RevenueReport();

  @override
  State<_RevenueReport> createState() => _RevenueReportState();
}

class _RevenueReportState extends State<_RevenueReport> {
  RevenuePeriod _period = RevenuePeriod.month;
  DateTimeRange? _range;

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
      initialDateRange: _range,
      helpText: 'Lọc theo ngày lập hóa đơn',
      saveText: 'Áp dụng',
    );
    if (r != null) setState(() => _range = r);
  }

  Widget _table(String firstColumn, List<RevenueRow> rows) => AdminTable(
        emptyText: 'Chưa có doanh thu',
        columns: [firstColumn, 'Số hóa đơn', 'Tiền phòng', 'Tiền dịch vụ', 'Doanh thu'],
        rows: [
          for (final r in rows)
            DataRow(cells: [
              DataCell(Text(r.label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text('${r.invoices}')),
              DataCell(Text(Fmt.vnd(r.roomRevenue))),
              DataCell(Text(Fmt.vnd(r.serviceRevenue))),
              DataCell(Text(Fmt.vnd(r.total))),
            ]),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookingProvider>();
    final from = _range?.start;
    final to = _range?.end;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final p in RevenuePeriod.values)
              ChoiceChip(
                label: Text(p.label),
                selected: _period == p,
                onSelected: (_) => setState(() => _period = p),
              ),
            OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range),
              label: Text(_range == null
                  ? 'Tất cả thời gian'
                  : '${Fmt.date(_range!.start)} - ${Fmt.date(_range!.end)}'),
            ),
            if (_range != null)
              IconButton(
                tooltip: 'Bỏ lọc ngày',
                onPressed: () => setState(() => _range = null),
                icon: const Icon(Icons.clear),
              ),
          ],
        ),
        const SizedBox(height: 16),
        StatCard(
            label: 'Tổng doanh thu',
            value: Fmt.vnd(prov.revenue(from: from, to: to)),
            icon: Icons.payments),
        const SizedBox(height: 20),
        _table('Thời gian', prov.revenueByPeriod(_period, from: from, to: to)),
        const SizedBox(height: 20),
        const SectionTitle('Doanh thu theo loại phòng'),
        _table('Loại phòng', prov.revenueByRoomType(from: from, to: to)),
      ],
    );
  }
}
