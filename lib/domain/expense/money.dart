/// Money helpers. Amounts are always integer minor units (paisa, cents, fils);
/// doubles never touch money. Pure Dart.
library;

/// Every currency we detect uses 2 minor digits.
const kMinorDigits = 2;
const kMinorFactor = 100;

/// Currency symbol used in compact UI ("Rs 2,500", "$12.99").
const currencySymbols = <String, String>{
  'PKR': 'Rs',
  'INR': '₹',
  'USD': r'$',
  'EUR': '€',
  'GBP': '£',
  'AED': 'AED',
  'SAR': 'SAR',
};

/// Currencies offered in pickers, most likely first.
const supportedCurrencies = ['PKR', 'USD', 'AED', 'SAR', 'INR', 'EUR', 'GBP'];

/// Parses an amount as printed on a receipt ("2,500", "1,20,000", "12.99",
/// "2500.00") into minor units without going through a double.
/// Returns null for anything that is not a plain positive number.
int? parseMinor(String raw) {
  final s = raw.replaceAll(',', '').trim();
  final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(s);
  if (m == null) return null;
  final whole = int.tryParse(m.group(1)!);
  if (whole == null) return null;
  final frac = (m.group(2) ?? '').padRight(kMinorDigits, '0');
  return whole * kMinorFactor + int.parse(frac);
}

/// Parses user input from the amount field ("2500", "2,500.5").
int? parseUserAmount(String input) {
  final s = input.replaceAll(RegExp(r'[^\d.,]'), '');
  if (s.isEmpty) return null;
  final v = parseMinor(s);
  return v == null || v <= 0 ? null : v;
}

/// "2,500" / "12.99" — groups thousands, shows decimals only when non-zero.
String formatMinorNumber(int minor, {bool alwaysDecimals = false}) {
  final negative = minor < 0;
  final abs = minor.abs();
  final whole = abs ~/ kMinorFactor;
  final frac = abs % kMinorFactor;
  final digits = whole.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  if (frac != 0 || alwaysDecimals) buf.write('.${frac.toString().padLeft(kMinorDigits, '0')}');
  return '${negative ? '-' : ''}$buf';
}

/// "Rs 2,500", "$12.99", "AED 45".
String formatMoneyMinor(int minor, String currency) {
  final sym = currencySymbols[currency] ?? currency;
  final n = formatMinorNumber(minor);
  // Single-glyph symbols hug the number; codes get a space.
  return sym.length == 1 ? '$sym$n' : '$sym $n';
}

/// Compact form for tight spaces ("Rs 128.4k").
String formatMoneyCompact(int minor, String currency) {
  final major = minor / kMinorFactor;
  if (major.abs() < 10000) return formatMoneyMinor((major.round()) * kMinorFactor, currency);
  final sym = currencySymbols[currency] ?? currency;
  final String n;
  if (major.abs() >= 1e6) {
    n = '${(major / 1e6).toStringAsFixed(major.abs() >= 1e7 ? 0 : 1)}M';
  } else {
    n = '${(major / 1e3).toStringAsFixed(major.abs() >= 1e5 ? 0 : 1)}k';
  }
  return sym.length == 1 ? '$sym$n' : '$sym $n';
}

/// Plain decimal for CSV export ("2500.00").
String minorToDecimalString(int minor) {
  final abs = minor.abs();
  return '${minor < 0 ? '-' : ''}${abs ~/ kMinorFactor}.${(abs % kMinorFactor).toString().padLeft(2, '0')}';
}
