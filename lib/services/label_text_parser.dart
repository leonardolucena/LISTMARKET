import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ShelfLabelScanResult {
  const ShelfLabelScanResult({
    this.name,
    this.price,
    required this.rawText,
  });

  final String? name;
  final double? price;
  final String rawText;

  bool get hasData => (name != null && name!.isNotEmpty) || price != null;
}

class _ParsedLine {
  const _ParsedLine({
    required this.text,
    required this.top,
    required this.height,
  });

  final String text;
  final double top;
  final double height;
}

class LabelTextParser {
  LabelTextParser._();

  static final RegExp pricePattern =
      RegExp(r'(?:R\s*\$?\s*)?\d{1,4}[,\.]\d{2}', caseSensitive: false);
  static final RegExp priceOnlyPattern = RegExp(
    r'^\s*(?:R\s*\$?\s*)?\d{1,4}[,\.]\d{2}\s*$',
    caseSensitive: false,
  );
  static final RegExp realSymbolOnlyPattern = RegExp(
    r'^\s*R\s*\$?\s*$',
    caseSensitive: false,
  );
  static final RegExp longNumberPattern = RegExp(r'\d{5,}');
  static final RegExp letterPattern = RegExp(r'[A-Za-zÀ-ÿ]');

  static ShelfLabelScanResult parse(String rawText) {
    final lines = _mergeSplitPriceTexts(_extractLines(rawText));
    return ShelfLabelScanResult(
      name: _extractNameFromTexts(lines),
      price: _extractPrice(lines.join('\n')),
      rawText: lines.join('\n'),
    );
  }

  static ShelfLabelScanResult parseRecognizedText(RecognizedText recognized) {
    final parsedLines = <_ParsedLine>[];

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;

        parsedLines.add(
          _ParsedLine(
            text: text,
            top: line.boundingBox.top,
            height: line.boundingBox.height,
          ),
        );
      }
    }

    parsedLines.sort((a, b) => a.top.compareTo(b.top));
    final mergedLines = _mergeSplitPriceLines(parsedLines);
    final texts = mergedLines.map((line) => line.text).toList();
    final rawText = texts.join('\n');

    return ShelfLabelScanResult(
      name: _extractNameFromParsedLines(mergedLines),
      price: _extractPriceFromParsedLines(mergedLines) ??
          _extractPrice(rawText),
      rawText: rawText,
    );
  }

  static List<String> _extractLines(String rawText) {
    return rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static List<String> _mergeSplitPriceTexts(List<String> lines) {
    if (lines.isEmpty) return lines;

    final merged = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final current = lines[i];
      if (realSymbolOnlyPattern.hasMatch(current) && i + 1 < lines.length) {
        merged.add('$current ${lines[i + 1]}');
        i++;
        continue;
      }
      merged.add(current);
    }

    return merged;
  }

  static List<_ParsedLine> _mergeSplitPriceLines(List<_ParsedLine> lines) {
    if (lines.isEmpty) return lines;

    final merged = <_ParsedLine>[];

    for (var i = 0; i < lines.length; i++) {
      final current = lines[i];
      if (realSymbolOnlyPattern.hasMatch(current.text) && i + 1 < lines.length) {
        final next = lines[i + 1];
        merged.add(
          _ParsedLine(
            text: '${current.text} ${next.text}',
            top: current.top,
            height: current.height > next.height ? current.height : next.height,
          ),
        );
        i++;
        continue;
      }
      merged.add(current);
    }

    return merged;
  }

  static String? _extractNameFromTexts(List<String> lines) {
    String? best;
    var bestScore = 0;

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (!_isNameCandidate(line)) continue;

      var score = line.length;
      if (letterPattern.hasMatch(line)) score += 12;
      if (line.length >= 8) score += 6;
      if (index <= 1) score += 10;

      if (score > bestScore) {
        bestScore = score;
        best = line;
      }
    }

    return best;
  }

  static String? _extractNameFromParsedLines(List<_ParsedLine> lines) {
    if (lines.isEmpty) return null;

    final maxTop = lines.map((line) => line.top).reduce((a, b) => a > b ? a : b);

    String? best;
    var bestScore = 0;

    for (final line in lines) {
      if (!_isNameCandidate(line.text)) continue;

      var score = line.text.length;
      if (letterPattern.hasMatch(line.text)) score += 12;
      if (line.text.length >= 8) score += 6;

      if (line.top <= maxTop * 0.55) {
        score += 18;
      }

      if (score > bestScore) {
        bestScore = score;
        best = line.text;
      }
    }

    return best ?? _extractNameFromTexts(lines.map((line) => line.text).toList());
  }

  static bool _isNameCandidate(String line) {
    if (line.length < 2) return false;
    if (priceOnlyPattern.hasMatch(line)) return false;
    if (pricePattern.hasMatch(line) && line.length <= 12) return false;
    if (longNumberPattern.hasMatch(line)) return false;
    if (RegExp(r'^[\d\s\.,R\$]+$').hasMatch(line)) return false;
    if (!letterPattern.hasMatch(line)) return false;
    return true;
  }

  static double? _extractPriceFromParsedLines(List<_ParsedLine> lines) {
    if (lines.isEmpty) return null;

    final maxTop = lines.map((line) => line.top).reduce((a, b) => a > b ? a : b);
    double? bestPrice;
    var bestScore = 0;

    for (final line in lines) {
      final normalizedLine = _normalizeForPriceSearch(line.text);
      final matches = pricePattern.allMatches(normalizedLine).toList();
      if (matches.isEmpty) continue;

      for (final match in matches) {
        final token = match.group(0)!;
        final value = _parsePriceToken(token);
        if (value == null || value <= 0 || value > 9999) continue;

        var score = (line.height * 2).round();
        if (token.toUpperCase().contains('R')) score += 80;
        if (priceOnlyPattern.hasMatch(normalizedLine)) score += 60;
        if (line.top >= maxTop * 0.45) score += 25;

        if (value >= 0.5 && value <= 999) score += 10;

        if (score > bestScore) {
          bestScore = score;
          bestPrice = value;
        }
      }
    }

    return bestPrice;
  }

  static double? _extractPrice(String text) {
    final normalized = _normalizeForPriceSearch(text);
    final matches = pricePattern.allMatches(normalized).toList();
    if (matches.isEmpty) return null;

    double? fallback;

    for (final match in matches) {
      final token = match.group(0)!;
      final value = _parsePriceToken(token);
      if (value == null || value <= 0 || value > 9999) continue;

      if (token.toUpperCase().contains('R')) {
        return value;
      }

      fallback ??= value;
    }

    return fallback;
  }

  static String _normalizeForPriceSearch(String text) {
    return text
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('l', '1')
        .replaceAll('I', '1')
        .replaceAll('S', '5')
        .replaceAll('B', '8');
  }

  static double? _parsePriceToken(String token) {
    final normalized = token
        .replaceAll(RegExp(r'R\s*\$?\s*', caseSensitive: false), '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');

    return double.tryParse(normalized);
  }
}
