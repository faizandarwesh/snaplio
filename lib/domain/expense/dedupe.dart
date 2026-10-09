/// Duplicate detection for expenses. Pure Dart.
library;

class DedupeRef {
  const DedupeRef({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.payeeKey,
    required this.transactionId,
    required this.date,
  });

  final int id;
  final int amountMinor;
  final String currency;
  final String? payeeKey;
  final String? transactionId;
  final DateTime date;
}

enum DedupeKind {
  /// A new expense.
  unique,

  /// Same transaction id — the same payment. Don't insert.
  sameTransaction,

  /// Same amount + payee within [ExpenseDedupe.window] and no TID to tell them
  /// apart: insert, but hold it for review and don't count it.
  likelyDuplicate,
}

class DedupeResult {
  const DedupeResult(this.kind, [this.matchId]);
  final DedupeKind kind;
  final int? matchId;

  static const unique = DedupeResult(DedupeKind.unique);
}

class ExpenseDedupe {
  const ExpenseDedupe();

  static const window = Duration(minutes: 10);

  static String? normalizeTid(String? tid) {
    if (tid == null) return null;
    final t = tid.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return t.isEmpty ? null : t;
  }

  DedupeResult check(DedupeRef candidate, Iterable<DedupeRef> existing) {
    final tid = normalizeTid(candidate.transactionId);
    DedupeRef? near;
    for (final e in existing) {
      if (e.id == candidate.id) continue;
      final otherTid = normalizeTid(e.transactionId);
      if (tid != null && otherTid != null) {
        if (tid == otherTid) return DedupeResult(DedupeKind.sameTransaction, e.id);
        // Two different TIDs are two different payments, however similar.
        continue;
      }
      if (e.amountMinor == candidate.amountMinor &&
          e.currency == candidate.currency &&
          e.payeeKey == candidate.payeeKey &&
          e.date.difference(candidate.date).abs() <= window) {
        near ??= e;
      }
    }
    return near == null ? DedupeResult.unique : DedupeResult(DedupeKind.likelyDuplicate, near.id);
  }
}
