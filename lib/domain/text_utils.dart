import 'dart:convert';

import 'package:crypto/crypto.dart';

final _wordRe = RegExp(r'[A-Za-z]{2,}');
final _whitespaceRe = RegExp(r'\s+');
// Status-bar noise that differs between otherwise identical screenshots.
final _clockRe = RegExp(r'\b\d{1,2}:\d{2}(?:\s?[ap]m)?\b', caseSensitive: false);
final _percentRe = RegExp(r'\b\d{1,3}\s?%');

/// Counts "real" words (2+ letters), ignoring status-bar tokens like `5G`, `87%`.
int wordCount(String? text) =>
    text == null ? 0 : _wordRe.allMatches(text).length;

String normalizeText(String text) =>
    text.toLowerCase().replaceAll(_whitespaceRe, ' ').trim();

/// Hash of normalized OCR text used to group duplicates.
/// Returns null when there is too little text to be meaningful (< 5 words).
String? textHash(String? text) {
  if (text == null || wordCount(text) < 5) return null;
  final cleaned = normalizeText(
    text.replaceAll(_clockRe, ' ').replaceAll(_percentRe, ' '),
  );
  return sha1.convert(utf8.encode(cleaned)).toString();
}
