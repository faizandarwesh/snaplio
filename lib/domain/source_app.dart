/// Parses the app a screenshot was taken in from its file name.
///
/// Handles the common OEM patterns:
/// * Samsung / OneUI: `Screenshot_20261008-145012_WhatsApp.jpg`
/// * Xiaomi / MIUI:   `Screenshot_2026-10-08-14-50-12-345_com.whatsapp.jpg`
/// * Some Pixels:     `Screenshot_20261008-145012.png` (no app → null)
library;

const _packages = <String, String>{
  'com.whatsapp': 'WhatsApp',
  'com.whatsapp.w4b': 'WhatsApp Business',
  'com.android.chrome': 'Chrome',
  'com.instagram.android': 'Instagram',
  'com.google.android.gm': 'Gmail',
  'com.google.android.youtube': 'YouTube',
  'com.facebook.katana': 'Facebook',
  'com.facebook.orca': 'Messenger',
  'org.telegram.messenger': 'Telegram',
  'org.thoughtcrime.securesms': 'Signal',
  'com.twitter.android': 'X',
  'com.snapchat.android': 'Snapchat',
  'com.linkedin.android': 'LinkedIn',
  'com.google.android.apps.maps': 'Maps',
  'com.google.android.apps.messaging': 'Messages',
  'com.samsung.android.messaging': 'Messages',
  'com.android.mms': 'Messages',
  'com.discord': 'Discord',
  'com.Slack': 'Slack',
  'com.microsoft.teams': 'Teams',
  'com.viber.voip': 'Viber',
  'com.imo.android.imoim': 'imo',
  'com.daraz.android': 'Daraz',
  'com.zhiliaoapp.musically': 'TikTok',
  'com.android.settings': 'Settings',
  'com.google.android.apps.photos': 'Photos',
  'com.sec.android.app.sbrowser': 'Samsung Internet',
  'org.mozilla.firefox': 'Firefox',
  'com.microsoft.emmx': 'Edge',
  'com.amazon.mShop.android.shopping': 'Amazon',
  'com.google.android.apps.nbu.paisa.user': 'Google Pay',
  'com.techlogix.mobilinkcustomer': 'JazzCash',
  'pk.com.telenor.phoenix': 'Easypaisa',
};

const _names = <String, String>{
  'whatsapp': 'WhatsApp',
  'chrome': 'Chrome',
  'instagram': 'Instagram',
  'gmail': 'Gmail',
  'youtube': 'YouTube',
  'facebook': 'Facebook',
  'messenger': 'Messenger',
  'telegram': 'Telegram',
  'signal': 'Signal',
  'twitter': 'X',
  'x': 'X',
  'snapchat': 'Snapchat',
  'linkedin': 'LinkedIn',
  'maps': 'Maps',
  'messages': 'Messages',
  'discord': 'Discord',
  'slack': 'Slack',
  'teams': 'Teams',
  'viber': 'Viber',
  'tiktok': 'TikTok',
  'settings': 'Settings',
  'samsunginternet': 'Samsung Internet',
  'firefox': 'Firefox',
};

/// Messenger apps — a strong signal for the Chats category.
const messengerApps = {
  'WhatsApp',
  'WhatsApp Business',
  'Messenger',
  'Telegram',
  'Signal',
  'Messages',
  'Discord',
  'Slack',
  'Teams',
  'Viber',
  'imo',
  'Snapchat',
};

final _digitsOnly = RegExp(r'^[\d\-]+$');

String? parseSourceApp(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final base = dot > 0 ? fileName.substring(0, dot) : fileName;
  final parts = base.split('_');
  if (parts.length < 3) return null;
  if (!parts.first.toLowerCase().startsWith('screenshot')) return null;

  // Everything after the timestamp segment is the app (package names have no '_'
  // in practice, but join defensively).
  final app = parts.sublist(2).join('_').trim();
  if (app.isEmpty || _digitsOnly.hasMatch(app)) return null;

  if (app.contains('.')) {
    final known = _packages[app];
    if (known != null) return known;
    // Unknown package: use its most meaningful segment.
    final segs = app.split('.').where((s) => s.length > 2 && s != 'android' && s != 'app' && s != 'com').toList();
    if (segs.isEmpty) return null;
    return _titleCase(segs.first);
  }

  final key = app.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
  return _names[key] ?? app;
}

String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
