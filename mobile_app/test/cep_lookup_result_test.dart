import 'package:flutter_test/flutter_test.dart';
import 'package:solarpro_mobile/services/client_service.dart';

void main() {
  CepLookupResult resultWithResolution(String? addressResolution) {
    return CepLookupResult.fromMap({
      'zip_code': '01001000',
      'street': 'Praca da Se',
      'neighborhood': 'Se',
      'city': 'Sao Paulo',
      'state': 'SP',
      'source': 'viacep',
      if (addressResolution != null) 'address_resolution': addressResolution,
    });
  }

  test('interpreta resolucao de endereco street', () {
    final result = resultWithResolution('street');

    expect(result.zipCode, '01001000');
    expect(result.street, 'Praca da Se');
    expect(result.neighborhood, 'Se');
    expect(result.city, 'Sao Paulo');
    expect(result.state, 'SP');
    expect(result.source, 'viacep');
    expect(result.addressResolution, 'street');
  });

  test('interpreta resolucao de endereco neighborhood', () {
    expect(
        resultWithResolution('neighborhood').addressResolution, 'neighborhood');
  });

  test('interpreta resolucao de endereco locality', () {
    expect(resultWithResolution('locality').addressResolution, 'locality');
  });

  test('mantem retrocompatibilidade sem address_resolution', () {
    expect(resultWithResolution(null).addressResolution, isNull);
  });
}
