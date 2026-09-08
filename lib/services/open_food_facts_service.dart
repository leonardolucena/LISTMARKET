import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_lookup_result.dart';

class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://br.openfoodfacts.org/api/v2/product';

  Future<ProductLookupResult> lookupBarcode(String barcode) async {
    final sanitizedBarcode = barcode.trim();
    if (sanitizedBarcode.isEmpty) {
      return ProductLookupNotFound(sanitizedBarcode);
    }

    try {
      final uri = Uri.parse('$_baseUrl/$sanitizedBarcode.json');
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return ProductLookupNotFound(sanitizedBarcode);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'];

      if (status != 1) {
        return ProductLookupNotFound(sanitizedBarcode);
      }

      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) {
        return ProductLookupNotFound(sanitizedBarcode);
      }

      final name = _readProductName(product);
      if (name.isEmpty) {
        return ProductLookupNotFound(sanitizedBarcode);
      }

      return ProductLookupSuccess(
        ProductInfo(
          barcode: sanitizedBarcode,
          name: name,
          brand: _readBrand(product),
          imageUrl: _readImageUrl(product),
        ),
      );
    } catch (_) {
      return ProductLookupConnectionError(sanitizedBarcode);
    }
  }

  String _readProductName(Map<String, dynamic> product) {
    const keys = [
      'product_name_pt',
      'product_name',
      'generic_name_pt',
      'generic_name',
      'abbreviated_product_name',
    ];

    for (final key in keys) {
      final value = product[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  String? _readBrand(Map<String, dynamic> product) {
    final brands = product['brands'];
    if (brands is! String || brands.trim().isEmpty) return null;
    return brands.split(',').first.trim();
  }

  String? _readImageUrl(Map<String, dynamic> product) {
    const keys = ['image_front_url', 'image_url', 'image_small_url'];

    for (final key in keys) {
      final value = product[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }
}
