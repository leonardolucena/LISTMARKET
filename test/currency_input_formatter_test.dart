import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listmarket/utils/currency_input_formatter.dart';

void main() {
  group('CurrencyInputFormatter', () {
    final formatter = CurrencyInputFormatter();

    TextEditingValue format(String oldText, String newText) {
      return formatter.formatEditUpdate(
        TextEditingValue(text: oldText),
        TextEditingValue(text: newText),
      );
    }

    test('formata digitos como centavos', () {
      expect(format('', '5').text, '0,05');
      expect(format('0,05', '50').text, '0,50');
      expect(format('0,50', '500').text, '5,00');
    });

    test('converte double para texto formatado', () {
      expect(CurrencyInputFormatter.formatDouble(12.99), '12,99');
    });

    test('le texto formatado como double', () {
      expect(CurrencyInputFormatter.parseFormattedPrice('5,00'), 5.0);
    });
  });
}
