import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:snaplio_native/snaplio_native.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../domain/notifications/smart_notifications.dart';
import '../../services/prefs_keys.dart';
import '../../services/scan_service.dart';
import '../../services/smart_notifier.dart';

/// Global messenger so in-app toasts can show from anywhere.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

@immutable
class SmartState {
  const SmartState({required this.settings, required this.permission, required this.cardDismissed});

  final SmartSettings settings;
  final NotificationPermission permission;
  final bool cardDismissed;

  /// Notifications will actually be posted.
  bool get active => settings.enabled && permission == NotificationPermission.granted;

  SmartState copyWith({SmartSettings? settings, NotificationPermission? permission, bool? cardDismissed}) => SmartState(
        settings: settings ?? this.settings,
        permission: permission ?? this.permission,
        cardDismissed: cardDismissed ?? this.cardDismissed,
      );
}

/// Smart Actions in the app: permission + toggles, the foreground MediaStore
/// listener (instant processing + in-app toast), and catching up with what
/// the background job wrote while the app was away.
class SmartActionsController extends Notifier<SmartState> {
  bool _listening = false;
  Timer? _debounce;
  StreamSubscription<ProcessedShot>? _processedSub;

  @override
  SmartState build() {
    ref.onDispose(_stopListening);
    final p = ref.read(sharedPrefsProvider);
    return SmartState(
      settings: SmartSettingsStore.read(p),
      permission: NotificationPermission.unknown,
      cardDismissed: p.getBool(PrefsKeys.smartCardDismissed) ?? false,
    );
  }

  Future<void> refreshPermission() async {
    final perm = await SnapNative.permissionState();
    state = state.copyWith(permission: perm);
  }

  Future<void> onAppStart() async {
    await refreshPermission();
    // Keep the native flag in sync and (re)arm the content-trigger job.
    await SnapNative.setSmartActionsEnabled(state.active);
    await _catchUp();
    final access = await ref.read(galleryAccessProvider.future);
    if (access.canRead) _startListening();
  }

  Future<void> onResume() async {
    await ref.read(sharedPrefsProvider).reload();
    await ref.read(settingsProvider.notifier).reload();
    await refreshPermission();
    await _catchUp();
  }

  /// Applies notification actions taken while closed and refreshes live
  /// queries, since another engine may have written to the database.
  Future<void> _catchUp() async {
    await applyPendingOps(expenses: ref.read(expenseServiceProvider), shots: ref.read(repositoryProvider));
    ref.read(repositoryProvider).notifyExternalChanges();
  }

  /// Contextual opt-in: asks for POST_NOTIFICATIONS, then turns everything on.
  Future<bool> enable() async {
    final granted = await SnapNative.requestPermission();
    await refreshPermission();
    if (granted) await setEnabled(true, ask: false);
    return granted;
  }

  Future<void> setEnabled(bool on, {bool ask = true}) async {
    if (on && ask && state.permission != NotificationPermission.granted) {
      await enable();
      return;
    }
    await ref.read(sharedPrefsProvider).setBool(PrefsKeys.smartEnabled, on);
    state = state.copyWith(settings: _with(enabled: on));
    await SnapNative.setSmartActionsEnabled(state.active);
    Haptics.selection();
  }

  Future<void> setKind(SmartKind kind, bool on) async {
    final key = switch (kind) {
      SmartKind.otp => PrefsKeys.smartOtp,
      SmartKind.receipt => PrefsKeys.smartReceipts,
      SmartKind.link => PrefsKeys.smartLinks,
      SmartKind.address => PrefsKeys.smartAddresses,
      SmartKind.phone => PrefsKeys.smartPhones,
    };
    await ref.read(sharedPrefsProvider).setBool(key, on);
    state = state.copyWith(settings: SmartSettingsStore.read(ref.read(sharedPrefsProvider)));
    Haptics.selection();
  }

  Future<void> dismissCard() async {
    await ref.read(sharedPrefsProvider).setBool(PrefsKeys.smartCardDismissed, true);
    state = state.copyWith(cardDismissed: true);
  }

  SmartSettings _with({required bool enabled}) {
    final s = state.settings;
    return SmartSettings(enabled: enabled, otp: s.otp, receipts: s.receipts, links: s.links, addresses: s.addresses, phones: s.phones);
  }

  // ------------------------------------------------------ Foreground path

  void _startListening() {
    if (_listening) return;
    _listening = true;
    PhotoManager.addChangeCallback(_onMediaChange);
    PhotoManager.startChangeNotify();
    _processedSub = ref.read(scanServiceProvider).processed.listen(_onProcessed);
  }

  void _stopListening() {
    if (!_listening) return;
    _listening = false;
    PhotoManager.removeChangeCallback(_onMediaChange);
    PhotoManager.stopChangeNotify();
    _processedSub?.cancel();
    _debounce?.cancel();
  }

  bool get _foreground => WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  void _onMediaChange(MethodCall _) {
    if (!_foreground) return; // the background job owns this case
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(scanServiceProvider).scanNew(since: DateTime.now().subtract(const Duration(minutes: 10)));
    });
  }

  /// In-app toast instead of a system notification while the app is open.
  void _onProcessed(ProcessedShot shot) {
    if (!_foreground || DateTime.now().difference(shot.row.createdAt) > const Duration(minutes: 2)) return;
    final s = state.settings;
    // Toasts don't need notification permission; per-type choices still apply.
    final inApp = SmartSettings(otp: s.otp, receipts: s.receipts, links: s.links, addresses: s.addresses, phones: s.phones);
    final n = noticeFor(shotInfoOf(shot), inApp);
    if (n == null) return;
    Haptics.light();
    final primary = n.actions.first;
    rootMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Icon(_iconFor(n.kind), color: Brand.sky, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(n.title, maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
        action: SnackBarAction(label: primary.label, onPressed: () => runSmartAction(ref, n, primary)),
      ));
  }
}

IconData _iconFor(SmartKind k) => switch (k) {
      SmartKind.otp => Icons.password_rounded,
      SmartKind.receipt => Icons.receipt_long_rounded,
      SmartKind.link => Icons.link_rounded,
      SmartKind.address => Icons.map_outlined,
      SmartKind.phone => Icons.call_rounded,
    };

/// Runs a notice's action inside the app (toast buttons).
Future<void> runSmartAction(Ref ref, SmartNotice n, SmartAction a) async {
  Future<void> open(String uri) => launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
  switch (a.type) {
    case SmartActionType.copy:
      await Clipboard.setData(ClipboardData(text: a.value!));
    case SmartActionType.open:
      await ref.read(repositoryProvider).markLinkOpened(n.assetId, a.value!);
      await open(a.value!);
    case SmartActionType.maps:
      if (!await launchUrl(Uri.parse(a.value!), mode: LaunchMode.externalApplication)) {
        final q = Uri.parse(a.value!).queryParameters['q'] ?? '';
        await open(Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': q}).toString());
      }
    case SmartActionType.call:
    case SmartActionType.whatsapp:
      await open(a.value!);
    case SmartActionType.view:
      final id = Uri.parse(a.value!).pathSegments.firstOrNull;
      if (id != null) ref.read(routerProvider).push(Routes.expense(int.parse(id)));
    case SmartActionType.notExpense:
      await ref.read(expenseServiceProvider).setExcluded(a.expenseId!, true);
  }
}

final smartActionsProvider = NotifierProvider<SmartActionsController, SmartState>(SmartActionsController.new);
