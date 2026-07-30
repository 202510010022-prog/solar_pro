import 'package:flutter_test/flutter_test.dart';
import 'package:solarpro_mobile/services/sizing_service.dart';

void main() {
  test('calcula dimensionamento mensal basico', () {
    final service = SizingService();

    final result = service.calculate(
      monthlyConsumption: List<double>.filled(12, 500),
      monthlyHsp: List<double>.filled(12, 5),
      generationExtraPercent: 10,
      performanceRatio: 0.8,
      modulePower: 550,
      tariff: 0.95,
      projectValue: 25000,
    );

    expect(result.annualConsumption, 6000);
    expect(result.monthlyGenerations, hasLength(12));
    expect(result.monthlyBalances, hasLength(12));
    expect(result.moduleCount, greaterThan(0));
    expect(result.systemPower, greaterThan(0));
    expect(result.paybackYears, greaterThan(0));
  });
}
