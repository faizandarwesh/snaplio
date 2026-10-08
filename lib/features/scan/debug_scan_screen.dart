import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/asset_thumb.dart';
import '../../services/scan_service.dart';

/// Developer screen to verify the scan pipeline fills the DB correctly.
/// Reachable from Settings → Diagnostics.
class DebugScanScreen extends ConsumerWidget {
  const DebugScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(libraryStatsProvider).value;
    final p = ref.watch(scanProgressProvider).value ?? ScanProgress.idle;
    final recent = ref.watch(recentScreenshotsProvider).value ?? const [];
    final service = ref.read(scanServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(Space.screen),
        children: [
          Text('Rows: ${stats?.total ?? 0} · processed: ${stats?.processed ?? 0} · ${formatBytes(stats?.bytes ?? 0)}', style: context.text.titleSmall),
          const SizedBox(height: Space.xs),
          Text('Phase: ${p.phase.name} · ${p.processed}/${p.total}', style: context.text.bodyMedium),
          if (p.error != null) Text('Error: ${p.error}', style: TextStyle(color: context.colors.danger)),
          const SizedBox(height: Space.sm),
          LinearProgressIndicator(value: p.isRunning ? p.fraction : null, minHeight: 4),
          const SizedBox(height: Space.sm),
          Wrap(spacing: 8, children: [
            FilledButton(onPressed: p.isRunning ? null : service.scan, child: const Text('Incremental scan')),
            OutlinedButton(onPressed: p.isRunning ? null : service.rescanAll, child: const Text('Re-scan all')),
          ]),
          const Divider(height: Space.xl),
          for (final r in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 56, height: 96, child: AssetThumb(r.assetId, size: 160)),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${r.category} · ${r.sourceApp ?? '-'} · ${formatBytes(r.sizeBytes)}', style: context.text.labelMedium),
                        Text(r.fileName, style: context.text.labelSmall),
                        Text(
                          r.processedAt == null ? '(pending)' : (r.ocrText ?? '(no text)'),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
