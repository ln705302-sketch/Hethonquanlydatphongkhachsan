import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../widgets/common.dart';
import '../../../widgets/search_box.dart';

/// Banner lớn có ảnh nền và hộp tìm phòng
class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.isMobile(context);
    return Stack(
      children: [
        const Positioned.fill(child: NetImage(kHeroImage)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.overlay,
                  AppColors.primaryDark.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        ),
        ContentWrap(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: mobile ? 36 : 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng đến với\n${AppConstants.appName}',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: mobile ? 28 : 44,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Khách sạn 3 sao · Phòng Standard, Deluxe, Suite · Đặt phòng trực tiếp tại website',
                  style: TextStyle(color: AppColors.heroText, fontSize: 16),
                ),
                const SizedBox(height: 28),
                const SearchBox(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
