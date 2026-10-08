import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/haptics.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/shimmer.dart';
import '../../core/widgets/states.dart';
import '../../services/gallery_service.dart';

final _albumsProvider = FutureProvider.autoDispose<List<ScreenshotAlbum>>(
  (ref) => ref.watch(galleryServiceProvider).screenshotAlbums(),
);

/// Shows detected screenshot folders with include/exclude toggles.
class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(_albumsProvider);
    final excluded = ref.watch(settingsProvider.select((s) => s.excludedAlbumIds));
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage folders')),
      body: switch (albums) {
        AsyncData(:final value) when value.isEmpty => const EmptyState(
            icon: Icons.folder_off_outlined,
            title: 'No screenshot folders',
            message: 'Once you take a screenshot, its folder will appear here.',
          ),
        AsyncData(:final value) => ListView(
            padding: const EdgeInsets.all(Space.screen),
            children: [
              Text('Turn a folder off to stop sorting its screenshots. Nothing is deleted.', style: context.text.bodyMedium),
              const SizedBox(height: Space.md),
              Container(
                decoration: BoxDecoration(color: c.surface, borderRadius: Radii.mdAll, border: Border.all(color: c.border)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final a in value)
                      SwitchListTile(
                        value: !excluded.contains(a.id),
                        onChanged: (on) async {
                          Haptics.selection();
                          await ref.read(settingsProvider.notifier).setAlbumExcluded(a.id, !on);
                          ref.read(scanServiceProvider).scan();
                        },
                        secondary: Icon(Icons.folder_rounded, color: c.textSecondary),
                        title: Text(a.name, style: context.text.bodyLarge),
                        subtitle: Text('${formatCount(a.count)} screenshots', style: context.text.bodySmall),
                      ),
                  ],
                ),
              ),
            ],
          ),
        AsyncError() => ErrorState(onRetry: () => ref.invalidate(_albumsProvider)),
        _ => ListView(
            padding: const EdgeInsets.all(Space.screen),
            children: const [
              ShimmerBox(height: 64, radius: Radii.sm),
              SizedBox(height: Space.sm),
              ShimmerBox(height: 64, radius: Radii.sm),
            ],
          ),
      },
    );
  }
}
