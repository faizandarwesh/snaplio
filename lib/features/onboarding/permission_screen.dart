import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/pressable.dart';
import '../../services/gallery_service.dart';

/// Asks for photo access with clear privacy copy. Handles first ask, denied,
/// permanently denied (→ settings) and Android 14 partial access.
class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _busy = false;
  int _deniedCount = 0;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from system settings: re-check and continue if granted.
    _lifecycle = AppLifecycleListener(onResume: () async {
      final a = await ref.read(galleryAccessProvider.notifier).refresh();
      if (a.canRead && mounted) context.go(Routes.firstScan);
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    setState(() => _busy = true);
    final gallery = ref.read(galleryServiceProvider);
    final current = ref.read(galleryAccessProvider).value;
    // After two denials Android stops showing the dialog — go to settings.
    if (current == GalleryAccess.denied && _deniedCount >= 2) {
      await gallery.openAppSettings();
      if (mounted) setState(() => _busy = false);
      return;
    }
    final result = await ref.read(galleryAccessProvider.notifier).request();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.canRead) {
      context.go(Routes.firstScan);
    } else {
      setState(() => _deniedCount++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final denied = _deniedCount > 0;
    final goSettings = _deniedCount >= 2;
    final reduce = context.reduceMotion;

    Widget enter(Widget w, int i) =>
        reduce ? w : w.animate().fadeIn(delay: (70 * i).ms, duration: 400.ms).moveY(begin: 12, end: 0, curve: Motion.enter);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Space.screen),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Column(
                children: [
                  const SizedBox(height: Space.xxl),
                  enter(
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: Brand.gradient,
                        boxShadow: [BoxShadow(color: Brand.violet.withValues(alpha: 0.4), blurRadius: 48)],
                      ),
                      child: const Icon(Icons.photo_library_rounded, size: 46, color: Colors.white),
                    ),
                    0,
                  ),
                  const SizedBox(height: Space.xl),
                  enter(Text('Let SnapLio see your screenshots', textAlign: TextAlign.center, style: context.text.displaySmall), 1),
                  const SizedBox(height: Space.sm),
                  enter(
                    Text(
                      'We read the text inside your screenshots to make them searchable. Only screenshots are processed.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyLarge?.copyWith(color: c.textSecondary),
                    ),
                    2,
                  ),
                  const SizedBox(height: Space.xl),
                  enter(
                    Container(
                      padding: const EdgeInsets.all(Space.md),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: Radii.mdAll,
                        border: Border.all(color: c.border),
                      ),
                      child: Column(
                        children: [
                          _Point(icon: Icons.phonelink_lock_rounded, text: 'Processed 100% on your device'),
                          _Point(icon: Icons.cloud_off_rounded, text: 'Nothing is uploaded — no account, no servers'),
                          _Point(icon: Icons.delete_outline_rounded, text: 'Nothing is deleted without your confirmation'),
                        ],
                      ),
                    ),
                    3,
                  ),
                  const SizedBox(height: Space.xl),
                  AnimatedSwitcher(
                    duration: Motion.medium,
                    child: denied
                        ? Padding(
                            key: ValueKey(goSettings),
                            padding: const EdgeInsets.only(bottom: Space.md),
                            child: Text(
                              goSettings
                                  ? 'Access is turned off. Open Settings → Permissions → Photos and allow access.'
                                  : 'SnapLio needs photo access to find your screenshots.',
                              textAlign: TextAlign.center,
                              style: context.text.bodyMedium?.copyWith(color: c.danger),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  GradientButton(
                    label: goSettings ? 'Open Settings' : 'Allow access',
                    icon: goSettings ? Icons.settings_rounded : Icons.lock_open_rounded,
                    loading: _busy,
                    onPressed: _request,
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    'On Android 14+ you can also pick “Select photos” — you can allow all later.',
                    textAlign: TextAlign.center,
                    style: context.text.labelSmall?.copyWith(color: c.textTertiary),
                  ),
                  const SizedBox(height: Space.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: c.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: c.success),
          ),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(text, style: context.text.bodyLarge)),
        ],
      ),
    );
  }
}
