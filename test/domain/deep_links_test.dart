import 'package:flutter_test/flutter_test.dart';
import 'package:snap_lio/app/deep_links.dart';

void main() {
  test('tabs', () {
    expect(parseDeepLink('snaplio://spend')!.location, '/spend');
    expect(parseDeepLink('snapsort://clean')!.tab, isTrue);
    final s = parseDeepLink('snaplio://search')!;
    expect(s.location, '/search');
    expect(s.focusSearch, isTrue);
    final l = parseDeepLink('snaplio://links')!;
    expect(l.location, '/search');
    expect(l.linksFilter, isTrue);
  });

  test('screens pushed on top', () {
    final d = parseDeepLink('snaplio://screenshot/1000123')!;
    expect(d.location, '/shot/1000123');
    expect(d.tab, isFalse);
    expect(parseDeepLink('snaplio://expense/42')!.location, '/expense/42');
    expect(parseDeepLink('snapsort://recap/7')!.location, '/recap/7');
  });

  test('rejects other schemes and junk', () {
    expect(parseDeepLink('https://spend'), isNull);
    expect(parseDeepLink('snaplio://expense/abc'), isNull);
    expect(parseDeepLink('snaplio://nope'), isNull);
    expect(parseDeepLink('snaplio://screenshot'), isNull);
  });
}
