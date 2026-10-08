import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

import '../data/screenshot_repository.dart';

enum GalleryAccess {
  /// Not asked yet.
  unknown,
  granted,

  /// Android 14 "Select photos" partial access.
  limited,
  denied;

  bool get canRead => this == granted || this == limited;
}

class ScreenshotAlbum {
  const ScreenshotAlbum(this.id, this.name, this.count);
  final String id;
  final String name;
  final int count;
}

/// Thin wrapper around photo_manager so the rest of the app never talks to the
/// plugin directly.
class GalleryService {
  static const _permOption = PermissionRequestOption(
    androidPermission: AndroidPermission(type: RequestType.image, mediaLocation: false),
  );

  static GalleryAccess _map(PermissionState s) => switch (s) {
        PermissionState.authorized => GalleryAccess.granted,
        PermissionState.limited => GalleryAccess.limited,
        PermissionState.notDetermined => GalleryAccess.unknown,
        PermissionState.denied || PermissionState.restricted => GalleryAccess.denied,
      };

  Future<GalleryAccess> currentAccess() async {
    try {
      return _map(await PhotoManager.getPermissionState(requestOption: _permOption));
    } catch (_) {
      return GalleryAccess.unknown;
    }
  }

  Future<GalleryAccess> requestAccess() async =>
      _map(await PhotoManager.requestPermissionExtend(requestOption: _permOption));

  /// Re-opens the Android 14 photo picker so the user can grant more.
  Future<void> presentLimitedPicker() => PhotoManager.presentLimited(type: RequestType.image);

  Future<void> openAppSettings() => PhotoManager.openSetting();

  /// MediaStore WHERE clause matching screenshots: albums named "Screenshot…",
  /// any path containing /Screenshots/, or any file named Screenshot*.
  static String screenshotWhere(Set<String> excludedAlbumIds) {
    final base = "(bucket_display_name LIKE '%screenshot%' "
        "OR _data LIKE '%/Screenshots/%' "
        "OR _display_name LIKE 'Screenshot%')";
    final ids = excludedAlbumIds.where((id) => RegExp(r'^-?\d+$').hasMatch(id)).toList();
    if (ids.isEmpty) return base;
    return '$base AND bucket_id NOT IN (${ids.join(',')})';
  }

  PMFilter _filter(Set<String> excluded) => CustomFilter.sql(
        where: screenshotWhere(excluded),
        orderBy: [OrderByItem.desc(CustomColumns.base.createDate)],
      )..needTitle = true;

  /// Lists every screenshot visible to the app, de-duplicated by asset id.
  Future<List<DiscoveredAsset>> findScreenshots({Set<String> excludedAlbumIds = const {}}) async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: _filter(excludedAlbumIds),
    );
    if (paths.isEmpty) return const [];
    final all = paths.first;
    final total = await all.assetCountAsync;
    final seen = <String>{};
    final out = <DiscoveredAsset>[];
    const page = 500;
    for (var start = 0; start < total; start += page) {
      final assets = await all.getAssetListRange(start: start, end: start + page);
      for (final a in assets) {
        if (!seen.add(a.id)) continue;
        out.add(DiscoveredAsset(
          id: a.id,
          fileName: a.title ?? 'Screenshot_${a.id}.png',
          createdAt: a.createDateTime,
          width: a.orientatedWidth,
          height: a.orientatedHeight,
        ));
      }
    }
    return out;
  }

  /// Albums that contain screenshots (for Settings → Manage folders).
  Future<List<ScreenshotAlbum>> screenshotAlbums() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: false,
      filterOption: _filter(const {}),
    );
    final out = <ScreenshotAlbum>[];
    for (final p in paths) {
      final n = await p.assetCountAsync;
      if (n > 0) out.add(ScreenshotAlbum(p.id, p.name, n));
    }
    out.sort((a, b) => b.count.compareTo(a.count));
    return out;
  }

  Future<File?> fileFor(String assetId) async {
    final entity = await AssetEntity.fromId(assetId);
    return entity?.file;
  }

  /// Deletes via MediaStore. On Android 11+ this shows the system confirmation
  /// dialog; returns the ids that were actually deleted.
  Future<List<String>> delete(List<String> ids) async {
    if (ids.isEmpty) return const [];
    return PhotoManager.editor.deleteWithIds(ids);
  }
}
