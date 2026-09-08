import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'label_text_parser.dart';

class ShelfLabelOcrService {
  ShelfLabelOcrService()
      : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<ShelfLabelScanResult?> scanImageFile(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognizedText = await _recognizer.processImage(inputImage);
    final text = recognizedText.text.trim();

    if (text.isEmpty) return null;

    return LabelTextParser.parse(text);
  }

  void dispose() {
    _recognizer.close();
  }
}
