import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snaplio_native/snaplio_native.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/widgets/app_mark.dart';
import '../../core/widgets/pressable.dart';
import '../../services/prefs_keys.dart';
import 'smart_actions.dart';

/// Shown once, right after the first scan: "Turn on Smart Actions".
Future<void> maybeShowSmartActionsSheet(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(sharedPrefsProvider);
  if (prefs.getBool(PrefsKeys.smartSheetShown) ?? false) return;
  await ref.read(smartActionsProvider.notifier).refreshPermission();
  if (ref.read(smartActionsProvider).active || !context.mounted) return;
  await prefs.setBool(PrefsKeys.smartSheetShown, true);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _SmartSheet(),
  );
}

class _SmartSheet extends ConsumerStatefulWidget {
  const _SmartSheet();

  @override
  ConsumerState<_SmartSheet> createState() => _SmartSheetState();
}

class _SmartSheetState extends ConsumerState<_SmartSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.screen, Space.md, Space.screen, Space.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MockNotificationCarousel(),
            const SizedBox(height: Space.lg),
            Text('Turn on Smart Actions', style: context.text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: Space.xs),
            Text(
              'Take a screenshot and SnapLio reacts in seconds: copy a code, track a payment, open a link — right from the notification. Still 100% on your phone.',
              style: context.text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.lg),
            GradientButton(
              label: 'Turn on',
              icon: Icons.notifications_active_rounded,
              loading: _busy,
              onPressed: () async {
                setState(() => _busy = true);
                final ok = await ref.read(smartActionsProvider.notifier).enable();
                if (!context.mounted) return;
                if (ok) Haptics.medium();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: Space.xs),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not now')),
          ],
        ),
      ),
    );
  }
}

/// Android-style notification preview that cycles through examples.
class MockNotificationCarousel extends StatefulWidget {
  const MockNotificationCarousel({super.key});

  @override
  State<MockNotificationCarousel> createState() => _MockNotificationCarouselState();
}

class _MockNotificationCarouselState extends State<MockNotificationCarousel> {
  static const _examples = [
    (Icons.password_rounded, Color(0xFF9B87F5), 'Code 482913', 'Copy'),
    (Icons.receipt_long_rounded, Color(0xFF5BBF8A), 'Rs 2,500 to Ali Khan · added to Spend', 'View'),
    (Icons.link_rounded, Color(0xFF6B9EF2), 'Link saved · example.com', 'Open'),
  ];
  int _i = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (mounted) setState(() => _i = (_i + 1) % _examples.length);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, color, title, action) = _examples[_i];
    return SizedBox(
      height: 112,
      child: AnimatedSwitcher(
        duration: Motion.slow,
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(position: Tween(begin: const Offset(0, -0.35), end: Offset.zero).animate(a), child: child),
        ),
        child: Container(
          key: ValueKey(_i),
          padding: const EdgeInsets.all(Space.sm),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.border),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppMark(size: 18),
                  const SizedBox(width: 6),
                  Text('SnapLio · now', style: context.text.labelSmall),
                  const Spacer(),
                  Icon(icon, size: 16, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
              const Spacer(),
              Text(action.toUpperCase(), style: context.text.labelMedium?.copyWith(color: Brand.violet, letterSpacing: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home card while Smart Actions is off. Dismissible, never nags.
class SmartActionsHomeCard extends ConsumerWidget {
  const SmartActionsHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(smartActionsProvider);
    if (s.active || s.cardDismissed) return const SizedBox.shrink();
    final c = context.colors;
    final denied = s.permission == NotificationPermission.denied;
    final n = ref.read(smartActionsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.screen, Space.sm, Space.screen, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.xxs, Space.sm),
        decoration: BoxDecoration(
          borderRadius: Radii.mdAll,
          border: Border.all(color: Brand.violet.withValues(alpha: 0.25)),
          color: Brand.violet.withValues(alpha: context.isDark ? 0.12 : 0.07),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_outlined, color: Brand.violet),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(denied ? 'Notifications are off' : 'Smart Actions', style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    denied ? 'Allow them to copy codes and track receipts straight from new screenshots.' : 'Copy codes and track receipts the moment you take a screenshot.',
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Pressable(
                    onTap: () => denied ? SnapNative.openNotificationSettings() : n.enable(),
                    child: Text(denied ? 'Open settings' : 'Turn on', style: context.text.labelLarge?.copyWith(color: Brand.violet)),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: n.dismissCard,
              icon: Icon(Icons.close_rounded, size: 18, color: c.textTertiary),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: Motion.slow);
  }
}

/// Settings → "Not getting notifications?": OEM battery restrictions.
class BatteryHelpScreen extends ConsumerStatefulWidget {
  const BatteryHelpScreen({super.key});

  @override
  ConsumerState<BatteryHelpScreen> createState() => _BatteryHelpScreenState();
}

class _BatteryHelpScreenState extends ConsumerState<BatteryHelpScreen> with WidgetsBindingObserver {
  bool? _ignoring;
  bool? _notifications;
  String _maker = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final ignoring = await SnapNative.isIgnoringBatteryOptimizations();
    final notif = await SnapNative.notificationsEnabled();
    final info = await SnapNative.deviceInfo();
    if (mounted) {
      setState(() {
        _ignoring = ignoring;
        _notifications = notif;
        _maker = info.manufacturer.toLowerCase();
      });
    }
  }

  String get _tip {
    if (_maker.contains('xiaomi') || _maker.contains('redmi') || _maker.contains('poco')) {
      return 'Xiaomi / Redmi / POCO: Settings → Apps → SnapLio → turn on Autostart, then Battery saver → No restrictions.';
    }
    if (_maker.contains('oppo') || _maker.contains('realme') || _maker.contains('oneplus')) {
      return 'OPPO / realme / OnePlus: Settings → Apps → SnapLio → Battery → allow background activity and auto-launch.';
    }
    if (_maker.contains('vivo') || _maker.contains('iqoo')) {
      return 'vivo / iQOO: Settings → Battery → Background power consumption → SnapLio → Allow.';
    }
    if (_maker.contains('samsung')) {
      return 'Samsung: Settings → Battery → Background usage limits → remove SnapLio from Sleeping apps, then Apps → SnapLio → Battery → Unrestricted.';
    }
    if (_maker.contains('huawei') || _maker.contains('honor')) {
      return 'Huawei / Honor: Settings → Battery → App launch → SnapLio → Manage manually, allow all three.';
    }
    return 'Settings → Apps → SnapLio → Battery → Unrestricted (names differ by phone maker).';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget status(String label, bool? ok, String okText, String badText) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(ok == null ? Icons.more_horiz_rounded : (ok ? Icons.check_circle_rounded : Icons.error_outline_rounded),
                  size: 20, color: ok == null ? c.textTertiary : (ok ? c.success : const Color(0xFFE8A951))),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(label, style: context.text.bodyLarge)),
              Text(ok == null ? '' : (ok ? okText : badText), style: context.text.labelMedium),
            ],
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Not getting notifications?')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(Space.screen, Space.xs, Space.screen, MediaQuery.paddingOf(context).bottom + Space.xl),
        children: [
          Text(
            'SnapLio wakes up for a moment whenever you take a screenshot. Some phones stop apps from doing that to save battery — then Smart Actions arrive late, or not at all.',
            style: context.text.bodyLarge?.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: Space.lg),
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(color: c.surface, borderRadius: Radii.mdAll, border: Border.all(color: c.border)),
            child: Column(
              children: [
                status('Notifications', _notifications, 'Allowed', 'Off'),
                status('Battery optimization', _ignoring, 'Not restricted', 'Restricted'),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          if (_ignoring == false) ...[
            GradientButton(
              label: 'Allow background activity',
              icon: Icons.battery_charging_full_rounded,
              onPressed: SnapNative.requestIgnoreBatteryOptimizations,
            ),
            const SizedBox(height: Space.xs),
          ],
          if (_notifications == false) ...[
            SoftButton(label: 'Turn on notifications', icon: Icons.notifications_rounded, expand: true, onPressed: SnapNative.openNotificationSettings),
            const SizedBox(height: Space.xs),
          ],
          SoftButton(label: 'Open app settings', icon: Icons.settings_applications_outlined, expand: true, onPressed: SnapNative.openAppSettings),
          const SizedBox(height: Space.lg),
          Text('On your phone', style: context.text.titleSmall),
          const SizedBox(height: Space.xs),
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(color: Brand.violet.withValues(alpha: 0.08), borderRadius: Radii.mdAll),
            child: Text(_tip, style: context.text.bodyMedium?.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: Space.lg),
          Text(
            'Nothing leaves your phone either way — this only lets SnapLio run briefly after a screenshot.',
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}
