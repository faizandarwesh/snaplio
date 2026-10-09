/// Spend categories and the built-in merchant/keyword map. Pure Dart.
library;

enum ExpenseCategory {
  food('Food', '🍔'),
  bills('Bills', '💡'),
  shopping('Shopping', '🛍️'),
  transport('Transport', '🚗'),
  health('Health', '💊'),
  education('Education', '🎓'),
  transfers('Transfers', '🔁'),
  other('Other', '📁');

  const ExpenseCategory(this.label, this.emoji);

  final String label;
  final String emoji;

  static ExpenseCategory fromName(String? name) =>
      values.firstWhere((c) => c.name == name, orElse: () => other);
}

/// Keyword patterns per category. Edit freely: each entry is a regex fragment
/// matched case-insensitively on word boundaries. Longer (more specific)
/// matches win across categories, so "uber eats" beats "uber".
const Map<ExpenseCategory, List<String>> kCategoryKeywords = {
  ExpenseCategory.food: [
    'foodpanda', 'food panda', 'kfc', r"mcdonald'?s?", 'cheezious', 'restaurant', 'cafe', 'café', 'coffee',
    'pizza hut', 'domino\'?s', 'burger', 'subway', 'hardee\'?s', 'gloria jean\'?s', 'starbucks', 'dunkin',
    'bakery', 'biryani', 'kitchen', 'grill', 'dhaba', 'uber eats', 'deliveroo', 'talabat', 'careem food',
    'savour', 'optp', 'johnny & jugnu', 'howdy', 'tehzeeb', 'food',
  ],
  ExpenseCategory.bills: [
    'k-?electric', 'ssgc', 'sngpl', 'ptcl', 'lesco', 'iesco', 'mepco', 'fesco', 'gepco', 'pesco', 'hesco',
    'electricity', 'gas bill', 'water bill', 'utility', 'internet (?:bill|package|charges)', 'broadband', 'nayatel', 'stormfiber',
    'storm fiber', 'mobile load', 'mobile package', 'easyload', 'top-?up', 'recharge', 'postpaid', 'prepaid',
    r'jazz(?!\s?cash)', 'zong', r'telenor(?!\s?microfinance)', 'ufone', 'warid', 'bill payment', 'netflix',
    'spotify', 'youtube premium', 'du', 'etisalat', 'dewa', 'stc', 'verizon', 'at&t', 't-mobile', 'comcast',
  ],
  ExpenseCategory.shopping: [
    'daraz', 'amazon', 'store', 'mart', 'imtiaz', 'carrefour', 'metro cash', 'chase up', 'al-?fatah',
    'naheed', 'khaadi', 'outfitters', 'gul ahmed', 'sapphire', 'junaid jamshed', 'ikea', 'walmart',
    'costco', 'temu', 'aliexpress', 'shein', 'supermarket', 'hypermarket', 'mall', 'shop',
  ],
  ExpenseCategory.transport: [
    'careem', 'uber', 'indrive', 'in drive', 'bykea', 'yango', 'fuel', 'petrol', 'diesel', 'pso', 'shell',
    'total parco', 'attock', 'hascol', 'metro bus', 'parking', 'toll', 'motorway', 'airline', 'pia',
    'airblue', 'serene air', 'emirates', 'flydubai', 'railway', 'daewoo', 'faisal movers', 'lyft', 'taxi', 'cab',
  ],
  ExpenseCategory.health: [
    'pharmacy', 'pharma', 'hospital', 'clinic', 'lab', 'laboratory', 'chughtai', 'dawaai', 'sehat',
    'medical', 'medicine', 'dental', 'doctor', 'shifa', 'aga khan', 'diagnostic', 'oladoc', 'marham',
  ],
  ExpenseCategory.education: [
    'school', 'university', 'college', 'academy', 'tuition', 'school fee', 'fee voucher', 'admission',
    'coursera', 'udemy', 'institute', 'beaconhouse', 'city school', 'lums', 'nust', 'fast nuces',
  ],
};

/// Normalizes a payee to a stable key for merchant rules and dedupe:
/// "Ali Khan  " → "ali khan", "FOODPANDA PK!" → "foodpanda pk".
String? payeeKey(String? payee) {
  if (payee == null) return null;
  final k = payee
      .toLowerCase()
      .replaceAll(RegExp(r"[^\p{L}\p{N}& ]+", unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return k.isEmpty ? null : k;
}

class _Compiled {
  _Compiled(this.category, this.pattern)
      : re = RegExp('(?<![\\p{L}\\p{N}])(?:$pattern)(?![\\p{L}\\p{N}])', caseSensitive: false, unicode: true);
  final ExpenseCategory category;
  final String pattern;
  final RegExp re;
}

final List<_Compiled> _compiled = [
  for (final entry in kCategoryKeywords.entries)
    for (final p in entry.value) _Compiled(entry.key, p),
];

/// Person-to-person transfer language (no merchant involved).
final _transferRe = RegExp(
  r'\b(?:ibft|raast|funds?\s+transfer(?:red)?|money\s+transfer|transferred\s+to|sent\s+to|send\s+money|money\s+sent|interbank|beneficiary|p2p|wallet\s+to\s+wallet)\b',
  caseSensitive: false,
);

class CategoryMatch {
  const CategoryMatch(this.category, {this.merchant, this.fromRule = false});
  final ExpenseCategory category;

  /// The merchant text that matched (as written in the source), if any.
  final String? merchant;
  final bool fromRule;
}

/// Maps a receipt to a spend category.
class CategoryMapper {
  const CategoryMapper();

  /// Longest keyword hit in [text], or null.
  ({ExpenseCategory category, String match})? keywordMatch(String text) {
    ({ExpenseCategory category, String match})? best;
    for (final c in _compiled) {
      for (final m in c.re.allMatches(text)) {
        final hit = m.group(0)!;
        if (best == null || hit.length > best.match.length) best = (category: c.category, match: hit);
      }
    }
    return best;
  }

  CategoryMatch map({
    required String? payee,
    required String text,
    Map<String, ExpenseCategory> rules = const {},
  }) {
    final key = payeeKey(payee);
    if (key != null && rules[key] != null) return CategoryMatch(rules[key]!, fromRule: true);

    if (payee != null) {
      final m = keywordMatch(payee);
      if (m != null) return CategoryMatch(m.category, merchant: m.match);
    }
    final m = keywordMatch(text);
    if (m != null) return CategoryMatch(m.category, merchant: m.match);

    if (_transferRe.hasMatch(text)) return const CategoryMatch(ExpenseCategory.transfers);
    return const CategoryMatch(ExpenseCategory.other);
  }
}
