import 'package:flutter/material.dart';

import '../../widgets/app_footer.dart';
import '../../widgets/common.dart';
import 'widgets/hero_banner.dart';
import 'widgets/home_sections.dart';

/// Trang chủ: banner + tìm phòng, hạng phòng, dịch vụ, ưu đãi
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroBanner(),
          SizedBox(height: 48),
          ContentWrap(child: RoomTypeHighlights()),
          SizedBox(height: 48),
          ContentWrap(child: ServiceHighlights()),
          SizedBox(height: 48),
          ContentWrap(child: Promotions()),
          SizedBox(height: 48),
          ContentWrap(child: WhySunrise()),
          SizedBox(height: 56),
        ],
      ),
    );
  }
}
