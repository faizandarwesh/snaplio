import '../entity_extractor/entity_extractor.dart';
import 'expense_category.dart';
import 'money.dart';

enum ExpenseType {
  expense,
  income;

  static ExpenseType fromName(String? n) => n == 'income' ? income : expense;
}

/// What a receipt screenshot says about a payment. Pure data.
class ExtractedExpense {
  const ExtractedExpense({
    required this.amountMinor,
    required this.currency,
    required this.currencyExplicit,
    required this.type,
    required this.payee,
    required this.transactionId,
    required this.date,
    required this.dateFromText,
    required this.category,
    required this.categoryFromRule,
    required this.confidence,
  });

  final int amountMinor;
  final String currency;

  /// False when no symbol/code was printed and [currency] is the default.
  final bool currencyExplicit;
  final ExpenseType type;
  final String? payee;
  final String? transactionId;
  final DateTime date;
  final bool dateFromText;
  final ExpenseCategory category;
  final bool categoryFromRule;

  /// 0–1. Below [ExpenseExtractor.reviewThreshold] the expense needs review.
  final double confidence;

  bool get needsReview => confidence < ExpenseExtractor.reviewThreshold;

  @override
  String toString() =>
      'ExtractedExpense(${type.name} $currency $amountMinor, payee: $payee, tid: $transactionId, '
      '${category.name}, ${date.toIso8601String()}, conf: ${confidence.toStringAsFixed(2)})';
}

class _Amount {
  const _Amount(this.line, this.minor, this.currency, this.explicit);
  final int line;
  final int minor;
  final String? currency;
  final bool explicit;
}

/// Receipt → expense extraction over OCR text. Pure Dart, unit tested.
class ExpenseExtractor {
  const ExpenseExtractor({this.mapper = const CategoryMapper()});

  final CategoryMapper mapper;

  static const reviewThreshold = 0.6;

  // ------------------------------------------------------------- Amounts

  static const _curPrefix = r'(?:rs\.?|pkr\.?|usd|us\$|eur|gbp|inr|aed|sar|dhs?\.?|\$|€|£|₹)';
  static const _curSuffix = r'(?:pkr|usd|eur|gbp|inr|aed|sar|rs|dhs?)';
  static const _num = r'(?:\d{1,3}(?:,\d{2,3})+|\d+)(?:\.\d{1,2})?';
  static final _prefixRe = RegExp('(?<![a-z])($_curPrefix)\\s?($_num)(?![\\d%])', caseSensitive: false);
  static final _suffixRe = RegExp('(?<![\\d.,])($_num)\\s?($_curSuffix)\\b', caseSensitive: false);
  static final _bareRe = RegExp(r'(?<![\d.,:/\-+])(\d{1,3}(?:,\d{2,3})+(?:\.\d{1,2})?|\d{2,7}\.\d{2}|\d{2,7})(?![\d%:/])');

  /// Lines whose amount is the payment itself, strongest first.
  static final _strongKeyRe = RegExp(
    r'\b(?:grand\s*total|total\s*amount|amount\s*paid|total\s*paid|amount\s*(?:sent|transferred|received)|you\s*(?:paid|sent|received)|total\s*due|amount\s*due|bill\s*amount|net\s*(?:amount|total|payable)|transfer\s*amount|transaction\s*amount|total\s*payable)\b',
    caseSensitive: false,
  );
  static final _keyRe = RegExp(
    r'\b(?:total|paid|sent|transferred|amount|received|charged|payment|debited|credited)\b',
    caseSensitive: false,
  );

  /// Lines that hold side amounts (never preferred).
  static final _softSkipRe = RegExp(
    r'\b(?:sub\s?-?total|fees?|charges?|tax|vat|gst|discount|delivery|tip|service|savings?|saved|packaging|rounding|change|tendered|cash\s*given)\b',
    caseSensitive: false,
  );

  /// Lines whose amounts are never the payment.
  static final _hardSkipRe = RegExp(
    r'\b(?:balance|limit|available|cashback|reward|points|previous|outstanding|late\s*payment|after\s*due|min(?:imum)?\s*(?:due|payment))\b',
    caseSensitive: false,
  );

  static String _normalizeCurrency(String raw, String defaultCurrency) {
    final k = raw.toLowerCase().replaceAll('.', '').trim();
    switch (k) {
      case 'rs':
        return defaultCurrency == 'INR' ? 'INR' : 'PKR';
      case 'dh':
      case 'dhs':
        return 'AED';
      case r'us$':
        return 'USD';
    }
    return EntityExtractor.normalizeCurrency(k);
  }

  List<_Amount> _amounts(List<String> lines, String defaultCurrency) {
    final out = <_Amount>[];
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      final spans = <int>{};
      for (final m in _prefixRe.allMatches(l)) {
        final v = parseMinor(m.group(2)!);
        if (v != null && v > 0 && spans.add(m.start)) {
          out.add(_Amount(i, v, _normalizeCurrency(m.group(1)!, defaultCurrency), true));
        }
      }
      for (final m in _suffixRe.allMatches(l)) {
        final v = parseMinor(m.group(1)!);
        // Skip if this number was already read as a prefix amount.
        final already = _prefixRe.allMatches(l).any((p) => p.end >= m.start + m.group(1)!.length && p.start <= m.start);
        if (v != null && v > 0 && !already && spans.add(m.start)) {
          out.add(_Amount(i, v, _normalizeCurrency(m.group(2)!, defaultCurrency), true));
        }
      }
    }
    return out;
  }

  /// Amounts printed without a currency, only on (or right after) keyword lines.
  List<_Amount> _bareAmounts(List<String> lines) {
    final out = <_Amount>[];
    for (var i = 0; i < lines.length; i++) {
      final keyed = _keyRe.hasMatch(lines[i]) || (i > 0 && _isLabelOnly(lines[i - 1]) && _keyRe.hasMatch(lines[i - 1]));
      if (!keyed || _hardSkipRe.hasMatch(lines[i])) continue;
      // Dates, times and IDs on the same line are not amounts.
      final cleaned = lines[i]
          .replaceAll(RegExp(r'\d{1,4}[/\-.]\d{1,2}[/\-.]\d{2,4}'), ' ')
          .replaceAll(RegExp(r'\d{1,2}:\d{2}'), ' ');
      for (final m in _bareRe.allMatches(cleaned)) {
        final v = parseMinor(m.group(1)!);
        if (v != null && v > 0) out.add(_Amount(i, v, null, false));
      }
    }
    return out;
  }

  static bool _isLabelOnly(String line) => !RegExp(r'\d').hasMatch(line) && line.trim().length <= 32;

  int _priority(List<String> lines, int i) {
    final l = lines[i];
    if (_hardSkipRe.hasMatch(l)) return -2;
    final prev = i > 0 && _isLabelOnly(lines[i - 1]) ? lines[i - 1] : '';
    final strong = _strongKeyRe.hasMatch(l) || _strongKeyRe.hasMatch(prev);
    if (strong) return 3;
    if (_softSkipRe.hasMatch(l) || (prev.isNotEmpty && _softSkipRe.hasMatch(prev))) return -1;
    if (_keyRe.hasMatch(l) || _keyRe.hasMatch(prev)) return 2;
    return 0;
  }

  _Amount? _pickAmount(List<String> lines, List<_Amount> amounts) {
    if (amounts.isEmpty) return null;
    _Amount? best;
    var bestP = -3;
    for (final a in amounts) {
      final p = _priority(lines, a.line);
      if (p < -1) continue;
      // Keyword lines win; within a tier, the largest amount wins.
      final tier = p >= 2 ? p : 0;
      if (best == null || tier > bestP || (tier == bestP && a.minor > best.minor)) {
        best = a;
        bestP = tier;
      }
    }
    return best;
  }

  // ----------------------------------------------------------------- Type

  static final _incomeRe = RegExp(
    r"\b(?:you(?:'ve|\s+have)?\s+received|received\s+from|money\s+received|amount\s+received|funds?\s+received|has\s+been\s+credited|credited\s+(?:to|in(?:to)?)\s+your|incoming|deposit(?:ed)?\s+(?:to|in(?:to)?)\s+your|refund(?:ed)?)\b",
    caseSensitive: false,
  );
  static final _expenseSignalRe = RegExp(
    r'\b(?:sent\s+to|paid\s+to|transferred\s+to|you\s+(?:paid|sent)|debited|beneficiary|bill\s+payment|purchase|received\s+your\s+payment|payment\s+(?:has\s+been\s+)?received)\b',
    caseSensitive: false,
  );

  ExpenseType _type(String text) {
    if (_incomeRe.hasMatch(text) && !_expenseSignalRe.hasMatch(text)) return ExpenseType.income;
    return ExpenseType.expense;
  }

  // ---------------------------------------------------------------- Payee

  static const _expenseLabels =
      r'paid\s+to|sent\s+to|transferred\s+to|transfer\s+to|beneficiary(?:\s+(?:name|title))?|merchant(?:\s+name)?|recipient(?:\s+name)?|receiver(?:\s+name)?|biller(?:\s+name)?|(?:to\s+)?account\s+title|payee(?:\s+name)?|to';
  static const _incomeLabels = r'received\s+from|sender(?:\s+name)?|sent\s+by|from';

  static final _junkPayeeRe = RegExp(
    r'^(?:account|your|my|iban|a/c|number|no\.?|name|title|bank|wallet|mobile|details?|the|home|favou?rites?|contacts?)\b',
    caseSensitive: false,
  );

  static String? _cleanPayee(String raw) {
    var v = raw
        // Trailing account / phone numbers, masked numbers and amounts.
        .replaceAll(RegExp(r'[\s,\-|(]*(?:\+?\d[\d\s\-*xX]{5,}\d)\)?\s*$'), '')
        .replaceAll(RegExp(r'\b(?:rs\.?|pkr|usd|aed|sar|\$|₹)\s?[\d,.]+.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    v = v.replaceAll(RegExp(r'^[\s:\-–|]+|[\s:\-–|,.]+$'), '');
    final letters = RegExp(r'\p{L}', unicode: true).allMatches(v).length;
    if (letters < 2 || v.length > 48) return null;
    if (_junkPayeeRe.hasMatch(v)) return null;
    return v;
  }

  String? _labeledPayee(List<String> lines, ExpenseType type) {
    final labels = type == ExpenseType.income ? _incomeLabels : _expenseLabels;
    final inline = RegExp('^\\s*(?:$labels)\\s*[:\\-–]?\\s+(.+)\$', caseSensitive: false);
    final inlineColon = RegExp('^\\s*(?:$labels)\\s*[:\\-–]\\s*(.+)\$', caseSensitive: false);
    final alone = RegExp('^\\s*(?:$labels)\\s*[:\\-–]?\\s*\$', caseSensitive: false);
    // Mid-line forms: "Rs 500 sent to Ali Khan", "received Rs 500 from Sara".
    final midExpense = RegExp(r'\b(?:sent|paid|transferred)\s+to\s+([^\n]+)', caseSensitive: false);
    final midIncome = RegExp(r'\breceived\b.*?\bfrom\s+([^\n]+)', caseSensitive: false);

    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      final m = inlineColon.firstMatch(l) ?? inline.firstMatch(l);
      if (m != null) {
        final v = _cleanPayee(m.group(1)!);
        if (v != null) return v;
      }
      if (alone.hasMatch(l)) {
        for (var j = i + 1; j < lines.length && j <= i + 2; j++) {
          if (alone.hasMatch(lines[j])) break;
          final v = _cleanPayee(lines[j]);
          if (v != null) return v;
        }
      }
    }
    final mid = type == ExpenseType.income ? midIncome : midExpense;
    for (final l in lines) {
      final m = mid.firstMatch(l);
      if (m != null) {
        final v = _cleanPayee(m.group(1)!.split(RegExp(r'\s+(?:on|at|via|for|ref)\b', caseSensitive: false)).first);
        if (v != null) return v;
      }
    }
    return null;
  }

  /// Display names for brands found anywhere in the text.
  static final List<(RegExp, String)> _knownMerchants = [
    for (final e in const {
      r'food\s?panda': 'foodpanda',
      'kfc': 'KFC',
      r"mcdonald'?s?": "McDonald's",
      'cheezious': 'Cheezious',
      'daraz': 'Daraz',
      'amazon': 'Amazon',
      'uber eats': 'Uber Eats',
      'careem': 'Careem',
      'uber': 'Uber',
      r'in\s?drive': 'inDrive',
      'bykea': 'Bykea',
      'yango': 'Yango',
      r'k-?electric': 'K-Electric',
      'ssgc': 'SSGC',
      'sngpl': 'SNGPL',
      'ptcl': 'PTCL',
      'lesco': 'LESCO',
      'iesco': 'IESCO',
      r'jazz(?!\s?cash)': 'Jazz',
      'zong': 'Zong',
      r'telenor(?!\s?microfinance)': 'Telenor',
      'ufone': 'Ufone',
      'nayatel': 'Nayatel',
      r'storm\s?fiber': 'StormFiber',
      'pso': 'PSO',
      'shell': 'Shell',
      'netflix': 'Netflix',
      'spotify': 'Spotify',
      'starbucks': 'Starbucks',
      'imtiaz': 'Imtiaz',
      'carrefour': 'Carrefour',
      'talabat': 'Talabat',
      'chughtai': 'Chughtai Lab',
      'dawaai': 'Dawaai',
      'pizza hut': 'Pizza Hut',
      "domino'?s": "Domino's",
    }.entries)
      (RegExp('(?<![\\p{L}\\p{N}])(?:${e.key})(?![\\p{L}\\p{N}])', caseSensitive: false, unicode: true), e.value),
  ];

  String? _knownMerchant(String text) {
    String? best;
    var bestPos = 1 << 30;
    for (final (re, name) in _knownMerchants) {
      final m = re.firstMatch(text);
      // Earliest mention wins (the header usually names the merchant).
      if (m != null && m.start < bestPos) {
        best = name;
        bestPos = m.start;
      }
    }
    return best;
  }

  // ----------------------------------------------------------- Transaction

  static const _tidLabel =
      r'(?:tid|trx\.?\s?id|txn\.?\s?id|transaction\s?(?:id|no\.?|number|ref(?:erence)?(?:\s?no\.?)?)|ref(?:erence)?\.?\s?(?:no\.?|number|#|id|code)?|rrn|stan|order\s?(?:id|#|no\.?|number)|receipt\s?(?:no\.?|#|number)|invoice\s?(?:no\.?|#|number))';
  static final _tidInlineRe = RegExp('\\b$_tidLabel\\s*[:#.\\-]?\\s*([A-Z0-9][A-Z0-9\\-]{3,40})', caseSensitive: false);
  static final _tidAloneRe = RegExp('^\\s*$_tidLabel\\s*[:#.\\-]?\\s*\$', caseSensitive: false);
  static final _tidValueRe = RegExp(r'^\s*#?([A-Z0-9][A-Z0-9\-]{3,40})\s*$', caseSensitive: false);

  static bool _looksLikeId(String v) => RegExp(r'\d').allMatches(v).length >= 4;

  String? _transactionId(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final m = _tidInlineRe.firstMatch(lines[i]);
      if (m != null && _looksLikeId(m.group(1)!)) return m.group(1)!.toUpperCase();
      if (_tidAloneRe.hasMatch(lines[i]) && i + 1 < lines.length) {
        final v = _tidValueRe.firstMatch(lines[i + 1]);
        if (v != null && _looksLikeId(v.group(1)!)) return v.group(1)!.toUpperCase();
      }
    }
    return null;
  }

  // ----------------------------------------------------------------- Dates

  static const _monthNames = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };
  static final _timeRe = RegExp(r'\b(\d{1,2}):(\d{2})(?::\d{2})?\s?([ap])?\.?\s?m?\.?(?![\d])', caseSensitive: false);

  /// Parses a date string as found by [EntityExtractor.extractDates].
  /// Day-first unless [monthFirst] (US receipts) and the parts allow it.
  static DateTime? parseDate(String s, {bool monthFirst = false}) {
    var m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
    if (m != null) return _ymd(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    m = RegExp(r'^(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})$').firstMatch(s);
    if (m != null) {
      var a = int.parse(m[1]!), b = int.parse(m[2]!);
      var y = int.parse(m[3]!);
      if (y < 100) y += 2000;
      // a/b: pick the reading that is valid, preferring the locale's order.
      final dayFirst = a > 12 || (!monthFirst && b <= 12);
      if (!dayFirst) (a, b) = (b, a);
      return _ymd(y, b, a);
    }
    m = RegExp(r'^(\d{1,2})(?:st|nd|rd|th)?\s([a-z]+)\.?,?\s(\d{2,4})$', caseSensitive: false).firstMatch(s);
    if (m != null) {
      final mon = _monthNames[m[2]!.toLowerCase().substring(0, 3)];
      var y = int.parse(m[3]!);
      if (y < 100) y += 2000;
      return mon == null ? null : _ymd(y, mon, int.parse(m[1]!));
    }
    m = RegExp(r'^([a-z]+)\.?\s(\d{1,2})(?:st|nd|rd|th)?,?\s(\d{4})$', caseSensitive: false).firstMatch(s);
    if (m != null) {
      final mon = _monthNames[m[1]!.toLowerCase().substring(0, 3)];
      return mon == null ? null : _ymd(int.parse(m[3]!), mon, int.parse(m[2]!));
    }
    return null;
  }

  static DateTime? _ymd(int y, int mo, int d) {
    if (mo < 1 || mo > 12 || d < 1 || d > 31 || y < 2000 || y > 2100) return null;
    final dt = DateTime(y, mo, d);
    return dt.month == mo ? dt : null;
  }

  (DateTime, bool) _date(String text, List<String> lines, DateTime fallback, bool monthFirst) {
    final dates = const EntityExtractor().extractDates(text);
    for (final d in dates) {
      final parsed = parseDate(d.value, monthFirst: monthFirst);
      if (parsed == null) continue;
      // Due dates (after the screenshot) and ancient dates are not the payment date.
      if (parsed.isAfter(fallback.add(const Duration(days: 1)))) continue;
      if (parsed.isBefore(fallback.subtract(const Duration(days: 400)))) continue;
      if (parsed.year == fallback.year && parsed.month == fallback.month && parsed.day == fallback.day) {
        return (fallback, true);
      }
      // Look for a time on the date's line or the next one.
      final li = lines.indexWhere((l) => l.contains(d.value));
      for (final l in [if (li >= 0) lines[li], if (li >= 0 && li + 1 < lines.length) lines[li + 1]]) {
        final t = _timeRe.firstMatch(l.replaceFirst(d.value, ' '));
        if (t != null) {
          var h = int.parse(t[1]!);
          final min = int.parse(t[2]!);
          final ap = t[3]?.toLowerCase();
          if (ap == 'p' && h < 12) h += 12;
          if (ap == 'a' && h == 12) h = 0;
          if (h < 24 && min < 60) return (DateTime(parsed.year, parsed.month, parsed.day, h, min), true);
        }
      }
      return (DateTime(parsed.year, parsed.month, parsed.day, 12), true);
    }
    return (fallback, false);
  }

  // ---------------------------------------------------------------- Score

  static final _txnKeywordRe = RegExp(
    r'\b(?:paid|payment|transaction|transfer(?:red)?|successful(?:ly)?|sent|received|receipt|invoice|order|purchase|debited|credited|approved|tid|trx|txn|ibft|raast)\b',
    caseSensitive: false,
  );

  // ------------------------------------------------------------------ API

  /// Returns null when no payment amount can be found.
  ///
  /// [fallbackDate] is the screenshot's `createdAt`; [rules] maps learned
  /// payee keys to categories.
  ExtractedExpense? extract(
    String? text, {
    required DateTime fallbackDate,
    String defaultCurrency = 'PKR',
    Map<String, ExpenseCategory> rules = const {},
  }) {
    if (text == null || text.trim().isEmpty) return null;
    final lines = [for (final l in text.split('\n')) if (l.trim().isNotEmpty) l.trim()];

    var picked = _pickAmount(lines, _amounts(lines, defaultCurrency));
    picked ??= _pickAmount(lines, _bareAmounts(lines).where((a) => _priority(lines, a.line) >= 2).toList());
    if (picked == null) return null;

    final currency = picked.currency ?? defaultCurrency;
    final type = _type(text);
    final known = _knownMerchant(text);
    var payee = _labeledPayee(lines, type);
    if (type == ExpenseType.expense && known != null) {
      // A brand beats a generic label value ("Merchant: FOODPANDA PK 0042").
      if (payee == null || RegExp(RegExp.escape(known.split(' ').first), caseSensitive: false).hasMatch(payee)) {
        payee = known;
      }
    }
    final tid = _transactionId(lines);
    final (date, fromText) = _date(text, lines, fallbackDate, currency == 'USD');
    final cat = mapper.map(payee: payee, text: text, rules: rules);

    var confidence = _priority(lines, picked.line) >= 2 ? 0.45 : 0.35;
    if (picked.explicit) confidence += 0.05;
    if (payee != null) confidence += 0.25;
    if (_txnKeywordRe.hasMatch(text)) confidence += 0.2;
    if (tid != null) confidence += 0.05;

    return ExtractedExpense(
      amountMinor: picked.minor,
      currency: currency,
      currencyExplicit: picked.explicit,
      type: type,
      payee: payee,
      transactionId: tid,
      date: date,
      dateFromText: fromText,
      category: cat.category,
      categoryFromRule: cat.fromRule,
      confidence: confidence > 1 ? 1 : double.parse(confidence.toStringAsFixed(2)),
    );
  }
}
