import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'label_image_processor.dart';
import 'label_text_parser.dart';

class ShelfLabelOcrService {
  ShelfLabelOcrService()
      : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<ShelfLabelScanResult?> scanImageFile(String path) async {
    final candidates = <ShelfLabelScanResult>[];

    final original = await _recognizeFile(path);
    if (original != null) {
      candidates.add(original);
    }

    final variants = await LabelImageProcessor.prepareVariantsForOcr(path);
    for (final variantPath in variants) {
      final result = await _recognizeFile(variantPath);
      if (result != null) {
        candidates.add(result);
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => _scoreResult(b).compareTo(_scoreResult(a)));
    return _mergeAll(candidates);
  }

  Future<ShelfLabelScanResult?> _recognizeFile(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognizedText = await _recognizer.processImage(inputImage);
    return LabelTextParser.parseRecognizedText(recognizedText);
  }

  int _scoreResult(ShelfLabelScanResult result) {
    var score = 0;

    if (result.name != null && result.name!.trim().length >= 3) {
      score += 45 + result.name!.trim().length.clamp(0, 20);
    }

    if (result.price != null) {
      score += 45;
      if (result.price! >= 0.5 && result.price! <= 999) {
        score += 15;
      }
    }

    if (result.name != null &&
        result.name!.length >= 3 &&
        result.price != null) {
      score += 30;
    }

    return score;
  }

  ShelfLabelScanResult _mergeAll(List<ShelfLabelScanResult> results) {
    String? bestName;
    var bestNameScore = 0;
    double? bestPrice;
    var bestPriceScore = 0;
    var rawText = '';

    for (final result in results) {
      if (result.rawText.length > rawText.length) {
        rawText = result.rawText;
      }

      final name = result.name?.trim();
      if (name != null && name.isNotEmpty) {
        final nameScore = name.length + (name.contains(' ') ? 8 : 0);
        if (nameScore > bestNameScore) {
          bestNameScore = nameScore;
          bestName = name;
        }
      }

      if (result.price != null) {
        final priceScore = _priceConfidence(result);
        if (priceScore > bestPriceScore) {
          bestPriceScore = priceScore;
          bestPrice = result.price;
        }
      }
    }

    return ShelfLabelScanResult(
      name: bestName,
      price: bestPrice,
      rawText: rawText,
    );
  }

  int _priceConfidence(ShelfLabelScanResult result) {
    if (result.price == null) return 0;

    var score = 40;
    if (result.rawText.toUpperCase().contains('R\$')) {
      score += 25;
    }
    if (result.price! >= 0.5 && result.price! <= 999) {
      score += 15;
    }
    return score;
  }

  void dispose() {
    _recognizer.close();
  }
}
