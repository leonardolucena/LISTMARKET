import 'package:flutter_test/flutter_test.dart';
import 'package:listmarket/services/label_text_parser.dart';

void main() {
  group('LabelTextParser', () {
    test('extrai nome e preço de uma etiqueta típica', () {
      const text = '''
ARROZ TIPO 1 5KG
Tio João
R\$ 24,90
7891234567890
''';

      final result = LabelTextParser.parse(text);

      expect(result.name, 'ARROZ TIPO 1 5KG');
      expect(result.price, 24.90);
    });

    test('extrai preço sem símbolo de real', () {
      const text = '''
Feijão Carioca
12,49
''';

      final result = LabelTextParser.parse(text);

      expect(result.name, 'Feijão Carioca');
      expect(result.price, 12.49);
    });

    test('ignora linhas com números longos como código de barras', () {
      const text = '''
7891000100103
Leite Integral
3,99
''';

      final result = LabelTextParser.parse(text);

      expect(result.name, 'Leite Integral');
      expect(result.price, 3.99);
    });
  });
}
