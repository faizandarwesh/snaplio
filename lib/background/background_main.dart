import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../services/smart_notifier.dart';
import 'background_services.dart';

/// Body of the headless engine started by the native ScreenshotJobService
/// (see packages/snaplio_native HeadlessRunner for the protocol).
Future<void> runHeadlessEngine() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Dart-side plugin implementations (shared_preferences, path_provider…).
  DartPluginRegistrant.ensureInitialized();

  const channel = MethodChannel('snaplio/background');
  BackgroundServices? services;

  channel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'run':
        final task = (call.arguments as Map?)?['task'] as String? ?? 'scan';
        try {
          final s = services ??= await BackgroundServices.open();
          await applyPendingOps(expenses: s.expenses, shots: s.shots);
          if (task == 'scan') await s.scanNewAndNotify();
          await s.pushWidgets();
        } catch (e, st) {
          debugPrint('Background task $task failed: $e\n$st');
        }
        return null;
      case 'dispose':
        await services?.dispose();
        services = null;
        return null;
    }
    return null;
  });
  await channel.invokeMethod<void>('ready');
}
