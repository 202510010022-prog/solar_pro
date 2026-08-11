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

  test('limita economia anual ao consumo anual compensavel', () {
    const tariff = 0.95;
    const projectValue = 25000.0;
    final base = SizingResult(
      averageConsumption: 500,
      averageHsp: 5,
      annualConsumption: 6000,
      annualGeneration: 0,
      monthlyGenerations: const [],
      monthlyBalances: const [],
      systemPower: 4.95,
      moduleCount: 9,
      monthlyGeneration: 0,
      monthlySavings: 0,
      paybackYears: 0,
    );

    final result = base.withMonthlyGenerations(
      generations: List<double>.filled(12, 7312.8 / 12),
      consumption: List<double>.filled(12, 500),
      tariff: tariff,
      projectValue: projectValue,
    );

    expect(result.annualConsumption, 6000);
    expect(result.annualGeneration, closeTo(7312.8, 0.001));
    expect(result.monthlySavings, closeTo(475, 0.001));
    expect(result.paybackYears, closeTo(projectValue / (6000 * tariff), 0.001));
  });
}
