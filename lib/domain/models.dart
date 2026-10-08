/// Core domain types. Pure Dart — no Flutter imports, so everything in
/// `domain/` can be unit tested on the VM.
library;

enum ScreenshotCategory {
  otp('OTP', '🔐'),
  receipts('Receipts', '🧾'),
  orders('Orders', '📦'),
  errors('Errors', '⚠️'),
  links('Links', '🔗'),
  chats('Chats', '💬'),
  notes('Notes & Info', '📝'),
  images('Images & Memes', '🖼️'),
  others('Others', '📁');

  const ScreenshotCategory(this.label, this.emoji);

  final String label;
  final String emoji;

  static ScreenshotCategory fromName(String? name) =>
      values.firstWhere((c) => c.name == name, orElse: () => others);
}

enum EntityType {
  url,
  phone,
  email,
  otp,
  amount,
  date,
  address,
  tracking;

  static EntityType? fromName(String name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

class ExtractedEntity {
  const ExtractedEntity(this.type, this.value, this.displayValue);

  final EntityType type;

  /// Normalized, machine-usable value (e.g. `https://…`, `+923001234567`).
  final String value;

  /// What we show the user (close to what was on screen).
  final String displayValue;

  @override
  bool operator ==(Object other) =>
      other is ExtractedEntity && other.type == type && other.value == value;

  @override
  int get hashCode => Object.hash(type, value);

  @override
  String toString() => 'ExtractedEntity($type, $value)';
}

/// Everything the scan pipeline derives from one screenshot.
class AnalysisResult {
  const AnalysisResult({
    required this.category,
    required this.entities,
    required this.sourceApp,
    required this.textHash,
  });

  final ScreenshotCategory category;
  final List<ExtractedEntity> entities;
  final String? sourceApp;
  final String? textHash;
}
