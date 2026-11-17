import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_footer.dart';
import '../widgets/common.dart';

/// Trang 404
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: ContentWrap(
        child: EmptyState(
          icon: Icons.explore_off_outlined,
          title: 'Không tìm thấy trang',
          message: 'Đường dẫn bạn truy cập không tồn tại.',
          action: ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Về trang chủ'),
          ),
        ),
      ),
    );
  }
}
