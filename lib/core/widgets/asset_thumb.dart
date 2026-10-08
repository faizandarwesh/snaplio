import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../design/tokens.dart';
import 'shimmer.dart';

/// Image provider for a MediaStore thumbnail, cached by Flutter's ImageCache
/// under (assetId, size).
@immutable
class AssetThumbProvider extends ImageProvider<AssetThumbProvider> {
  const AssetThumbProvider(this.assetId, {this.size = 300});

  final String assetId;
  final int size;

  @override
  Future<AssetThumbProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<AssetThumbProvider>(this);

  @override
  ImageStreamCompleter loadImage(AssetThumbProvider key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1.0, debugLabel: 'thumb:$assetId');

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final entity = AssetEntity(id: assetId, typeInt: AssetType.image.index, width: size, height: size);
    final bytes = await entity.thumbnailDataWithSize(ThumbnailSize.square(size), quality: 82);
    if (bytes == null || bytes.isEmpty) {
      throw StateError('No thumbnail for $assetId');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) => other is AssetThumbProvider && other.assetId == assetId && other.size == size;

  @override
  int get hashCode => Object.hash(assetId, size);
}

/// Rounded thumbnail with shimmer placeholder and fade-in.
class AssetThumb extends StatelessWidget {
  const AssetThumb(
    this.assetId, {
    super.key,
    this.radius = Radii.sm,
    this.size = 300,
    this.fit = BoxFit.cover,
  });

  final String assetId;
  final double radius;
  final int size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: c.surfaceElevated,
        child: Image(
          image: AssetThumbProvider(assetId, size: size),
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          frameBuilder: (context, child, frame, sync) {
            if (sync) return child;
            return AnimatedSwitcher(
              duration: Motion.medium,
              child: frame == null ? const ShimmerBox(key: ValueKey('s')) : KeyedSubtree(key: const ValueKey('i'), child: child),
            );
          },
          errorBuilder: (context, error, stack) => Center(
            child: Icon(Icons.broken_image_outlined, color: c.textTertiary, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Full-resolution image for the detail view: reads the file directly when the
/// path is known (callers fall back to [AssetThumbProvider] on error).
ImageProvider fullImageProvider(String assetId, String? filePath) {
  if (filePath != null) return FileImage(File(filePath));
  return AssetThumbProvider(assetId, size: 1600);
}
