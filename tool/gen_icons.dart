// Generates the SnapLio app mark PNGs (launcher icons + splash mark) without
// any image dependencies. Run with: dart run tool/gen_icons.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _c1 = [0x7C, 0x5C, 0xFF];
const _c2 = [0x4F, 0xC3, 0xF7];

void main() {
  final res = 'android/app/src/main/res';
  const mipmaps = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
  mipmaps.forEach((dpi, size) {
    _write('$res/mipmap-$dpi/ic_launcher.png', _render(size, background: true));
  });
  Directory('assets/brand').createSync(recursive: true);
  // Splash mark: gradient tile, transparent around (Android 12 masks to a circle).
  _write('assets/brand/splash_mark.png', _render(288, background: true, inset: 0.2));
  _write('assets/brand/splash_mark_a12.png', _render(960, background: true, inset: 0.3));
  _write('assets/brand/app_mark.png', _render(512, background: true));
}

void _write(String path, Uint8List bytes) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  stdout.writeln('wrote $path');
}

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// Signed distance to a rounded box centered at (cx, cy).
double _sdRoundBox(double px, double py, double cx, double cy, double hw, double hh, double r) {
  final qx = (px - cx).abs() - hw + r;
  final qy = (py - cy).abs() - hh + r;
  final ox = math.max(qx, 0.0), oy = math.max(qy, 0.0);
  return math.sqrt(ox * ox + oy * oy) + math.min(math.max(qx, qy), 0.0) - r;
}

Uint8List _render(int size, {required bool background, double inset = 0.0}) {
  final px = Uint8List(size * size * 4);
  final s = size.toDouble();
  // Tile occupies the area inside [inset].
  final t0 = s * inset, t1 = s * (1 - inset);
  final tw = t1 - t0;
  final aa = 1.2;

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final fx = x + 0.5, fy = y + 0.5;
      var r = 0.0, g = 0.0, b = 0.0, a = 0.0;

      void over(double sr, double sg, double sb, double sa) {
        final na = sa + a * (1 - sa);
        if (na <= 0) return;
        r = (sr * sa + r * a * (1 - sa)) / na;
        g = (sg * sa + g * a * (1 - sa)) / na;
        b = (sb * sa + b * a * (1 - sa)) / na;
        a = na;
      }

      if (background) {
        final d = _sdRoundBox(fx, fy, s / 2, s / 2, tw / 2, tw / 2, tw * 0.28);
        final cov = _clamp01(0.5 - d / aa);
        if (cov > 0) {
          final k = _clamp01(((fx - t0) + (fy - t0)) / (2 * tw));
          over(
            (_c1[0] + (_c2[0] - _c1[0]) * k) / 255,
            (_c1[1] + (_c2[1] - _c1[1]) * k) / 255,
            (_c1[2] + (_c2[2] - _c1[2]) * k) / 255,
            cov,
          );
        }
      }

      // Back card (translucent white), offset up-right.
      final u = tw / 100; // unit
      final cx = s / 2, cy = s / 2;
      final back = _sdRoundBox(fx, fy, cx + 7 * u, cy - 6 * u, 20 * u, 27 * u, 7 * u);
      final backCov = _clamp01(0.5 - back / aa);
      if (backCov > 0) over(1, 1, 1, backCov * 0.45);

      // Front card (white).
      final front = _sdRoundBox(fx, fy, cx - 5 * u, cy + 5 * u, 20 * u, 27 * u, 7 * u);
      final frontCov = _clamp01(0.5 - front / aa);
      if (frontCov > 0) over(1, 1, 1, frontCov);

      // Text lines on the front card (brand violet).
      if (frontCov > 0.5) {
        const lines = [(-12.0, 12.0), (-3.0, 9.0), (6.0, 12.0)];
        for (final (dy, hw) in lines) {
          final lx = cx - 5 * u - (12 - hw) * u;
          final d = _sdRoundBox(fx, fy, lx, cy + 5 * u + dy * u, hw * u, 2.2 * u, 2.2 * u);
          final c = _clamp01(0.5 - d / aa);
          if (c > 0) over(_c1[0] / 255, _c1[1] / 255, _c1[2] / 255, c);
        }
        // Sparkle dot.
        final dd = math.sqrt(math.pow(fx - (cx + 7 * u), 2) + math.pow(fy - (cy + 20 * u), 2)) - 3.6 * u;
        final c = _clamp01(0.5 - dd / aa);
        if (c > 0) over(_c2[0] / 255, _c2[1] / 255, _c2[2] / 255, c);
      }

      final i = (y * size + x) * 4;
      px[i] = (r * 255).round();
      px[i + 1] = (g * 255).round();
      px[i + 2] = (b * 255).round();
      px[i + 3] = (a * 255).round();
    }
  }
  return _encodePng(size, size, px);
}

Uint8List _encodePng(int w, int h, Uint8List rgba) {
  final raw = BytesBuilder();
  for (var y = 0; y < h; y++) {
    raw.addByte(0);
    raw.add(Uint8List.sublistView(rgba, y * w * 4, (y + 1) * w * 4));
  }
  final out = BytesBuilder()..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void chunk(String type, List<int> data) {
    final len = ByteData(4)..setUint32(0, data.length);
    out.add(len.buffer.asUint8List());
    final td = [...type.codeUnits, ...data];
    out.add(td);
    final crc = ByteData(4)..setUint32(0, _crc32(td));
    out.add(crc.buffer.asUint8List());
  }

  final ihdr = ByteData(13)
    ..setUint32(0, w)
    ..setUint32(4, h)
    ..setUint8(8, 8)
    ..setUint8(9, 6)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  chunk('IHDR', ihdr.buffer.asUint8List());
  chunk('IDAT', ZLibCodec(level: 9).encode(raw.toBytes()));
  chunk('IEND', const []);
  return out.toBytes();
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}
