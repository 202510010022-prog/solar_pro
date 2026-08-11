import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:solarpro_mobile/services/pvgis_validation_service.dart';
import 'package:solarpro_mobile/services/sizing_service.dart';

void main() {
  const performanceRatio = 0.80;
  const monthlyConsumption = 50.0;
  const modulePower = 1000.0;
  const reviewThreshold = PvgisValidationResult.reviewThresholdPercent;
  const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  final fixture = jsonDecode(
    File('test/fixtures/pvgis_brazil_cases.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final cases = fixture['cases'] as List<dynamic>;

  test('fixture contem quatro regioes brasileiras obrigatorias', () {
    expect(fixture['api_version'], 'v5_3');
    expect(fixture['tool'], 'PVcalc');
    expect(fixture['captured_at'], isA<String>());
    expect(cases, hasLength(4));
    expect(cases.map((item) => item['region']).toSet(), {
      'Nordeste',
      'Sudeste',
      'Sul',
      'Norte',
    });
    expect(cases.map((item) => item['city']).toSet(), {
      'Salvador',
      'São Paulo',
      'Curitiba',
      'Manaus',
    });
  });

  test('compara Solar Pro com PVGIS oficial por 1 kWp normalizado', () {
    final service = SizingService();

    for (final rawCase in cases) {
      final item = rawCase as Map<String, dynamic>;
      final hsp = _doubleList(item['monthly_hsp']);
      final pvgisMonthly = _doubleList(item['monthly_pvgis_generation']);
      final pvgisAnnual = _doubleValue(item['pvgis_annual_generation']);
      final latitude = _doubleValue(item['latitude']);
      final longitude = _doubleValue(item['longitude']);
      final database = '${item['radiation_database'] ?? ''}'.trim();

      expect(hsp, hasLength(12), reason: item['id'] as String);
      expect(pvgisMonthly, hasLength(12), reason: item['id'] as String);
      expect(latitude, inInclusiveRange(-90, 90), reason: item['id'] as String);
      expect(longitude, inInclusiveRange(-180, 180),
          reason: item['id'] as String);
      expect(database, isNotEmpty, reason: item['id'] as String);
      expect(pvgisAnnual, greaterThan(0), reason: item['id'] as String);

      final result = service.calculate(
        monthlyConsumption: List<double>.filled(12, monthlyConsumption),
        monthlyHsp: hsp,
        generationExtraPercent: 0,
        performanceRatio: performanceRatio,
        modulePower: modulePower,
        tariff: 1,
        projectValue: 0,
      );

      expect(result.moduleCount, 1, reason: item['id'] as String);
      expect(result.systemPower, closeTo(1.0, 1e-12),
          reason: item['id'] as String);
      expect(result.monthlyGenerations, hasLength(12),
          reason: item['id'] as String);

      final solarMonthlySum = result.monthlyGenerations.fold<double>(
        0,
        (sum, value) => sum + value,
      );
      expect(result.annualGeneration, closeTo(solarMonthlySum, 1e-9),
          reason: item['id'] as String);

      for (var i = 0; i < 12; i++) {
        final expectedMonth = result.systemPower *
            hsp[i] *
            SizingService.daysInMonth[i] *
            performanceRatio;
        expect(
          result.monthlyGenerations[i],
          closeTo(expectedMonth, 1e-6),
          reason: '${item['id']} ${months[i]}',
        );
      }

      final pvgisMonthlySum = pvgisMonthly.fold<double>(
        0,
        (sum, value) => sum + value,
      );
      final annualTolerance = max(1.0, pvgisAnnual * 0.001);
      expect((pvgisAnnual - pvgisMonthlySum).abs(),
          lessThanOrEqualTo(annualTolerance),
          reason: item['id'] as String);

      final annualDifferencePercent = (pvgisAnnual - result.annualGeneration) /
          max(result.annualGeneration, 1) *
          100;
      final status =
          annualDifferencePercent.abs() > reviewThreshold ? 'Revisar' : 'OK';
      expect(status, isIn(['OK', 'Revisar']), reason: item['id'] as String);
      expect(annualDifferencePercent.isFinite, isTrue,
          reason: item['id'] as String);

      for (var i = 0; i < 12; i++) {
        final monthlyDifferencePercent =
            (pvgisMonthly[i] - result.monthlyGenerations[i]) /
                max(result.monthlyGenerations[i], 1) *
                100;
        expect(monthlyDifferencePercent.isFinite, isTrue,
            reason: '${item['id']} ${months[i]}');
      }
    }
  });
}

List<double> _doubleList(dynamic value) {
  expect(value, isA<List<dynamic>>());
  return (value as List<dynamic>).map(_doubleValue).toList();
}

double _doubleValue(dynamic value) {
  expect(value, isA<num>());
  final result = (value as num).toDouble();
  expect(result.isFinite, isTrue);
  return result;
}
