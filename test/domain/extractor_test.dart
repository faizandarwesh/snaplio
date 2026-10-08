import 'package:snap_lio/domain/entity_extractor/entity_extractor.dart';
import 'package:snap_lio/domain/models.dart';
import 'package:snap_lio/domain/source_app.dart';
import 'package:snap_lio/domain/text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const x = EntityExtractor();

  List<String> values(String text, EntityType type) =>
      x.extract(text).where((e) => e.type == type).map((e) => e.value).toList();

  group('URLs', () {
    test('full and bare urls', () {
      final v = values('Visit https://example.com/a?b=1, or www.daraz.pk and flutter.dev.', EntityType.url);
      expect(v, containsAll(['https://example.com/a?b=1', 'https://www.daraz.pk', 'https://flutter.dev']));
    });
    test('does not treat email domain as url', () {
      expect(values('mail me at ali@gmail.com', EntityType.url), isEmpty);
    });
  });

  test('emails', () {
    expect(values('Contact: Support@Shop.co.uk today', EntityType.email), ['support@shop.co.uk']);
  });

  group('phones', () {
    test('pakistani formats', () {
      final v = values('Call 0300-1234567 or +92 321 7654321 or 03451234567', EntityType.phone);
      expect(v, containsAll(['+923001234567', '+923217654321', '+923451234567']));
    });
    test('international', () {
      expect(values('UAE office: +971 4 123 4567', EntityType.phone), ['+97141234567']);
    });
    test('ignores plain short numbers', () {
      expect(values('Order 123456 total 4500', EntityType.phone), isEmpty);
    });
  });

  group('otp', () {
    test('picks code near keyword, not amount', () {
      expect(values('Rs. 5000 transfer. Your OTP is 839201', EntityType.otp), ['839201']);
    });
    test('none without keyword', () {
      expect(values('Room 4521 is on the 3rd floor', EntityType.otp), isEmpty);
    });
    test('ignores years', () {
      expect(values('Verification done in 2026', EntityType.otp), isEmpty);
    });
  });

  group('amounts', () {
    test('prefix and suffix currencies', () {
      final v = values('Rs. 2,500.00 paid, then \$44.5 and 1,250 AED and ₹999', EntityType.amount);
      expect(v, containsAll(['PKR 2500', 'USD 44.50', 'AED 1250', 'INR 999']));
    });
    test('parse back', () {
      expect(EntityExtractor.parseAmountValue('PKR 2500'), ('PKR', 2500.0));
    });
  });

  test('dates', () {
    final v = values('Due 08/10/2026, shipped 2026-10-01, paid 8 Oct 2026, from March 3, 2026', EntityType.date);
    expect(v, containsAll(['08/10/2026', '2026-10-01', '8 Oct 2026', 'March 3, 2026']));
  });

  test('tracking', () {
    final v = values('Tracking No: 7788123456\nAlso RR123456789PK', EntityType.tracking);
    expect(v, containsAll(['7788123456', 'RR123456789PK']));
  });

  test('address with label', () {
    final v = values('Delivery Address: House 12, Street 5, F-7/2, Islamabad\nPhone', EntityType.address);
    expect(v.single, contains('House 12'));
  });

  group('source app', () {
    test('samsung style', () {
      expect(parseSourceApp('Screenshot_20261008-145012_WhatsApp.jpg'), 'WhatsApp');
      expect(parseSourceApp('Screenshot_20261008-145012_Chrome.jpg'), 'Chrome');
    });
    test('xiaomi package style', () {
      expect(parseSourceApp('Screenshot_2026-10-08-14-50-12-345_com.instagram.android.jpg'), 'Instagram');
    });
    test('no app', () {
      expect(parseSourceApp('Screenshot_20261008-145012.png'), isNull);
      expect(parseSourceApp('IMG_1234.jpg'), isNull);
    });
  });

  group('text hash', () {
    test('ignores status bar clock and battery', () {
      expect(
        textHash('10:41 87%\nYour package has been delivered today'),
        textHash('10:58 85%\nYour  package has been DELIVERED today'),
      );
    });
    test('null for little text', () {
      expect(textHash('hi there'), isNull);
    });
  });
}
