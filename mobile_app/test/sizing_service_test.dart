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

  test('usa dias reais de cada mes na geracao mensal', () {
    final service = SizingService();

    final result = service.calculate(
      monthlyConsumption: [1450, ...List<double>.filled(11, 0)],
      monthlyHsp: List<double>.filled(12, 5),
      generationExtraPercent: 0,
      performanceRatio: 0.8,
      modulePower: 1000,
      tariff: 0.95,
      projectValue: 25000,
    );

    expect(result.systemPower, 1);
    expect(result.monthlyGenerations[0], closeTo(124, 0.001));
    expect(result.monthlyGenerations[1], closeTo(112, 0.001));
    expect(result.monthlyGenerations[3], closeTo(120, 0.001));
    expect(
      result.monthlyGenerations[0] / result.monthlyGenerations[1],
      closeTo(31 / 28, 0.001),
    );
    expect(
      result.monthlyGenerations[0],
      greaterThan(result.monthlyGenerations[3]),
    );
    expect(
      result.monthlyGenerations[3],
      greaterThan(result.monthlyGenerations[1]),
    );
  });

  test('calcula geracao anual pela soma das geracoes mensais', () {
    final service = SizingService();

    final result = service.calculate(
      monthlyConsumption: List<double>.filled(12, 500),
      monthlyHsp: const [
        5.1,
        5.0,
        4.8,
        4.6,
        4.4,
        4.2,
        4.3,
        4.5,
        4.7,
        4.9,
        5.0,
        5.2
      ],
      generationExtraPercent: 10,
      performanceRatio: 0.8,
      modulePower: 550,
      tariff: 0.95,
      projectValue: 25000,
    );
    final monthlyTotal =
        result.monthlyGenerations.fold<double>(0, (sum, item) => sum + item);

    expect(result.annualGeneration, closeTo(monthlyTotal, 0.001));
  });

  test('dimensiona potencia usando horas solares equivalentes anuais', () {
    final service = SizingService();
    const hsp = [5.0, 4.8, 5.2, 5.1, 4.9, 4.7, 4.6, 4.8, 5.0, 5.2, 5.3, 5.1];
    const days = SizingService.daysInMonth;
    final annualEquivalentSolarHours = List<double>.generate(
      12,
      (index) => hsp[index] * days[index],
    ).fold<double>(0, (sum, item) => sum + item);
    const annualConsumption = 7200.0;
    const generationExtraPercent = 10.0;
    const performanceRatio = 0.8;
    const modulePower = 550.0;
    final targetAnnualGeneration =
        annualConsumption * (1 + generationExtraPercent / 100);
    final rawSystemPower = targetAnnualGeneration /
        (annualEquivalentSolarHours * performanceRatio);
    final expectedModuleCount = (rawSystemPower * 1000 / modulePower).ceil();

    final result = service.calculate(
      monthlyConsumption: List<double>.filled(12, annualConsumption / 12),
      monthlyHsp: hsp,
      generationExtraPercent: generationExtraPercent,
      performanceRatio: performanceRatio,
      modulePower: modulePower,
      tariff: 0.95,
      projectValue: 25000,
    );

    expect(result.moduleCount, expectedModuleCount);
    expect(result.systemPower,
        closeTo(expectedModuleCount * modulePower / 1000, 0.001));
  });

  test('usa ano climatologico padrao de 365 dias, nao 360', () {
    final service = SizingService();
    final totalDays =
        SizingService.daysInMonth.fold<int>(0, (sum, item) => sum + item);

    final result = service.calculate(
      monthlyConsumption: [360, ...List<double>.filled(11, 0)],
      monthlyHsp: List<double>.filled(12, 1),
      generationExtraPercent: 0,
      performanceRatio: 1,
      modulePower: 1000,
      tariff: 0.95,
      projectValue: 25000,
    );

    expect(totalDays, 365);
    expect(result.systemPower, 1);
    expect(result.annualGeneration, closeTo(365, 0.001));
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
