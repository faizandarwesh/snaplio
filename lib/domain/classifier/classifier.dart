import '../models.dart';
import '../source_app.dart';
import '../text_utils.dart';

/// Rule-based screenshot classifier. Rules are evaluated in priority order and
/// the first match wins. Pure Dart.
class ScreenshotClassifier {
  const ScreenshotClassifier();

  static final _strongOtpRe = RegExp(
    r'\b(?:otp|one[\s\-]?time|verification|passcode|security code|login code)\b',
    caseSensitive: false,
  );
  static final _receiptRe = RegExp(
    r'\b(?:paid|payment|transaction|tid|trx|transfer(?:red)?|successful(?:ly)?|receipt|invoice|total|amount sent|sent to)\b',
    caseSensitive: false,
  );
  static final _orderRe = RegExp(
    r'\b(?:order\s?(?:#|no\.?|number|id|placed|confirmed)|your order|tracking|shipped|delivered|out for delivery|courier|dispatched|in transit|parcel|shipment)\b',
    caseSensitive: false,
  );
  static final _errorRe = RegExp(
    r'\b(?:error|exception|failed|failure|crash(?:ed)?|stack\s?trace|traceback|null(?:pointer)?|undefined|not responding|something went wrong|(?:http\s?)?(?:404|500|502|503))\b',
    caseSensitive: false,
  );
  static final _timestampLineRe = RegExp(
    r'\b\d{1,2}:\d{2}\s?(?:am|pm)\b',
    caseSensitive: false,
  );

  ScreenshotCategory classify({
    required String? text,
    required List<ExtractedEntity> entities,
    String? sourceApp,
  }) {
    final t = text ?? '';
    final words = wordCount(t);
    bool has(EntityType type) => entities.any((e) => e.type == type);

    // 1. OTP — a code near an OTP keyword. Bare "code"/"pin" only counts for
    //    short texts, so chats that mention a PIN don't get misfiled.
    if (has(EntityType.otp) && (_strongOtpRe.hasMatch(t) || words < 60)) {
      return ScreenshotCategory.otp;
    }

    // 2. Receipts — currency amount + payment language.
    if (has(EntityType.amount) && _receiptRe.hasMatch(t)) {
      return ScreenshotCategory.receipts;
    }

    // 3. Orders.
    if (_orderRe.hasMatch(t) || has(EntityType.tracking)) {
      return ScreenshotCategory.orders;
    }

    // 4. Errors.
    if (_errorRe.hasMatch(t)) return ScreenshotCategory.errors;

    // 5. Links — URL present and the text is short or URL-dominant.
    final urls = entities.where((e) => e.type == EntityType.url).toList();
    if (urls.isNotEmpty) {
      final urlChars = urls.fold<int>(0, (s, u) => s + u.displayValue.length);
      final textChars = t.replaceAll(RegExp(r'\s'), '').length;
      if (words <= 30 || (textChars > 0 && urlChars / textChars > 0.25)) {
        return ScreenshotCategory.links;
      }
    }

    // 6. Chats — messenger app, or several message timestamps on separate lines.
    if (sourceApp != null && messengerApps.contains(sourceApp)) {
      return ScreenshotCategory.chats;
    }
    final timestampLines = t.split('\n').where(_timestampLineRe.hasMatch).length;
    if (timestampLines >= 2) return ScreenshotCategory.chats;

    // 7. Notes & Info — long text.
    if (words > 40) return ScreenshotCategory.notes;

    // 8. Images & Memes — very little text.
    if (words < 5) return ScreenshotCategory.images;

    return ScreenshotCategory.others;
  }
}
