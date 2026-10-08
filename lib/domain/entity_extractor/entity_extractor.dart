import '../models.dart';

/// Regex-based entity extraction over OCR text. Pure Dart.
class EntityExtractor {
  const EntityExtractor();

  static const _maxPerType = 8;

  List<ExtractedEntity> extract(String? text) {
    if (text == null || text.trim().isEmpty) return const [];
    final emails = extractEmails(text);
    final out = <ExtractedEntity>{
      ...extractOtps(text),
      ...extractUrls(text, emails: emails),
      ...emails,
      ...extractPhones(text),
      ...extractAmounts(text),
      ...extractDates(text),
      ...extractTracking(text),
      ...extractAddresses(text),
    };
    return out.toList(growable: false);
  }

  // ---------------------------------------------------------------- URLs

  static const _tlds =
      'com|net|org|io|pk|co|app|dev|me|ly|gl|in|uk|ae|sa|info|biz|edu|gov|ai|tv|us|ca|de|fr|xyz|site|online|store|shop|link|page';
  static final _urlRe = RegExp(
    r'''(?:https?://|www\.)[^\s<>"'(){}\[\]]+|\b[a-z0-9][a-z0-9\-]*(?:\.[a-z0-9\-]+)*\.(?:'''
    '$_tlds'
    r''')\b(?:/[^\s<>"'(){}\[\]]*)?''',
    caseSensitive: false,
  );
  static final _trailingPunct = RegExp(r'[.,;:!?…]+$');

  List<ExtractedEntity> extractUrls(String text, {List<ExtractedEntity> emails = const []}) {
    final emailDomains = emails.map((e) => e.value.split('@').last.toLowerCase()).toSet();
    final out = <ExtractedEntity>[];
    for (final m in _urlRe.allMatches(text)) {
      // Skip the domain part of an e-mail address.
      if (m.start > 0 && text[m.start - 1] == '@') continue;
      var raw = m.group(0)!.replaceAll(_trailingPunct, '');
      if (raw.length < 4) continue;
      final lower = raw.toLowerCase();
      if (emailDomains.contains(lower)) continue;
      // Ignore things like "1.5.com" or version numbers that happen to end in a TLD.
      if (!RegExp(r'[a-z]{2,}', caseSensitive: false).hasMatch(lower.split('.').first) &&
          !lower.startsWith('http') &&
          !lower.startsWith('www.')) {
        continue;
      }
      final value = lower.startsWith('http') ? raw : 'https://$raw';
      out.add(ExtractedEntity(EntityType.url, value, raw));
      if (out.length >= _maxPerType) break;
    }
    return out;
  }

  // -------------------------------------------------------------- Emails

  static final _emailRe = RegExp(r'\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b');

  List<ExtractedEntity> extractEmails(String text) => _emailRe
      .allMatches(text)
      .take(_maxPerType)
      .map((m) => ExtractedEntity(EntityType.email, m.group(0)!.toLowerCase(), m.group(0)!))
      .toList();

  // -------------------------------------------------------------- Phones

  // Pakistani mobile: 03xx-xxxxxxx, +92 3xx xxxxxxx, 0092..., 923xx...
  static final _pkMobileRe = RegExp(r'(?<![\d+])(?:\+92|0092|92|0)[\s\-]?3\d{2}[\s\-]?\d{7}(?!\d)');
  // International: +<country> followed by 7–14 digits in groups.
  static final _intlRe = RegExp(r'(?<![\d\w])\+\d{1,3}[\s\-.]?\(?\d{1,4}\)?(?:[\s\-.]?\d{2,5}){1,4}(?!\d)');

  List<ExtractedEntity> extractPhones(String text) {
    final seen = <String>{};
    final out = <ExtractedEntity>[];

    void add(String display, String normalized) {
      if (seen.add(normalized)) {
        out.add(ExtractedEntity(EntityType.phone, normalized, display.trim()));
      }
    }

    for (final m in _pkMobileRe.allMatches(text)) {
      final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '');
      // Keep the last 10 digits (3xxxxxxxxx) and prefix the country code.
      final national = digits.substring(digits.length - 10);
      add(m.group(0)!, '+92$national');
    }
    for (final m in _intlRe.allMatches(text)) {
      final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 8 || digits.length > 15) continue;
      add(m.group(0)!, '+$digits');
    }
    return out.take(_maxPerType).toList();
  }

  // ---------------------------------------------------------------- OTPs

  static final _otpKeywordRe = RegExp(
    r'\b(?:otp|one[\s\-]?time|verification|verify|passcode|pin|security code|login code|auth(?:entication)? code|code)\b',
    caseSensitive: false,
  );
  // A standalone 4–8 digit run. Allows "G-583021" and a trailing full stop,
  // but not parts of amounts (1,250.00), times (10:42), dates or phone numbers.
  static final _codeRe = RegExp(r'(?<![\d,/:+]|\d[.\-])\d{4,8}(?![\d,/:%]|[.\-]\d)');

  List<ExtractedEntity> extractOtps(String text) {
    final keywords = _otpKeywordRe.allMatches(text).toList();
    if (keywords.isEmpty) return const [];
    final codes = <({int pos, String code})>[];
    for (final m in _codeRe.allMatches(text)) {
      final code = m.group(0)!;
      // Years are rarely OTPs.
      if (code.length == 4 && RegExp(r'^(19|20)\d{2}$').hasMatch(code)) continue;
      // Part of a currency amount → not an OTP.
      final before = text.substring((m.start - 5).clamp(0, text.length), m.start).toLowerCase();
      if (RegExp(r'(rs\.?|pkr|\$|€|£|₹|aed|sar|usd)\s*$').hasMatch(before)) continue;
      codes.add((pos: m.start, code: code));
    }
    if (codes.isEmpty) return const [];

    // Pick the code closest to any keyword, within ~80 characters.
    ({int pos, String code})? best;
    var bestDist = 1 << 30;
    for (final c in codes) {
      for (final k in keywords) {
        final dist = c.pos >= k.end ? c.pos - k.end : k.start - (c.pos + c.code.length);
        final d = dist < 0 ? 0 : dist;
        // Slight preference for codes that come after the keyword ("Your OTP is 1234").
        final score = c.pos >= k.start ? d : d + 10;
        if (d <= 80 && score < bestDist) {
          bestDist = score;
          best = c;
        }
      }
    }
    if (best == null) return const [];
    return [ExtractedEntity(EntityType.otp, best.code, best.code)];
  }

  // ------------------------------------------------------------- Amounts

  static const _cur = r'(?:rs\.?|pkr|usd|eur|gbp|inr|aed|sar|\$|€|£|₹)';
  static const _num = r'(?:\d{1,3}(?:,\d{2,3})+|\d+)(?:\.\d{1,2})?';
  static final _amountPrefixRe = RegExp('(?<![a-z])($_cur)\\s?($_num)', caseSensitive: false);
  static final _amountSuffixRe = RegExp('($_num)\\s?(pkr|usd|eur|gbp|inr|aed|sar|rs)\\b', caseSensitive: false);

  static String normalizeCurrency(String raw) {
    switch (raw.toLowerCase().replaceAll('.', '')) {
      case 'rs':
      case 'pkr':
        return 'PKR';
      case r'$':
      case 'usd':
        return 'USD';
      case '€':
      case 'eur':
        return 'EUR';
      case '£':
      case 'gbp':
        return 'GBP';
      case '₹':
      case 'inr':
        return 'INR';
      case 'aed':
        return 'AED';
      case 'sar':
        return 'SAR';
    }
    return raw.toUpperCase();
  }

  List<ExtractedEntity> extractAmounts(String text) {
    final out = <ExtractedEntity>[];
    final seenSpans = <int>{};
    void add(Match m, String cur, String number) {
      if (!seenSpans.add(m.start)) return;
      final n = double.tryParse(number.replaceAll(',', ''));
      if (n == null || n <= 0) return;
      final code = normalizeCurrency(cur);
      out.add(ExtractedEntity(EntityType.amount, '$code ${_fmtNum(n)}', m.group(0)!.trim()));
    }

    for (final m in _amountPrefixRe.allMatches(text)) {
      add(m, m.group(1)!, m.group(2)!);
    }
    for (final m in _amountSuffixRe.allMatches(text)) {
      add(m, m.group(2)!, m.group(1)!);
    }
    return out.take(_maxPerType).toList();
  }

  static String _fmtNum(double n) =>
      n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);

  /// Parses an amount entity value (`"PKR 1500"`) back to currency + number.
  static (String currency, double amount)? parseAmountValue(String value) {
    final parts = value.split(' ');
    if (parts.length != 2) return null;
    final n = double.tryParse(parts[1]);
    if (n == null) return null;
    return (parts[0], n);
  }

  // --------------------------------------------------------------- Dates

  static const _months =
      r'(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?';
  static final _dateRes = [
    RegExp(r'\b\d{4}-\d{2}-\d{2}\b'),
    RegExp(r'\b\d{1,2}[/\-.]\d{1,2}[/\-.](?:\d{4}|\d{2})\b'),
    RegExp('\\b\\d{1,2}(?:st|nd|rd|th)?\\s$_months,?\\s\\d{2,4}\\b', caseSensitive: false),
    RegExp('\\b$_months\\s\\d{1,2}(?:st|nd|rd|th)?,?\\s\\d{4}\\b', caseSensitive: false),
  ];

  List<ExtractedEntity> extractDates(String text) {
    final out = <ExtractedEntity>[];
    final covered = <int>[];
    for (final re in _dateRes) {
      for (final m in re.allMatches(text)) {
        if (covered.any((p) => p >= m.start && p < m.end)) continue;
        covered.add(m.start);
        out.add(ExtractedEntity(EntityType.date, m.group(0)!, m.group(0)!));
      }
    }
    return out.take(_maxPerType).toList();
  }

  // ------------------------------------------------------------ Tracking

  static final _trackingKeywordRe = RegExp(
    r'(?:tracking\s*(?:no\.?|number|id|#|code)?|consignment\s*(?:no\.?|number)?|awb|cn\s*(?:no\.?|#))\s*[:#\-]?\s*([A-Z0-9][A-Z0-9\-]{7,29})',
    caseSensitive: false,
  );
  static final _upuRe = RegExp(r'\b[A-Z]{2}\d{9}[A-Z]{2}\b');
  static final _upsRe = RegExp(r'\b1Z[0-9A-Z]{16}\b');

  List<ExtractedEntity> extractTracking(String text) {
    final out = <String>{};
    for (final m in _trackingKeywordRe.allMatches(text)) {
      final token = m.group(1)!;
      if (RegExp(r'\d').allMatches(token).length >= 4) out.add(token.toUpperCase());
    }
    for (final re in [_upuRe, _upsRe]) {
      for (final m in re.allMatches(text)) {
        out.add(m.group(0)!);
      }
    }
    return out.take(_maxPerType).map((t) => ExtractedEntity(EntityType.tracking, t, t)).toList();
  }

  // ----------------------------------------------------------- Addresses

  static final _addressLabelRe = RegExp(
    r'(?:^|\n)\s*(?:delivery |shipping |billing )?address\s*[:\-]\s*(.+)',
    caseSensitive: false,
  );
  static final _addressHintRe = RegExp(
    r'\b(?:house|h\.?\s?no|flat|apartment|apt|street|st\.|road|rd\.?|block|sector|phase|avenue|ave|lane|plaza|floor|town|colony|society|bahria|dha|gulberg|near)\b',
    caseSensitive: false,
  );

  List<ExtractedEntity> extractAddresses(String text) {
    final out = <String>{};
    for (final m in _addressLabelRe.allMatches(text)) {
      final line = m.group(1)!.trim();
      if (line.length >= 8) out.add(line);
    }
    if (out.isEmpty) {
      for (final line in text.split('\n')) {
        final l = line.trim();
        if (l.length < 12 || l.length > 120) continue;
        final hints = _addressHintRe.allMatches(l).length;
        final hasNumber = RegExp(r'\d').hasMatch(l);
        final hasComma = l.contains(',');
        if (hints >= 1 && hasNumber && hasComma) out.add(l);
      }
    }
    return out.take(3).map((a) => ExtractedEntity(EntityType.address, a, a)).toList();
  }
}
