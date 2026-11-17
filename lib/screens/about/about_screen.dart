import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/hotel_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/common.dart';
import 'widgets/hotel_gallery.dart';
import 'widgets/hotel_overview.dart';
import 'widgets/review_section.dart';

/// Trang giới thiệu khách sạn: /about
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hotel = context.watch<HotelProvider>().hotel;
    return AppScaffold(
      child: ContentWrap(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            HotelGallery(images: hotel.images),
            const SizedBox(height: 20),
            HotelOverview(
              onSelectRoom: () =>
                  context.go(context.read<SearchProvider>().roomsLocation),
            ),
            const SizedBox(height: 28),
            const ReviewSection(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
