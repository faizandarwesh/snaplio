import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/tokens.dart';

abstract final class AppTheme {
  static const fontFamily = 'PlusJakartaSans';

  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);
  static ThemeData light() => _build(Brightness.light, AppColors.light);

  static TextTheme _text(AppColors c) {
    TextStyle s(double size, FontWeight w, {double ls = 0, Color? color, double? h}) => TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          height: h,
          color: color ?? c.textPrimary,
        );
    return TextTheme(
      displayLarge: s(44, FontWeight.w800, ls: -1.4, h: 1.05),
      displayMedium: s(36, FontWeight.w700, ls: -1.0, h: 1.1),
      displaySmall: s(32, FontWeight.w700, ls: -0.8, h: 1.15),
      headlineMedium: s(26, FontWeight.w700, ls: -0.6, h: 1.2),
      headlineSmall: s(22, FontWeight.w700, ls: -0.4, h: 1.25),
      titleLarge: s(20, FontWeight.w600, ls: -0.3, h: 1.3),
      titleMedium: s(16, FontWeight.w600, ls: -0.1, h: 1.35),
      titleSmall: s(14, FontWeight.w600, h: 1.35),
      bodyLarge: s(15, FontWeight.w400, h: 1.5),
      bodyMedium: s(14, FontWeight.w400, h: 1.45, color: c.textSecondary),
      bodySmall: s(13, FontWeight.w400, h: 1.4, color: c.textSecondary),
      labelLarge: s(15, FontWeight.w600, h: 1.2),
      labelMedium: s(13, FontWeight.w600, h: 1.2),
      labelSmall: s(12, FontWeight.w500, ls: 0.1, h: 1.25, color: c.textSecondary),
    );
  }

  static ThemeData _build(Brightness b, AppColors c) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: Brand.violet,
      brightness: b,
    ).copyWith(
      primary: Brand.violet,
      onPrimary: Colors.white,
      secondary: Brand.sky,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      outlineVariant: c.border,
      error: c.danger,
    );
    final text = _text(c);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      splashFactory: InkSparkle.splashFactory,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: c.textPrimary),
        systemOverlayStyle: overlay(b),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surfaceElevated,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg))),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF2A2A35) : const Color(0xFF1D1D26),
        contentTextStyle: text.bodyLarge?.copyWith(color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
        insetPadding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, 100),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: Brand.violet.withValues(alpha: 0.18),
        side: BorderSide(color: c.border),
        shape: const StadiumBorder(),
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : c.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Brand.violet : c.surfaceElevated),
        trackOutlineColor: WidgetStateProperty.all(c.border),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: Brand.violet),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Brand.violet,
        selectionColor: Brand.violet.withValues(alpha: 0.3),
        selectionHandleColor: Brand.violet,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: PredictiveBackPageTransitionsBuilder()},
      ),
    );
  }

  /// Edge-to-edge: transparent status + navigation bars.
  static SystemUiOverlayStyle overlay(Brightness b) {
    final dark = b == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: b,
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    );
  }
}
