import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Khung nội dung mỗi trang admin: tiêu đề + hành động + nội dung cuộn
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTheme.titleStyle),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTheme.subtitleStyle),
                ],
              ),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

/// Thẻ thống kê trên dashboard
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.subtitleStyle),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Bảng DataTable có cuộn ngang, giãn đủ chiều rộng
class AdminTable extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyText = 'Không có dữ liệu',
  });

  final List<String> columns;
  final List<DataRow> rows;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columnSpacing: 24,
                  showCheckboxColumn: false,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 72,
                  columns: [for (final c in columns) DataColumn(label: Text(c))],
                  rows: rows,
                ),
              ),
            ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(emptyText,
                    textAlign: TextAlign.center, style: AppTheme.subtitleStyle),
              ),
          ],
        );
      }),
    );
  }
}

/// Ô tìm kiếm dùng trên các trang admin
class AdminSearchField extends StatelessWidget {
  const AdminSearchField(
      {super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
        ),
      ),
    );
  }
}
