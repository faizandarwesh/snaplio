import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR via ML Kit (bundled Latin model — works offline).
class OcrService {
  TextRecognizer? _recognizer;

  TextRecognizer get _r => _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  /// Returns recognized text with one line per detected line, or null on failure.
  Future<String?> recognize(String filePath) async {
    final result = await _r.processImage(InputImage.fromFilePath(filePath));
    final lines = <String>[
      for (final block in result.blocks)
        for (final line in block.lines) line.text,
    ];
    final text = lines.join('\n').trim();
    return text.isEmpty ? null : text;
  }

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
