import 'package:flutter/services.dart';

/// Centralized haptics so the feel stays consistent across the app.
abstract final class Haptics {
  /// Tabs, chips, toggles, page changes.
  static void selection() => HapticFeedback.selectionClick();

  /// Card / button presses.
  static void light() => HapticFeedback.lightImpact();

  /// Success moments (delete done, scan done).
  static void medium() => HapticFeedback.mediumImpact();
}
