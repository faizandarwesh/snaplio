import 'dart:convert';

import '../expense/expense_category.dart';
import '../expense/money.dart';
import '../expense/spend_summary.dart';
import '../models.dart';

/// Minimal screenshot view for the recap. Pure Dart.
class RecapShot {
  const RecapShot(this.createdAt, this.category, this.sourceApp);
  final DateTime createdAt;
  final ScreenshotCategory category;
  final String? sourceApp;
}

class RecapLink {
  const RecapLink(this.assetId, this.url, this.display);
  final String assetId;
  final String url;
  final String display;

  String get host => (Uri.tryParse(url)?.host ?? display).replaceFirst(RegExp(r'^www\.'), '');

  Map<String, Object?> toJson() => {'a': assetId, 'u': url, 'd': display};
  static RecapLink fromJson(Map<String, dynamic> j) => RecapLink(j['a'] as String, j['u'] as String, j['d'] as String);
}

/// One week, frozen when it was generated.
class WeeklyRecap {
  const WeeklyRecap({
    required this.weekStart,
    required this.weekEnd,
    required this.screenshots,
    required this.receipts,
    required this.spentMinor,
    required this.currency,
    required this.topCategory,
    required this.topCategoryMinor,
    required this.unreadLinks,
    required this.links,
    required this.cleanableBytes,
    required this.topSourceApp,
    required this.topSourceAppCount,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int screenshots;
  final int receipts;
  final int spentMinor;
  final String currency;
  final ExpenseCategory? topCategory;
  final int topCategoryMinor;
  final int unreadLinks;

  /// Up to 5 unread links to open from the story.
  final List<RecapLink> links;
  final int cleanableBytes;
  final String? topSourceApp;
  final int topSourceAppCount;

  /// Fewer than this and the week isn't worth a notification.
  static const minScreenshots = 3;
  bool get worthNotifying => screenshots >= minScreenshots;

  /// "31 screenshots · Rs 12,400 spent · 3 unread links · 180 MB to clean"
  String summaryLine(String Function(int bytes) bytes) => [
        '$screenshots screenshot${screenshots == 1 ? '' : 's'}',
        if (spentMinor > 0) '${formatMoneyMinor(spentMinor, currency)} spent',
        if (unreadLinks > 0) '$unreadLinks unread link${unreadLinks == 1 ? '' : 's'}',
        if (cleanableBytes >= 1024 * 1024) '${bytes(cleanableBytes)} to clean',
      ].join(' · ');

  Map<String, Object?> toJson() => {
        'ws': weekStart.millisecondsSinceEpoch,
        'we': weekEnd.millisecondsSinceEpoch,
        'n': screenshots,
        'r': receipts,
        's': spentMinor,
        'c': currency,
        'tc': topCategory?.name,
        'tcm': topCategoryMinor,
        'ul': unreadLinks,
        'l': [for (final l in links) l.toJson()],
        'cb': cleanableBytes,
        'app': topSourceApp,
        'appn': topSourceAppCount,
      };

  String encode() => jsonEncode(toJson());

  static WeeklyRecap decode(String s) {
    final j = jsonDecode(s) as Map<String, dynamic>;
    int i(String k) => (j[k] as num?)?.toInt() ?? 0;
    return WeeklyRecap(
      weekStart: DateTime.fromMillisecondsSinceEpoch(i('ws')),
      weekEnd: DateTime.fromMillisecondsSinceEpoch(i('we')),
      screenshots: i('n'),
      receipts: i('r'),
      spentMinor: i('s'),
      currency: j['c'] as String? ?? 'PKR',
      topCategory: j['tc'] == null ? null : ExpenseCategory.fromName(j['tc'] as String),
      topCategoryMinor: i('tcm'),
      unreadLinks: i('ul'),
      links: [for (final l in (j['l'] as List? ?? const []).cast<Map<String, dynamic>>()) RecapLink.fromJson(l)],
      cleanableBytes: i('cb'),
      topSourceApp: j['app'] as String?,
      topSourceAppCount: i('appn'),
    );
  }
}

/// Computes a recap for [start, end). Pure Dart.
WeeklyRecap computeWeeklyRecap({
  required DateTime start,
  required DateTime end,
  required Iterable<RecapShot> shots,
  required Iterable<SpendEntry> spend,
  required List<RecapLink> unreadLinks,
  required int cleanableBytes,
  required String currency,
}) {
  bool inWeek(DateTime d) => !d.isBefore(start) && d.isBefore(end);
  final week = [for (final s in shots) if (inWeek(s.createdAt)) s];

  final apps = <String, int>{};
  for (final s in week) {
    if (s.sourceApp != null) apps[s.sourceApp!] = (apps[s.sourceApp!] ?? 0) + 1;
  }
  final topApp = apps.isEmpty ? null : (apps.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;

  var spent = 0;
  var receipts = 0;
  final byCat = <ExpenseCategory, int>{};
  for (final e in spend) {
    if (!inWeek(e.date) || !e.countsAsSpend || e.currency != currency) continue;
    receipts++;
    spent += e.amountMinor;
    byCat[e.category] = (byCat[e.category] ?? 0) + e.amountMinor;
  }
  final topCat = byCat.isEmpty ? null : (byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;

  return WeeklyRecap(
    weekStart: start,
    weekEnd: end,
    screenshots: week.length,
    receipts: receipts,
    spentMinor: spent,
    currency: currency,
    topCategory: topCat?.key,
    topCategoryMinor: topCat?.value ?? 0,
    unreadLinks: unreadLinks.length,
    links: unreadLinks.take(5).toList(),
    cleanableBytes: cleanableBytes,
    topSourceApp: topApp?.key,
    topSourceAppCount: topApp?.value ?? 0,
  );
}

/// When the recap goes out (default Sunday 7 PM local).
class RecapSchedule {
  const RecapSchedule({this.enabled = true, this.weekday = DateTime.sunday, this.hour = 19, this.minute = 0});

  final bool enabled;

  /// [DateTime.monday] … [DateTime.sunday].
  final int weekday;
  final int hour;
  final int minute;

  /// Don't deliver a recap that is staler than this (phone was off for days).
  static const grace = Duration(days: 2);

  /// The latest scheduled moment at or before [now].
  DateTime lastOccurrence(DateTime now) {
    var d = DateTime(now.year, now.month, now.day, hour, minute);
    final back = (now.weekday - weekday) % 7;
    d = DateTime(d.year, d.month, d.day - back, hour, minute);
    if (d.isAfter(now)) d = DateTime(d.year, d.month, d.day - 7, hour, minute);
    return d;
  }

  DateTime nextOccurrence(DateTime now) {
    final last = lastOccurrence(now);
    return DateTime(last.year, last.month, last.day + 7, hour, minute);
  }

  /// The occurrence that should be delivered now, or null. [lastDelivered]
  /// is the occurrence handled most recently (sent or skipped).
  DateTime? due(DateTime now, DateTime? lastDelivered) {
    if (!enabled) return null;
    final occ = lastOccurrence(now);
    if (now.difference(occ) > grace) return null;
    if (lastDelivered != null && !lastDelivered.isBefore(occ)) return null;
    return occ;
  }

  /// The 7 days a recap delivered at [occurrence] covers.
  static (DateTime, DateTime) weekFor(DateTime occurrence) =>
      (DateTime(occurrence.year, occurrence.month, occurrence.day - 7, occurrence.hour, occurrence.minute), occurrence);
}
