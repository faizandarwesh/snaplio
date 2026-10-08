import 'package:snap_lio/domain/cleanup_rules/cleanup_rules.dart';
import 'package:snap_lio/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 8, 12);
  const mb = 1024 * 1024;

  CleanupItem item(
    String id, {
    ScreenshotCategory c = ScreenshotCategory.others,
    Duration age = Duration.zero,
    int size = 200 * 1024,
    String? hash,
    String? text,
    bool fav = false,
  }) =>
      CleanupItem(
        assetId: id,
        category: c,
        createdAt: now.subtract(age),
        sizeBytes: size,
        width: 1080,
        height: 2400,
        textHash: hash,
        ocrText: text,
        isFavorite: fav,
      );

  test('old OTPs only after 24h', () {
    final r = const CleanupRules().analyze([
      item('a', c: ScreenshotCategory.otp, age: const Duration(hours: 2)),
      item('b', c: ScreenshotCategory.otp, age: const Duration(days: 2)),
    ], now: now);
    expect(r.suggestions.single.kind, CleanupKind.oldOtps);
    expect(r.suggestions.single.assetIds, ['b']);
  });

  test('duplicates keep newest', () {
    final r = const CleanupRules().analyze([
      item('old', hash: 'h', age: const Duration(days: 3)),
      item('new', hash: 'h', age: const Duration(days: 1)),
      item('mid', hash: 'h', age: const Duration(days: 2)),
      item('other', hash: 'x'),
    ], now: now);
    final dup = r.suggestions.firstWhere((s) => s.kind == CleanupKind.duplicates);
    expect(dup.assetIds, ['mid', 'old']);
  });

  test('delivered orders older than 30 days', () {
    final r = const CleanupRules().analyze([
      item('a', c: ScreenshotCategory.orders, text: 'Delivered', age: const Duration(days: 40)),
      item('b', c: ScreenshotCategory.orders, text: 'Shipped', age: const Duration(days: 40)),
      item('c', c: ScreenshotCategory.orders, text: 'Delivered', age: const Duration(days: 5)),
    ], now: now);
    expect(r.suggestions.firstWhere((s) => s.kind == CleanupKind.deliveredOrders).assetIds, ['a']);
  });

  test('large and old, total counted once, favorites excluded', () {
    final r = const CleanupRules().analyze([
      item('big-old', size: 3 * mb, age: const Duration(days: 400)),
      item('big', size: 2 * mb),
      item('fav', size: 5 * mb, fav: true, age: const Duration(days: 400)),
    ], now: now);
    expect(r.suggestions.firstWhere((s) => s.kind == CleanupKind.large).assetIds, ['big-old', 'big']);
    expect(r.suggestions.firstWhere((s) => s.kind == CleanupKind.old).assetIds, ['big-old']);
    expect(r.reclaimableBytes, 5 * mb);
    expect(r.reclaimableCount, 2);
  });
}
