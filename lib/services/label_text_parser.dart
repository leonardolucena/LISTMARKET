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

class LabelTextParser {
  LabelTextParser._();

  static final RegExp pricePattern = RegExp(r'(R\$\s*)?\d+[\.,]\d{2}');
  static final RegExp longNumberPattern = RegExp(r'\d{4,}');

  static ShelfLabelScanResult parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return ShelfLabelScanResult(
      name: _extractName(lines),
      price: _extractPrice(rawText),
      rawText: rawText,
    );
  }

  static String? _extractName(List<String> lines) {
    for (final line in lines) {
      if (pricePattern.hasMatch(line)) continue;
      if (longNumberPattern.hasMatch(line)) continue;
      if (RegExp(r'^[\d\s\.,R\$]+$').hasMatch(line)) continue;
      if (line.length < 2) continue;
      return line;
    }

    return lines.isNotEmpty ? lines.first : null;
  }

  static double? _extractPrice(String text) {
    final match = pricePattern.firstMatch(text);
    if (match == null) return null;

    final normalized = match
        .group(0)!
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');

    return double.tryParse(normalized);
  }
}
