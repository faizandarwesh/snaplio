import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/haptics.dart';
import '../../core/utils/format.dart';
import '../../data/screenshot_repository.dart';

class DeleteOutcome {
  const DeleteOutcome(this.count, this.bytes);
  final int count;
  final int bytes;
  bool get any => count > 0;
}

/// Deletes through MediaStore (system confirmation dialog on Android 11+), then
/// removes only the rows the system actually deleted.
Future<DeleteOutcome> deleteScreenshots(WidgetRef ref, List<ScreenshotRow> rows) async {
  if (rows.isEmpty) return const DeleteOutcome(0, 0);
  final gallery = ref.read(galleryServiceProvider);
  final repo = ref.read(repositoryProvider);
  final deleted = (await gallery.delete([for (final r in rows) r.assetId])).toSet();
  if (deleted.isEmpty) return const DeleteOutcome(0, 0);
  await repo.deleteByIds(deleted);
  ref.read(widgetSyncProvider).schedule();
  final bytes = rows.where((r) => deleted.contains(r.assetId)).fold<int>(0, (s, r) => s + r.sizeBytes);
  Haptics.medium();
  return DeleteOutcome(deleted.length, bytes);
}

Future<void> shareScreenshots(WidgetRef ref, List<ScreenshotRow> rows) async {
  final gallery = ref.read(galleryServiceProvider);
  final files = <XFile>[];
  for (final r in rows.take(30)) {
    final path = r.filePath ?? (await gallery.fileFor(r.assetId))?.path;
    if (path != null) files.add(XFile(path));
  }
  if (files.isEmpty) return;
  await SharePlus.instance.share(ShareParams(files: files));
}

void showFreedSnack(BuildContext context, DeleteOutcome o) {
  if (!o.any) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF5FCB8E)),
        const SizedBox(width: 10),
        Expanded(child: Text('Deleted ${formatCount(o.count)} · ${formatBytes(o.bytes)} freed')),
      ]),
    ));
}
