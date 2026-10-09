/// Dart API for SnapLio's Android bridge. Works in every engine; calls that
/// need an Activity (permission prompt, initial deep link) no-op elsewhere.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

enum NotificationPermission { granted, denied, unknown }

/// A notification action, wired natively so it works with the app closed.
class NativeAction {
  const NativeAction._(this.type, this.label, this.value, {this.what, this.assetId, this.expenseId});

  /// Copies [text]; [what] names it in the toast ("Code copied").
  const NativeAction.copy(String label, String text, {String what = 'Text'}) : this._('copy', label, text, what: what);

  /// Opens a URL; with [assetId], records the link as opened.
  const NativeAction.open(String label, String url, {String? assetId}) : this._('open', label, url, assetId: assetId);
  const NativeAction.maps(String label, String geoUri) : this._('maps', label, geoUri);
  const NativeAction.call(String label, String telUri) : this._('call', label, telUri);
  const NativeAction.whatsapp(String label, String url) : this._('whatsapp', label, url);

  /// Opens a deep link in the app.
  const NativeAction.view(String label, String link) : this._('view', label, link);
  const NativeAction.notExpense(String label, int expenseId) : this._('notExpense', label, null, expenseId: expenseId);

  final String type;
  final String label;
  final String? value;
  final String? what;
  final String? assetId;
  final int? expenseId;

  Map<String, Object?> toMap() => {
        'type': type,
        'label': label,
        'value': value,
        'what': what,
        'assetId': assetId,
        'expenseId': expenseId,
      };
}

/// Something the user did from a notification while no Dart was running.
class PendingOp {
  const PendingOp(this.op, this.data, this.at);
  final String op;
  final Map<String, Object?> data;
  final DateTime at;
}

abstract final class SnapNative {
  static const _ch = MethodChannel('snaplio/native');
  static final _links = StreamController<String>.broadcast();
  static bool _listening = false;

  static const channelSmart = 'smart_actions';
  static const channelRecap = 'weekly_recap';

  /// Deep links (`snaplio://…`) delivered while the app is running.
  static Stream<String> get links {
    if (!_listening) {
      _listening = true;
      _ch.setMethodCallHandler((call) async {
        if (call.method == 'onLink' && call.arguments is String) _links.add(call.arguments as String);
      });
    }
    return _links.stream;
  }

  static Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _ch.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null; // tests / non-Android
    } on PlatformException {
      return null;
    }
  }

  /// The link that launched the app (once).
  static Future<String?> initialLink() => _call<String>('getInitialLink');

  /// Arms (or disarms) the new-screenshot background job.
  static Future<void> setSmartActionsEnabled(bool enabled) => _call('setSmartActionsEnabled', {'enabled': enabled});

  /// Re-arms the job if Smart Actions is on (cheap; call on every app start).
  static Future<void> armScreenshotJob() => _call('armScreenshotJob');

  static Future<void> post({
    required int id,
    required String title,
    String? body,
    String? link,
    String channel = channelSmart,
    bool group = false,
    List<NativeAction> actions = const [],
  }) =>
      _call('postNotification', {
        'id': id,
        'title': title,
        'body': body,
        'link': link,
        'channel': channel,
        'group': group,
        'actions': [for (final a in actions) a.toMap()],
      });

  static Future<void> cancel(int id) => _call('cancelNotification', {'id': id});

  static Future<bool> notificationsEnabled() async => await _call<bool>('notificationsEnabled') ?? false;

  static Future<NotificationPermission> permissionState() async {
    final s = await _call<String>('notificationPermissionState');
    return NotificationPermission.values.firstWhere((p) => p.name == s, orElse: () => NotificationPermission.unknown);
  }

  /// Shows the Android 13+ prompt (or opens settings if permanently denied).
  static Future<bool> requestPermission() async => await _call<bool>('requestNotificationPermission') ?? false;

  static Future<void> openNotificationSettings() => _call('openNotificationSettings');
  static Future<void> openAppSettings() => _call('openAppSettings');

  static Future<bool> isIgnoringBatteryOptimizations() async => await _call<bool>('isIgnoringBatteryOptimizations') ?? true;
  static Future<void> requestIgnoreBatteryOptimizations() => _call('requestIgnoreBatteryOptimizations');

  static Future<({String manufacturer, String brand, int sdk})> deviceInfo() async {
    final m = await _call<Map<Object?, Object?>>('deviceInfo') ?? const {};
    return (
      manufacturer: (m['manufacturer'] as String?) ?? '',
      brand: (m['brand'] as String?) ?? '',
      sdk: (m['sdk'] as int?) ?? 0,
    );
  }

  /// Drains actions recorded natively (link opened, not an expense).
  static Future<List<PendingOp>> takePendingOps() async {
    final raw = await _call<String>('takePendingOps');
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final o in list.cast<Map<String, dynamic>>())
        PendingOp(
          o['op'] as String,
          o,
          DateTime.fromMillisecondsSinceEpoch((o['at'] as num?)?.toInt() ?? 0),
        ),
    ];
  }
}
