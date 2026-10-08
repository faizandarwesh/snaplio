import 'classifier/classifier.dart';
import 'entity_extractor/entity_extractor.dart';
import 'models.dart';
import 'source_app.dart';
import 'text_utils.dart';

/// Runs extraction + classification for one screenshot. Pure Dart, so it can
/// run in a background isolate.
class ScreenshotAnalyzer {
  const ScreenshotAnalyzer({
    this.extractor = const EntityExtractor(),
    this.classifier = const ScreenshotClassifier(),
  });

  final EntityExtractor extractor;
  final ScreenshotClassifier classifier;

  AnalysisResult analyze({required String fileName, required String? text}) {
    final sourceApp = parseSourceApp(fileName);
    final entities = extractor.extract(text);
    final category = classifier.classify(
      text: text,
      entities: entities,
      sourceApp: sourceApp,
    );
    return AnalysisResult(
      category: category,
      entities: entities,
      sourceApp: sourceApp,
      textHash: textHash(text),
    );
  }
}
