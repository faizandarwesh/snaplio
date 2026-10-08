import 'package:flutter/material.dart';

import '../../domain/models.dart';

/// Spacing on an 8pt grid.
abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double screen = 20;
}

abstract final class Radii {
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 350);
  static const enter = Curves.easeOutCubic;
  static const stagger = Duration(milliseconds: 30);
}

abstract final class Brand {
  static const violet = Color(0xFF7C5CFF);
  static const sky = Color(0xFF4FC3F7);
  static const gradient = LinearGradient(
    colors: [violet, sky],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Semantic surface + text colors, switched per theme.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.danger,
    required this.navGlass,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color success;
  final Color danger;
  final Color navGlass;

  static const dark = AppColors(
    background: Color(0xFF0B0B10),
    surface: Color(0xFF15151C),
    surfaceElevated: Color(0xFF1D1D26),
    border: Color(0x0FFFFFFF),
    textPrimary: Color(0xFFF4F4F6),
    textSecondary: Color(0xFF9A9AA8),
    textTertiary: Color(0xFF6E6E7B),
    success: Color(0xFF5FCB8E),
    danger: Color(0xFFF27D72),
    navGlass: Color(0xB31D1D26),
  );

  static const light = AppColors(
    background: Color(0xFFF5F5F8),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    border: Color(0x14000000),
    textPrimary: Color(0xFF111118),
    textSecondary: Color(0xFF5E5E6B),
    textTertiary: Color(0xFF8A8A97),
    success: Color(0xFF2E9E62),
    danger: Color(0xFFD9534A),
    navGlass: Color(0xCCFFFFFF),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      navGlass: Color.lerp(navGlass, other.navGlass, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// True when the user asked the OS to remove animations.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}

/// Per-category accent + icon. Soft, muted hues — never neon.
class CategoryStyle {
  const CategoryStyle(this.color, this.icon);

  final Color color;
  final IconData icon;

  Color tint(BuildContext context) => color.withValues(alpha: context.isDark ? 0.14 : 0.12);

  static CategoryStyle of(ScreenshotCategory c) => switch (c) {
        ScreenshotCategory.otp => const CategoryStyle(Color(0xFF9B87F5), Icons.password_rounded),
        ScreenshotCategory.receipts => const CategoryStyle(Color(0xFF5BBF8A), Icons.receipt_long_rounded),
        ScreenshotCategory.orders => const CategoryStyle(Color(0xFFE8A951), Icons.local_shipping_rounded),
        ScreenshotCategory.errors => const CategoryStyle(Color(0xFFEE7B6E), Icons.error_outline_rounded),
        ScreenshotCategory.links => const CategoryStyle(Color(0xFF6B9EF2), Icons.link_rounded),
        ScreenshotCategory.chats => const CategoryStyle(Color(0xFF4DBDB3), Icons.chat_bubble_outline_rounded),
        ScreenshotCategory.notes => const CategoryStyle(Color(0xFF8D9AB0), Icons.sticky_note_2_outlined),
        ScreenshotCategory.images => const CategoryStyle(Color(0xFFEB8DBA), Icons.image_outlined),
        ScreenshotCategory.others => const CategoryStyle(Color(0xFF8E8E9A), Icons.folder_outlined),
      };
}
