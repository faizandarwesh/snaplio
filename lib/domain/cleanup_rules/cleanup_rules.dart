import '../models.dart';

/// Minimal view of a screenshot for cleanup analysis.
class CleanupItem {
  const CleanupItem({
    required this.assetId,
    required this.category,
    required this.createdAt,
    required this.sizeBytes,
    required this.width,
    required this.height,
    this.textHash,
    this.ocrText,
    this.isFavorite = false,
  });

  final String assetId;
  final ScreenshotCategory category;
  final DateTime createdAt;
  final int sizeBytes;
  final int width;
  final int height;
  final String? textHash;
  final String? ocrText;
  final bool isFavorite;
}

enum CleanupKind {
  oldOtps('Old OTPs', 'One-time codes older than 24 hours'),
  duplicates('Duplicates', 'Same content — we keep the newest'),
  deliveredOrders('Delivered orders', 'Delivered more than 30 days ago'),
  large('Large screenshots', 'The biggest files in your library'),
  old('Older than 6 months', 'Screenshots you probably forgot about');

  const CleanupKind(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

class CleanupSuggestion {
  const CleanupSuggestion({
    required this.kind,
    required this.assetIds,
    required this.totalBytes,
  });

  final CleanupKind kind;

  /// Ids pre-selected for deletion, newest first.
  final List<String> assetIds;
  final int totalBytes;

  int get count => assetIds.length;
}

class CleanupReport {
  const CleanupReport(this.suggestions, this.reclaimableBytes, this.reclaimableCount);

  final List<CleanupSuggestion> suggestions;

  /// Bytes across all suggestions, counting each screenshot once.
  final int reclaimableBytes;
  final int reclaimableCount;

  static const empty = CleanupReport([], 0, 0);
}

/// Pure cleanup rules. Favorites are never suggested.
class CleanupRules {
  const CleanupRules({
    this.largeMinBytes = 1024 * 1024,
    this.largeTopN = 30,
  });

  final int largeMinBytes;
  final int largeTopN;

  CleanupReport analyze(List<CleanupItem> all, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final items = all.where((i) => !i.isFavorite).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final suggestions = <CleanupSuggestion>[];
    void add(CleanupKind kind, Iterable<CleanupItem> picked) {
      final list = picked.toList();
      if (list.isEmpty) return;
      suggestions.add(CleanupSuggestion(
        kind: kind,
        assetIds: [for (final i in list) i.assetId],
        totalBytes: list.fold(0, (s, i) => s + i.sizeBytes),
      ));
    }

    add(CleanupKind.oldOtps, oldOtps(items, n));
    add(CleanupKind.duplicates, duplicates(items));
    add(CleanupKind.deliveredOrders, deliveredOrders(items, n));
    add(CleanupKind.large, large(items));
    add(CleanupKind.old, olderThan6Months(items, n));

    final seen = <String>{};
    var bytes = 0;
    final byId = {for (final i in items) i.assetId: i};
    for (final s in suggestions) {
      for (final id in s.assetIds) {
        if (seen.add(id)) bytes += byId[id]!.sizeBytes;
      }
    }
    return CleanupReport(suggestions, bytes, seen.length);
  }

  Iterable<CleanupItem> oldOtps(List<CleanupItem> items, DateTime now) => items.where(
        (i) => i.category == ScreenshotCategory.otp && now.difference(i.createdAt) > const Duration(hours: 24),
      );

  /// Groups by text hash + dimensions; keeps the newest of each group.
  Iterable<CleanupItem> duplicates(List<CleanupItem> items) sync* {
    final groups = <String, List<CleanupItem>>{};
    for (final i in items) {
      final h = i.textHash;
      if (h == null) continue;
      groups.putIfAbsent('$h:${i.width}x${i.height}', () => []).add(i);
    }
    for (final g in groups.values) {
      if (g.length < 2) continue;
      g.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield* g.skip(1);
    }
  }

  static final _deliveredRe = RegExp(r'\bdelivered\b', caseSensitive: false);

  Iterable<CleanupItem> deliveredOrders(List<CleanupItem> items, DateTime now) => items.where(
        (i) =>
            i.category == ScreenshotCategory.orders &&
            _deliveredRe.hasMatch(i.ocrText ?? '') &&
            now.difference(i.createdAt) > const Duration(days: 30),
      );

  Iterable<CleanupItem> large(List<CleanupItem> items) {
    final sorted = items.where((i) => i.sizeBytes >= largeMinBytes).toList()
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return sorted.take(largeTopN);
  }

  Iterable<CleanupItem> olderThan6Months(List<CleanupItem> items, DateTime now) =>
      items.where((i) => now.difference(i.createdAt) > const Duration(days: 182));
}
