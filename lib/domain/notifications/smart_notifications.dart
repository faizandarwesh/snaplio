import 'dart:convert';

import '../expense/expense_extractor.dart';
import '../expense/money.dart';
import '../models.dart';

/// Which notification types the user allows (Settings → Smart Actions).
class SmartSettings {
  const SmartSettings({
    this.enabled = true,
    this.otp = true,
    this.receipts = true,
    this.links = true,
    this.addresses = true,
    this.phones = true,
  });

  final bool enabled;
  final bool otp;
  final bool receipts;
  final bool links;
  final bool addresses;
  final bool phones;

  static const off = SmartSettings(enabled: false);
}

enum SmartKind { otp, receipt, link, address, phone }

/// What a freshly processed screenshot contributed to Spend.
class ShotExpense {
  const ShotExpense({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.payee,
    required this.type,
    required this.likelyDuplicate,
  });

  final int id;
  final int amountMinor;
  final String currency;
  final String? payee;
  final ExpenseType type;
  final bool likelyDuplicate;
}

/// Everything the notifier needs to know about one new screenshot.
class ShotInfo {
  const ShotInfo({
    required this.assetId,
    required this.category,
    required this.entities,
    required this.words,
    required this.at,
    this.expense,
  });

  final String assetId;
  final ScreenshotCategory category;
  final List<ExtractedEntity> entities;
  final int words;
  final DateTime at;
  final ShotExpense? expense;
}

enum SmartActionType { copy, open, maps, call, whatsapp, view, notExpense }

class SmartAction {
  const SmartAction(this.type, this.label, {this.value, this.what, this.assetId, this.expenseId});
  final SmartActionType type;
  final String label;
  final String? value;
  final String? what;
  final String? assetId;
  final int? expenseId;
}

class SmartNotice {
  const SmartNotice({
    required this.kind,
    required this.assetId,
    required this.title,
    required this.body,
    required this.link,
    required this.actions,
  });

  final SmartKind kind;
  final String assetId;
  final String title;
  final String body;

  /// Deep link for a tap on the notification body.
  final String link;
  final List<SmartAction> actions;

  /// Stable per screenshot, so a re-run never posts a second one.
  int get id => notificationIdFor(assetId);
}

/// Notification id for a screenshot (MediaStore ids are numeric).
int notificationIdFor(String assetId) {
  final n = int.tryParse(assetId);
  final base = n ?? assetId.codeUnits.fold<int>(17, (h, c) => (h * 31 + c) & 0x3fffffff);
  return 1000 + base % 1000000000;
}

/// Id of the grouped "N screenshots sorted" summary.
const kSummaryNotificationId = 999;

const _silentCategories = {
  ScreenshotCategory.chats,
  ScreenshotCategory.notes,
  ScreenshotCategory.errors,
};

/// Decides whether a screenshot deserves a notification, and what it says.
/// One notice per screenshot at most; priority OTP > receipt > link >
/// address > phone. Chats, notes and errors never notify. Memes/Images and
/// Others never notify either — except a short screenshot that is basically
/// just an address or a phone number (the classifier files those under
/// Images/Others only because they have so few words).
SmartNotice? noticeFor(ShotInfo s, SmartSettings settings) {
  if (!settings.enabled || _silentCategories.contains(s.category)) return null;
  ExtractedEntity? first(EntityType t) {
    for (final e in s.entities) {
      if (e.type == t) return e;
    }
    return null;
  }

  final link = 'snaplio://screenshot/${Uri.encodeComponent(s.assetId)}';

  if (s.category == ScreenshotCategory.otp && settings.otp) {
    final otp = first(EntityType.otp);
    if (otp != null) {
      return SmartNotice(
        kind: SmartKind.otp,
        assetId: s.assetId,
        title: 'Code ${otp.value}',
        body: 'From your latest screenshot · tap Copy to paste it anywhere',
        link: link,
        actions: [SmartAction(SmartActionType.copy, 'Copy', value: otp.value, what: 'Code')],
      );
    }
  }

  if (s.category == ScreenshotCategory.receipts && settings.receipts && s.expense != null) {
    final x = s.expense!;
    final amount = formatMoneyMinor(x.amountMinor, x.currency);
    final income = x.type == ExpenseType.income;
    final who = x.payee == null ? '' : ' ${income ? 'from' : 'to'} ${x.payee}';
    final view = SmartAction(SmartActionType.view, 'View', value: 'snaplio://expense/${x.id}');
    if (x.likelyDuplicate) {
      return SmartNotice(
        kind: SmartKind.receipt,
        assetId: s.assetId,
        title: 'Possible duplicate · $amount$who',
        body: 'Looks like a payment you already have, so it isn\'t counted until you check it.',
        link: link,
        actions: [view],
      );
    }
    return SmartNotice(
      kind: SmartKind.receipt,
      assetId: s.assetId,
      title: '$amount$who · added to Spend',
      body: income ? 'Saved as income, kept apart from your spending.' : 'Tracked automatically from your screenshot.',
      link: link,
      actions: [view, SmartAction(SmartActionType.notExpense, income ? 'Don\'t track' : 'Not an expense', expenseId: x.id)],
    );
  }

  if (s.category == ScreenshotCategory.links && settings.links) {
    final url = first(EntityType.url);
    if (url != null) {
      final host = (Uri.tryParse(url.value)?.host ?? url.displayValue).replaceFirst(RegExp(r'^www\.'), '');
      return SmartNotice(
        kind: SmartKind.link,
        assetId: s.assetId,
        title: 'Link saved · $host',
        body: url.displayValue,
        link: link,
        actions: [
          SmartAction(SmartActionType.open, 'Open', value: url.value, assetId: s.assetId),
          SmartAction(SmartActionType.copy, 'Copy', value: url.value, what: 'Link'),
        ],
      );
    }
  }

  // Addresses and numbers: delivery screens (Orders) and short screenshots
  // that are basically just the address / number.
  final contactLike = s.category == ScreenshotCategory.orders ||
      s.category == ScreenshotCategory.links ||
      ((s.category == ScreenshotCategory.others || s.category == ScreenshotCategory.images) && s.words <= 30);
  if (!contactLike) return null;

  final address = first(EntityType.address);
  if (address != null && settings.addresses) {
    return SmartNotice(
      kind: SmartKind.address,
      assetId: s.assetId,
      title: 'Address detected',
      body: address.displayValue,
      link: link,
      actions: [
        SmartAction(SmartActionType.maps, 'Open in Maps', value: 'geo:0,0?q=${Uri.encodeComponent(address.value)}'),
      ],
    );
  }
  final phone = first(EntityType.phone);
  if (phone != null && settings.phones) {
    final digits = phone.value.replaceAll(RegExp(r'\D'), '');
    return SmartNotice(
      kind: SmartKind.phone,
      assetId: s.assetId,
      title: phone.displayValue,
      body: 'Number found in your latest screenshot',
      link: link,
      actions: [
        SmartAction(SmartActionType.call, 'Call', value: 'tel:${phone.value}'),
        SmartAction(SmartActionType.whatsapp, 'WhatsApp', value: 'https://wa.me/$digits'),
      ],
    );
  }
  return null;
}

// ---------------------------------------------------------------- Bursts

/// A screenshot seen recently (persisted between background runs).
class BurstEntry {
  const BurstEntry(this.assetId, this.category, this.at, {this.notified = false});

  final String assetId;
  final ScreenshotCategory category;
  final DateTime at;

  /// Whether it got its own notification (to cancel when grouping).
  final bool notified;

  Map<String, Object?> toJson() => {'a': assetId, 'c': category.name, 't': at.millisecondsSinceEpoch, 'n': notified};

  static BurstEntry fromJson(Map<String, dynamic> j) => BurstEntry(
        j['a'] as String,
        ScreenshotCategory.fromName(j['c'] as String?),
        DateTime.fromMillisecondsSinceEpoch((j['t'] as num).toInt()),
        notified: j['n'] == true,
      );

  static String encode(List<BurstEntry> l) => jsonEncode([for (final e in l) e.toJson()]);
  static List<BurstEntry> decode(String? s) {
    if (s == null || s.isEmpty) return [];
    try {
      return [for (final j in (jsonDecode(s) as List).cast<Map<String, dynamic>>()) fromJson(j)];
    } catch (_) {
      return [];
    }
  }
}

class SummaryNotice {
  const SummaryNotice(this.title, this.body);
  final String title;
  final String body;
}

class NotificationPlan {
  const NotificationPlan({required this.post, required this.cancel, required this.summary, required this.log});

  final List<SmartNotice> post;

  /// Individual notifications to withdraw because they are now grouped.
  final List<int> cancel;
  final SummaryNotice? summary;

  /// Updated burst log to persist.
  final List<BurstEntry> log;
}

/// Exactly one notification per screenshot; more than [burstLimit]
/// screenshots within [window] collapse into a single grouped summary.
class NotificationPlanner {
  const NotificationPlanner();

  static const window = Duration(seconds: 60);
  static const burstLimit = 3;

  static const _labels = {
    ScreenshotCategory.otp: ('code', 'codes'),
    ScreenshotCategory.receipts: ('receipt', 'receipts'),
    ScreenshotCategory.links: ('link', 'links'),
    ScreenshotCategory.orders: ('order', 'orders'),
  };

  NotificationPlan plan({
    required List<BurstEntry> log,
    required List<ShotInfo> shots,
    required SmartSettings settings,
    required DateTime now,
  }) {
    final recent = [for (final e in log) if (now.difference(e.at) <= window) e];
    final known = {for (final e in recent) e.assetId};
    final fresh = [for (final s in shots) if (!known.contains(s.assetId)) s];
    final notices = {for (final s in fresh) s.assetId: noticeFor(s, settings)};

    final all = [
      ...recent,
      for (final s in fresh) BurstEntry(s.assetId, s.category, now),
    ];
    final anyActionable = notices.values.any((n) => n != null) || recent.any((e) => e.notified);

    if (all.length > burstLimit && anyActionable) {
      final counts = <ScreenshotCategory, int>{};
      for (final e in all) {
        counts[e.category] = (counts[e.category] ?? 0) + 1;
      }
      final parts = [
        for (final c in _labels.keys)
          if ((counts[c] ?? 0) > 0) '${counts[c]} ${counts[c] == 1 ? _labels[c]!.$1 : _labels[c]!.$2}',
      ];
      return NotificationPlan(
        post: const [],
        cancel: [for (final e in recent) if (e.notified) notificationIdFor(e.assetId)],
        summary: SummaryNotice(
          '${all.length} screenshots sorted${parts.isEmpty ? '' : ' · ${parts.join(', ')}'}',
          'Tap to see them in SnapLio',
        ),
        // Keep "actionable" so later shots in the window still update the
        // summary (cancelling an already-cancelled id is harmless).
        log: [
          for (final e in all) BurstEntry(e.assetId, e.category, e.at, notified: e.notified || notices[e.assetId] != null),
        ],
      );
    }

    final post = [for (final n in notices.values) ?n];
    return NotificationPlan(
      post: post,
      cancel: const [],
      summary: null,
      log: [
        ...recent,
        for (final s in fresh) BurstEntry(s.assetId, s.category, now, notified: notices[s.assetId] != null),
      ],
    );
  }
}
