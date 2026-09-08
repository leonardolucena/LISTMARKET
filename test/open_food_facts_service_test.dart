import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:listmarket/models/product_lookup_result.dart';
import 'package:listmarket/services/open_food_facts_service.dart';

void main() {
  group('OpenFoodFactsService', () {
    test('retorna sucesso com nome, marca e imagem', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://br.openfoodfacts.org/api/v2/product/7891000100103.json',
        );
        return http.Response('''
{
  "status": 1,
  "product": {
    "product_name": "Leite Integral",
    "brands": "Nestlé, Nestle",
    "image_front_url": "https://example.com/leite.jpg"
  }
}
''', 200);
      });

      final service = OpenFoodFactsService(client: client);
      final result = await service.lookupBarcode('7891000100103');

      expect(result, isA<ProductLookupSuccess>());
      final product = (result as ProductLookupSuccess).product;
      expect(product.name, 'Leite Integral');
      expect(product.brand, 'Nestlé');
      expect(product.imageUrl, 'https://example.com/leite.jpg');
      expect(product.displayName, 'Leite Integral (Nestlé)');
    });

    test('retorna não encontrado quando status é 0', () async {
      final client = MockClient((request) async {
        return http.Response('{"status": 0}', 200);
      });

      final service = OpenFoodFactsService(client: client);
      final result = await service.lookupBarcode('000');

      expect(result, isA<ProductLookupNotFound>());
    });

    test('retorna erro de conexão quando a requisição falha', () async {
      final client = MockClient((request) async {
        throw Exception('Sem internet');
      });

      final service = OpenFoodFactsService(client: client);
      final result = await service.lookupBarcode('123');

      expect(result, isA<ProductLookupConnectionError>());
    });
  });
}
