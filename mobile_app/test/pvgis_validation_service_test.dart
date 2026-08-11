import 'package:flutter_test/flutter_test.dart';
import 'package:solarpro_mobile/services/pvgis_validation_service.dart';

void main() {
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
    });

    expect(result.monthlyHsp, hasLength(12));
    expect(result.monthlyHsp.first, 4.5);
    expect(result.monthlyHsp.last, 5.6);
    expect(result.orientationMode, 'automatic');
    expect(result.pvSlope, 1);
    expect(result.pvAzimuth, 1);
    expect(result.pvgisAspect, -179);
    expect(result.pvgisSystemLossPercent, 14);
  });

  test('mantem parsing retrocompativel sem campos de orientacao', () {
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
    });

    expect(result.monthlyHsp, hasLength(12));
    expect(result.monthlyHsp.first, 5.42);
    expect(result.orientationMode, 'automatic');
    expect(result.pvSlope, isNull);
    expect(result.pvAzimuth, isNull);
    expect(result.pvgisAspect, isNull);
    expect(result.pvgisSystemLossPercent, isNull);
  });
}
