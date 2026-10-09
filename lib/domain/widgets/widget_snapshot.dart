import 'package:intl/intl.dart';

import '../expense/money.dart';
import '../expense/spend_summary.dart';

/// Latest counted receipt for the snapshot widget.
class LatestReceipt {
  const LatestReceipt(this.amountMinor, this.currency, this.payee);
  final int amountMinor;
  final String currency;
  final String? payee;
}

/// Pre-formatted strings for the Android snapshot widget (bound as-is by
/// SnapshotWidgetProvider). Pure Dart.
Map<String, String> buildWidgetSnapshot({
  required MonthSpend spend,
  required LatestReceipt? latest,
  required int cleanableBytes,
  required int unreadLinks,
  required String Function(int bytes) formatBytes,
}) {
  final pct = spend.changePct;
  final prevName = DateFormat.MMM().format(previousMonth(spend.month));
  final String change;
  final String dir;
  if (pct == null) {
    change = spend.totalMinor == 0 ? 'Nothing tracked yet' : 'First month tracked';
    dir = 'flat';
  } else if (pct.abs() < 0.5) {
    change = 'Same as $prevName';
    dir = 'flat';
  } else {
    change = '${pct > 0 ? '▲' : '▼'} ${pct.abs().round()}% vs $prevName';
    dir = pct > 0 ? 'up' : 'down';
  }
  return {
    'spend_label': '${DateFormat.MMMM().format(spend.month)} spend',
    'spend_total': formatMoneyMinor(spend.totalMinor, spend.currency),
    'spend_change': change,
    'spend_dir': dir,
    'receipt_value': latest == null ? '—' : formatMoneyMinor(latest.amountMinor, latest.currency),
    'receipt_label': latest == null ? 'No receipts yet' : (latest.payee ?? 'Latest receipt'),
    'clean_value': cleanableBytes <= 0 ? '0 MB' : formatBytes(cleanableBytes),
    'links_value': '$unreadLinks',
    'links_label': unreadLinks == 1 ? 'unread link' : 'unread links',
  };
}
