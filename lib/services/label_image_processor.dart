import 'dart:io';

import 'package:image/image.dart' as img;

class LabelImageProcessor {
  LabelImageProcessor._();

  static const double guideAspectRatio = 300 / 180;

  static Future<List<String>> prepareVariantsForOcr(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return [sourcePath];

    final oriented = img.bakeOrientation(decoded);
    final cropped = _cropGuideRegion(oriented);

    return [
      await _writeVariant(sourcePath, 'enhanced', cropped, _enhance),
      await _writeVariant(sourcePath, 'sharp', cropped, _sharpen),
      await _writeVariant(sourcePath, 'binary', cropped, _binarize),
    ];
  }

  static Future<String> _writeVariant(
    String sourcePath,
    String suffix,
    img.Image cropped,
    img.Image Function(img.Image) transform,
  ) async {
    var image = transform(cropped);

    if (image.width < 1400) {
      final scale = 1400 / image.width;
      image = img.copyResize(
        image,
        width: 1400,
        height: (image.height * scale).round(),
      );
    }

    final outputPath = '$sourcePath.$suffix.jpg';
    await File(outputPath).writeAsBytes(img.encodeJpg(image, quality: 96));
    return outputPath;
  }

  static img.Image _enhance(img.Image image) {
    image = img.grayscale(image);
    return img.adjustColor(
      image,
      contrast: 1.45,
      brightness: 0.04,
      gamma: 0.92,
    );
  }

  static img.Image _sharpen(img.Image image) {
    image = img.grayscale(image);
    image = img.adjustColor(image, contrast: 1.6, brightness: 0.02);
    return img.convolution(
      image,
      filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ],
    );
  }

  static img.Image _binarize(img.Image image) {
    image = img.grayscale(image);
    image = img.adjustColor(image, contrast: 1.8);
    return img.luminanceThreshold(image, threshold: 0.45);
  }

  static img.Image _cropGuideRegion(img.Image image) {
    final cropWidth = (image.width * 0.88).round();
    final cropHeight = (cropWidth / guideAspectRatio)
        .round()
        .clamp(1, image.height);
    final x = ((image.width - cropWidth) / 2).round();
    final y = ((image.height - cropHeight) / 2).round();

    return img.copyCrop(
      image,
      x: x,
      y: y,
      width: cropWidth,
      height: cropHeight,
    );
  }
}
