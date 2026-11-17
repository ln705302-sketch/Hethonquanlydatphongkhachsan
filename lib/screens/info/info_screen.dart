import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/info_pages.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/common.dart';
import '../not_found_screen.dart';

/// Trang thông tin: /info/help, /info/cancellation, /info/terms, /info/privacy
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final page = kInfoPages[slug];
    if (page == null) return const NotFoundScreen();

    return AppScaffold(
      child: ContentWrap(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Trang chủ'),
                    ),
                  ),
                  SectionTitle(page.title),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (heading, body) in page.sections) ...[
                            Text(heading,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            Text(body, style: const TextStyle(height: 1.6)),
                            const SizedBox(height: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
