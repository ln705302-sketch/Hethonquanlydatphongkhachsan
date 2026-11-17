import 'package:flutter/material.dart';

import '../../widgets/app_footer.dart';
import '../../widgets/common.dart';
import '../../widgets/service_list.dart';

/// Trang dịch vụ: /services
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      child: ContentWrap(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle('Dịch vụ của khách sạn',
                  subtitle:
                      'Sau khi nhận phòng, hãy báo lễ tân để sử dụng. Chi phí được cộng vào hóa đơn khi trả phòng.'),
              ServiceList(),
            ],
          ),
        ),
      ),
    );
  }
}
