import 'package:flutter/material.dart';

/// Bảng màu dùng chung toàn ứng dụng (lấy cảm hứng từ Trip.com)
class AppColors {
  AppColors._();

  static const primary = Color(0xFF287DFA);
  static const primaryDark = Color(0xFF1A5FCC);
  static const primaryLight = Color(0xFFEAF2FF);
  static const cta = Color(0xFFFF6F00);
  static const ctaDark = Color(0xFFE65100);

  static const background = Color(0xFFF5F7FA);
  static const white = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F294D);
  static const textSecondary = Color(0xFF5C6B80);
  static const border = Color(0xFFDADFE6);

  static const success = Color(0xFF00A86B);
  static const successLight = Color(0xFFE6F7F0);
  static const warning = Color(0xFFF5A623);
  static const warningLight = Color(0xFFFFF5E5);
  static const danger = Color(0xFFE53935);
  static const dangerLight = Color(0xFFFDECEC);
  static const star = Color(0xFFFFB400);

  static const footer = Color(0xFF0F294D);
  static const footerText = Color(0xB3FFFFFF);
  static const footerMuted = Color(0x99FFFFFF);
  static const footerDivider = Color(0x33FFFFFF);
  static const heroText = Color(0xE6FFFFFF);
  static const shadow = Color(0x1A0F294D);
  static const overlay = Color(0x8C000000);
  static const transparent = Color(0x00000000);
}

/// ThemeData tập trung - mọi màn hình dùng chung
class AppTheme {
  AppTheme._();

  static final BorderRadius radius = BorderRadius.circular(8);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.cta,
      surface: AppColors.white,
      error: AppColors.danger,
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: AppColors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        width: 420,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.white,
        surfaceTintColor: AppColors.transparent,
      ),
      dataTableTheme: const DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(AppColors.primaryLight),
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Nút CTA màu cam cho "Đặt ngay", "Tìm kiếm"
  static ButtonStyle get ctaButton => ElevatedButton.styleFrom(
        backgroundColor: AppColors.cta,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.border,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      );

  /// Nút màu đỏ cho thao tác nguy hiểm (xóa, hủy)
  static ButtonStyle get dangerButton => ElevatedButton.styleFrom(
        backgroundColor: AppColors.danger,
        foregroundColor: AppColors.white,
      );

  static const titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const subtitleStyle = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
}
