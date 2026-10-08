import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/app_mark.dart';

/// Brand moment after the native splash: mark scales 0.8 → 1.0 with a glow,
/// wordmark fades/slides in. Total < 1.2s, and it routes as soon as both the
/// animation and the permission check are done.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _run();
    });
  }

  Future<void> _run() async {
    final reduce = context.reduceMotion;
    final routeFuture = _destination();
    if (!reduce) await _c.forward();
    final route = await routeFuture;
    if (!mounted) return;
    context.go(route);
  }

  Future<String> _destination() async {
    final settings = ref.read(settingsProvider);
    if (!settings.onboardingDone) return Routes.onboarding;
    final access = await ref.read(galleryAccessProvider.future);
    if (!access.canRead) return Routes.permission;
    return Routes.home;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = reduce ? 1.0 : _c.value;
            final mark = Curves.easeOutBack.transform((t / 0.7).clamp(0, 1));
            final word = Curves.easeOutCubic.transform(((t - 0.35) / 0.65).clamp(0, 1));
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.8 + 0.2 * mark,
                  child: AppMark(size: 96, glow: Curves.easeOut.transform(t)),
                ),
                const SizedBox(height: Space.lg),
                Opacity(
                  opacity: word,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - word)),
                    child: Text('SnapLio', style: context.text.headlineMedium),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
