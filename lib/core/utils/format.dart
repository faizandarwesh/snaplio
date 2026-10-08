import 'package:intl/intl.dart';

final _count = NumberFormat.decimalPattern();

String formatCount(int n) => _count.format(n);

String formatBytes(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return '0 MB';
  const kb = 1024, mb = kb * 1024, gb = mb * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(decimals)} GB';
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(bytes >= 100 * mb ? 0 : decimals)} MB';
  return '${(bytes / kb).toStringAsFixed(0)} KB';
}

String formatMoney(String currency, double amount) {
  final f = NumberFormat.decimalPatternDigits(decimalDigits: amount == amount.roundToDouble() ? 0 : 2);
  return '$currency ${f.format(amount)}';
}

String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 5) return 'Good night';
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String relativeDate(DateTime d, [DateTime? now]) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today, ${DateFormat.jm().format(d)}';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat.EEEE().format(d);
  if (d.year == n.year) return DateFormat.MMMd().format(d);
  return DateFormat.yMMMd().format(d);
}

String fullDate(DateTime d) => DateFormat('EEE, d MMM yyyy · h:mm a').format(d);
