import 'package:flutter_test/flutter_test.dart';
import 'package:solarpro_mobile/services/pvgis_validation_service.dart';

void main() {
  PvgisValidationResult resultWithDifference(double differencePercent) {
    return PvgisValidationResult.fromMap({
      'estimated_annual_generation': 6000,
      'pvgis_annual_generation': 6200,
      'monthly_generations': List<double>.filled(12, 500),
      'monthly_hsp': List<double>.filled(12, 5.42),
      'difference_percent': differencePercent,
      'latitude': -9.4,
      'longitude': -38.2,
      'location_source': 'client_address',
      'location_label': 'Paulo Afonso, BA',
    });
  }

  Map<String, dynamic> basePayload() {
    return {
      'estimated_annual_generation': 6000,
      'pvgis_annual_generation': 6200,
      'monthly_generations': List<double>.filled(12, 500),
      'monthly_hsp': List<double>.filled(12, 5.42),
      'difference_percent': 3.33,
      'latitude': -9.4,
      'longitude': -38.2,
      'location_source': 'client_address',
      'location_label': 'Paulo Afonso, BA',
    };
  }

  test('interpreta monthly_hsp como 12 valores de HSP medio diario', () {
    final result = PvgisValidationResult.fromMap({
      'estimated_annual_generation': 6000,
      'pvgis_annual_generation': 6200,
      'monthly_generations':
          List<double>.generate(12, (index) => 400.0 + index),
      'monthly_hsp': List<double>.generate(12, (index) => 4.5 + index / 10),
      'difference_percent': 3.33,
      'latitude': -9.4,
      'longitude': -38.2,
      'location_source': 'client_address',
      'location_label': 'Paulo Afonso, BA',
      'orientation_mode': 'automatic',
      'pv_slope': 1,
      'pv_azimuth': 1,
      'pvgis_aspect': -179,
      'pvgis_system_loss_percent': 14,
      'pvgis_radiation_database': 'PVGIS-SARAH3',
    });

    expect(result.monthlyHsp, hasLength(12));
    expect(result.monthlyHsp.first, 4.5);
    expect(result.monthlyHsp.last, 5.6);
    expect(result.orientationMode, 'automatic');
    expect(result.pvSlope, 1);
    expect(result.pvAzimuth, 1);
    expect(result.pvgisAspect, -179);
    expect(result.pvgisSystemLossPercent, 14);
    expect(result.pvgisRadiationDatabase, 'PVGIS-SARAH3');
  });

  test('interpreta base solar ERA5 retornada pelo PVGIS', () {
    final result = PvgisValidationResult.fromMap({
      'estimated_annual_generation': 6000,
      'pvgis_annual_generation': 6200,
      'monthly_generations': List<double>.filled(12, 500),
      'monthly_hsp': List<double>.filled(12, 5.42),
      'difference_percent': 3.33,
      'latitude': -9.4,
      'longitude': -38.2,
      'location_source': 'client_address',
      'location_label': 'Paulo Afonso, BA',
      'pvgis_radiation_database': 'PVGIS-ERA5',
    });

    expect(result.pvgisRadiationDatabase, 'PVGIS-ERA5');
  });

  test('mantem parsing retrocompativel sem campos de orientacao', () {
    final result = PvgisValidationResult.fromMap(basePayload());

    expect(result.monthlyHsp, hasLength(12));
    expect(result.monthlyHsp.first, 5.42);
    expect(result.monthlyGenerations, hasLength(12));
    expect(result.monthlyGenerations.first, 500);
    expect(result.differencePercent, 3.33);
    expect(result.needsReview, isFalse);
    expect(result.orientationMode, 'automatic');
    expect(result.pvSlope, isNull);
    expect(result.pvAzimuth, isNull);
    expect(result.pvgisAspect, isNull);
    expect(result.pvgisSystemLossPercent, isNull);
    expect(result.pvgisRadiationDatabase, isNull);
    expect(result.pvgisAnnualGenerationSource, isNull);
    expect(result.monthlyAverageDailyGenerationKwh, isEmpty);
    expect(result.monthlyPlaneIrradiationKwhM2, isEmpty);
    expect(result.monthlyGenerationSdKwh, isEmpty);
    expect(result.pvgisAnnualPlaneIrradiationKwhM2, isNull);
    expect(result.pvgisAnnualGenerationSdKwh, isNull);
    expect(result.pvgisLAoiPercent, isNull);
    expect(result.pvgisLSpecPercent, isNull);
    expect(result.pvgisLTgPercent, isNull);
    expect(result.pvgisLTotalPercent, isNull);
  });

  test('interpreta metricas PVGIS estendidas do payload completo', () {
    final result = PvgisValidationResult.fromMap({
      ...basePayload(),
      'orientation_mode': 'automatic',
      'pv_slope': 25,
      'pv_azimuth': 13,
      'pvgis_aspect': -167,
      'pvgis_system_loss_percent': 14,
      'pvgis_radiation_database': 'PVGIS-SARAH3',
      'pvgis_annual_generation_source': 'E_y',
      'monthly_average_daily_generation_kwh':
          List<double>.generate(12, (index) => 4.0 + index / 10),
      'monthly_plane_irradiation_kwh_m2':
          List<double>.generate(12, (index) => 120.0 + index),
      'monthly_generation_sd_kwh': <num>[
        0,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20
      ],
      'pvgis_annual_plane_irradiation_kwh_m2': 1774.09,
      'pvgis_annual_generation_sd_kwh': 58.43,
      'pvgis_l_aoi_percent': -2.71,
      'pvgis_l_spec_percent': null,
      'pvgis_l_tg_percent': -9.13,
      'pvgis_l_total_percent': -23.96,
    });

    expect(result.pvgisAnnualGenerationSource, 'E_y');
    expect(result.monthlyAverageDailyGenerationKwh, hasLength(12));
    expect(result.monthlyAverageDailyGenerationKwh.first, 4.0);
    expect(result.monthlyAverageDailyGenerationKwh.last, 5.1);
    expect(result.monthlyPlaneIrradiationKwhM2, hasLength(12));
    expect(result.monthlyPlaneIrradiationKwhM2.first, 120);
    expect(result.monthlyPlaneIrradiationKwhM2.last, 131);
    expect(result.monthlyGenerationSdKwh, hasLength(12));
    expect(result.monthlyGenerationSdKwh.first, 0);
    expect(result.monthlyGenerationSdKwh.last, 20);
    expect(result.pvgisAnnualPlaneIrradiationKwhM2, 1774.09);
    expect(result.pvgisAnnualGenerationSdKwh, 58.43);
    expect(result.pvgisLAoiPercent, -2.71);
    expect(result.pvgisLSpecPercent, isNull);
    expect(result.pvgisLTgPercent, -9.13);
    expect(result.pvgisLTotalPercent, -23.96);

    expect(result.monthlyHsp, hasLength(12));
    expect(result.monthlyGenerations, hasLength(12));
    expect(result.orientationMode, 'automatic');
    expect(result.pvSlope, 25);
    expect(result.pvAzimuth, 13);
    expect(result.pvgisAspect, -167);
    expect(result.pvgisSystemLossPercent, 14);
    expect(result.pvgisRadiationDatabase, 'PVGIS-SARAH3');
    expect(result.differencePercent, 3.33);
    expect(result.needsReview, isFalse);
  });

  test('interpreta fonte anual sum_E_m sem recalcular geracao anual', () {
    final result = PvgisValidationResult.fromMap({
      ...basePayload(),
      'pvgis_annual_generation': 1234.56,
      'monthly_generations': List<double>.filled(12, 1),
      'pvgis_annual_generation_source': 'sum_E_m',
    });

    expect(result.pvgisAnnualGenerationSource, 'sum_E_m');
    expect(result.pvgisAnnualGeneration, 1234.56);
  });

  test('descarta arrays mensais estendidos incompletos ou malformados', () {
    final result = PvgisValidationResult.fromMap({
      ...basePayload(),
      'monthly_average_daily_generation_kwh': [4.1, 4.2, 4.3],
      'monthly_plane_irradiation_kwh_m2':
          List<double>.generate(12, (index) => 100.0 + index)..[5] = double.nan,
      'monthly_generation_sd_kwh': List<double>.empty(),
    });

    expect(result.monthlyAverageDailyGenerationKwh, isEmpty);
    expect(result.monthlyPlaneIrradiationKwhM2, isEmpty);
    expect(result.monthlyGenerationSdKwh, isEmpty);
  });

  test('trata base solar vazia como retrocompativel', () {
    final result = PvgisValidationResult.fromMap({
      'estimated_annual_generation': 6000,
      'pvgis_annual_generation': 6200,
      'monthly_generations': List<double>.filled(12, 500),
      'monthly_hsp': List<double>.filled(12, 5.42),
      'difference_percent': 3.33,
      'latitude': -9.4,
      'longitude': -38.2,
      'location_source': 'client_address',
      'location_label': 'Paulo Afonso, BA',
      'pvgis_radiation_database': ' ',
    });

    expect(result.pvgisRadiationDatabase, isNull);
  });

  test('usa limite de revisao Solar Pro com fronteira inclusiva em 15%', () {
    expect(PvgisValidationResult.reviewThresholdPercent, 15);

    final belowThreshold = resultWithDifference(14.9);
    expect(belowThreshold.needsReview, isFalse);
    expect(belowThreshold.badgeLabel, 'OK');

    final exactThreshold = resultWithDifference(15.0);
    expect(exactThreshold.needsReview, isFalse);
    expect(exactThreshold.badgeLabel, 'OK');

    final aboveThreshold = resultWithDifference(15.1);
    expect(aboveThreshold.needsReview, isTrue);
    expect(aboveThreshold.badgeLabel, 'Revisar');
  });

  test('aplica o mesmo limite para diferencas negativas', () {
    final belowThreshold = resultWithDifference(-14.9);
    expect(belowThreshold.needsReview, isFalse);
    expect(belowThreshold.badgeLabel, 'OK');

    final exactThreshold = resultWithDifference(-15.0);
    expect(exactThreshold.needsReview, isFalse);
    expect(exactThreshold.badgeLabel, 'OK');

    final aboveThreshold = resultWithDifference(-15.1);
    expect(aboveThreshold.needsReview, isTrue);
    expect(aboveThreshold.badgeLabel, 'Revisar');
  });

  test('preserva direcao e expoe magnitude absoluta da diferenca', () {
    final pvgisHigher = resultWithDifference(10);
    expect(pvgisHigher.isPvgisHigher, isTrue);
    expect(pvgisHigher.isPvgisLower, isFalse);

    final pvgisLower = resultWithDifference(-10);
    expect(pvgisLower.isPvgisHigher, isFalse);
    expect(pvgisLower.isPvgisLower, isTrue);

    final negativeDifference = resultWithDifference(-12.5);
    expect(negativeDifference.absoluteDifferencePercent, 12.5);
  });
}
