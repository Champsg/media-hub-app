import 'package:flutter/material.dart';

/// Brand palette for the dark "media cockpit" aesthetic.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF070B14);
  static const Color surface = Color(0xFF0F1522);
  static const Color surfaceHigh = Color(0xFF182136);
  static const Color border = Color(0xFF233150);
  static const Color primary = Color(0xFF7C5CFF);
  static const Color secondary = Color(0xFF00D4FF);
  static const Color accent = Color(0xFFFF5C8A);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF2F4FA);
  static const Color textSecondary = Color(0xFF8B96AD);
  static const Color textFaint = Color(0xFF5B6783);
}

class AppTheme {
  AppTheme._();

  static const LinearGradient brandGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.28),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh.withOpacity(0.72),
        hintStyle: const TextStyle(color: AppColors.textFaint),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border.withOpacity(0.6),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
