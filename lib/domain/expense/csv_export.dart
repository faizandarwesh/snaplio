import 'money.dart';

class CsvExpense {
  const CsvExpense({
    required this.date,
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.payee,
    required this.category,
    required this.note,
    required this.transactionId,
    required this.source,
    required this.excluded,
  });

  final DateTime date;
  final String type;
  final int amountMinor;
  final String currency;
  final String? payee;
  final String category;
  final String note;
  final String? transactionId;
  final String source;
  final bool excluded;
}

String _cell(String? v) {
  final s = v ?? '';
  // Neutralize spreadsheet formulas and quote anything special (RFC 4180).
  final safe = RegExp(r'^[=+\-@]').hasMatch(s) ? "'$s" : s;
  if (safe.contains(RegExp(r'[",\n\r]'))) return '"${safe.replaceAll('"', '""')}"';
  return safe;
}

String _d(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// CSV for a month's expenses (oldest first). Pure Dart.
String expensesToCsv(Iterable<CsvExpense> rows) {
  final b = StringBuffer('Date,Type,Amount,Currency,Payee,Category,Note,Transaction ID,Source,Excluded\r\n');
  final sorted = rows.toList()..sort((a, b) => a.date.compareTo(b.date));
  for (final r in sorted) {
    b.write([
      _d(r.date),
      r.type,
      minorToDecimalString(r.amountMinor),
      r.currency,
      _cell(r.payee),
      _cell(r.category),
      _cell(r.note),
      _cell(r.transactionId),
      r.source,
      r.excluded ? 'yes' : 'no',
    ].join(','));
    b.write('\r\n');
  }
  return b.toString();
}
