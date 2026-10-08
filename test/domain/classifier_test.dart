import 'package:snap_lio/domain/analyzer.dart';
import 'package:snap_lio/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analyzer = ScreenshotAnalyzer();

  ScreenshotCategory classify(String text, {String file = 'Screenshot_20261008-145012.png'}) =>
      analyzer.analyze(fileName: file, text: text).category;

  group('OTP', () {
    test('bank SMS', () {
      expect(
        classify('9:41 ⚡ 87%\nHBL\nYour OTP for login is 482913. Do not share it with anyone. Valid for 5 minutes.'),
        ScreenshotCategory.otp,
      );
    });
    test('verification code with dash separator', () {
      expect(classify('Google\nG-583021 is your Google verification code.'), ScreenshotCategory.otp);
    });
    test('code before keyword', () {
      expect(classify('Messages\n7731 is your WhatsApp code. Don\'t share this code'), ScreenshotCategory.otp);
    });
    test('one-time PIN', () {
      expect(classify('Use one-time PIN 0042 to confirm your transfer of Rs. 5,000'), ScreenshotCategory.otp);
    });
  });

  group('Receipts', () {
    test('JazzCash transfer', () {
      expect(
        classify('10:12\nTransaction Successful\nAmount Rs. 2,500.00\nTo: Ali Khan\nTID: 012345678901\n08 Oct 2026 10:11 AM'),
        ScreenshotCategory.receipts,
      );
    });
    test('dollar invoice', () {
      expect(classify('INVOICE #2201\nSubtotal \$40.00\nTotal \$44.50\nPaid with Visa'), ScreenshotCategory.receipts);
    });
    test('amount suffix currency', () {
      expect(classify('Payment received\n1,250 AED\nThank you for shopping'), ScreenshotCategory.receipts);
    });
  });

  group('Orders', () {
    test('Daraz shipped', () {
      expect(
        classify('Your order #300112233 has been shipped!\nCourier: TCS\nTracking No: 7788123456\nExpected delivery Fri'),
        ScreenshotCategory.orders,
      );
    });
    test('delivered', () {
      expect(classify('Package delivered\nYour parcel was handed to resident'), ScreenshotCategory.orders);
    });
    test('out for delivery', () {
      expect(classify('Amazon\nOut for delivery\nArriving today by 8 PM'), ScreenshotCategory.orders);
    });
  });

  group('Errors', () {
    test('flutter exception', () {
      expect(
        classify('══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞══\nNull check operator used on a null value\n#0 main.dart:42'),
        ScreenshotCategory.errors,
      );
    });
    test('http 404', () {
      expect(classify('404\nThis page could not be found'), ScreenshotCategory.errors);
    });
    test('app crash', () {
      expect(classify('Instagram keeps stopping\nApp info  Close app'), isNot(ScreenshotCategory.errors));
      expect(classify('Unfortunately, the app has crashed. Something went wrong.'), ScreenshotCategory.errors);
    });
  });

  group('Links', () {
    test('url only', () {
      expect(classify('Check this out\nhttps://github.com/flutter/flutter'), ScreenshotCategory.links);
    });
    test('bare domain', () {
      expect(classify('flutter.dev/docs'), ScreenshotCategory.links);
    });
  });

  group('Chats', () {
    test('WhatsApp source app', () {
      expect(
        classify('Ahmed\nonline\nHey are we still meeting?\nYes see you there', file: 'Screenshot_20261008-145012_WhatsApp.jpg'),
        ScreenshotCategory.chats,
      );
    });
    test('timestamps on separate lines', () {
      expect(
        classify('Sara\nDid you finish the slides?\n10:42 pm\nAlmost, sending soon\n10:44 pm'),
        ScreenshotCategory.chats,
      );
    });
    test('stronger rule beats messenger', () {
      expect(
        classify('Your OTP is 551234', file: 'Screenshot_20261008-145012_WhatsApp.jpg'),
        ScreenshotCategory.otp,
      );
    });
  });

  group('Notes / Images / Others', () {
    test('long article text', () {
      final text = List.filled(12, 'The quick brown fox jumps over lazy dogs every single day.').join(' ');
      expect(classify(text), ScreenshotCategory.notes);
    });
    test('meme with little text', () {
      expect(classify('when the code\nworks'), ScreenshotCategory.images);
    });
    test('empty text', () {
      expect(classify(''), ScreenshotCategory.images);
    });
    test('medium text falls back to others', () {
      expect(classify('Settings\nDisplay brightness and theme options for your phone screen'), ScreenshotCategory.others);
    });
  });
}
