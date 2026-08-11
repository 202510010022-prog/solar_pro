class SizingResult {
  const SizingResult({
    required this.averageConsumption,
    required this.averageHsp,
    required this.annualConsumption,
    required this.annualGeneration,
    required this.monthlyGenerations,
    required this.monthlyBalances,
    required this.systemPower,
    required this.moduleCount,
    required this.monthlyGeneration,
    required this.monthlySavings,
    required this.paybackYears,
  });

  final double averageConsumption;
  final double averageHsp;
  final double annualConsumption;
  final double annualGeneration;
  final List<double> monthlyGenerations;
  final List<double> monthlyBalances;
  final double systemPower;
  final int moduleCount;
  final double monthlyGeneration;
  final double monthlySavings;
  final double paybackYears;

  SizingResult withMonthlyGenerations({
    required List<double> generations,
    required List<double> consumption,
    required double tariff,
    required double projectValue,
  }) {
    final normalizedGeneration = _normalizeList(generations, 12);
    final normalizedConsumption = _normalizeList(consumption, 12);
    final balances = List<double>.generate(
      12,
      (index) => normalizedGeneration[index] - normalizedConsumption[index],
    );
    final annual =
        normalizedGeneration.fold<double>(0, (sum, item) => sum + item);
    final monthly = annual / 12;
    final annualConsumptionTotal =
        normalizedConsumption.fold<double>(0, (sum, item) => sum + item);
    final annualSavings =
        _compensableAnnualGeneration(annual, annualConsumptionTotal) * tariff;
    final savings = annualSavings / 12;

    return SizingResult(
      averageConsumption: averageConsumption,
      averageHsp: averageHsp,
      annualConsumption: annualConsumption,
      annualGeneration: annual,
      monthlyGenerations: normalizedGeneration,
      monthlyBalances: balances,
      systemPower: systemPower,
      moduleCount: moduleCount,
      monthlyGeneration: monthly,
      monthlySavings: savings,
      paybackYears: annualSavings <= 0 ? 0 : projectValue / annualSavings,
    );
  }
}

class SizingService {
  static const daysInMonth = <int>[
    31,
    28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ];

  SizingResult calculate({
    required List<double> monthlyConsumption,
    required List<double> monthlyHsp,
    required double generationExtraPercent,
    required double performanceRatio,
    required double modulePower,
    required double tariff,
    required double projectValue,
  }) {
    final consumption = _normalize(monthlyConsumption, 12);
    final hsp = _normalize(monthlyHsp, 12);
    final annualConsumption =
        consumption.fold<double>(0, (sum, item) => sum + item);
    final averageConsumption = annualConsumption / 12;
    final averageHsp = hsp.fold<double>(0, (sum, item) => sum + item) / 12;
    final targetAnnualGeneration =
        annualConsumption * (1 + generationExtraPercent / 100);
    final safeHsp = averageHsp <= 0 ? 1.0 : averageHsp;
    final safePr = performanceRatio <= 0 ? 0.8 : performanceRatio;
    final annualEquivalentSolarHours = _annualEquivalentSolarHours(
      hsp: hsp,
      fallbackHsp: safeHsp,
    );
    final systemPower =
        targetAnnualGeneration / (annualEquivalentSolarHours * safePr);
    final moduleCount =
        modulePower <= 0 ? 0 : (systemPower * 1000 / modulePower).ceil();
    final installedPower = moduleCount * modulePower / 1000;
    final monthlyGenerations = List<double>.generate(12, (index) {
      final monthHsp = hsp[index] <= 0 ? safeHsp : hsp[index];
      return installedPower * monthHsp * daysInMonth[index] * safePr;
    });
    final monthlyBalances = List<double>.generate(
      12,
      (index) => monthlyGenerations[index] - consumption[index],
    );
    final annualGeneration =
        monthlyGenerations.fold<double>(0, (sum, item) => sum + item);
    final monthlyGeneration = annualGeneration / 12;
    final annualSavings =
        _compensableAnnualGeneration(annualGeneration, annualConsumption) *
            tariff;
    final monthlySavings = annualSavings / 12;
    final paybackYears =
        annualSavings <= 0 ? 0.0 : projectValue / annualSavings;

    return SizingResult(
      averageConsumption: averageConsumption,
      averageHsp: averageHsp,
      annualConsumption: annualConsumption,
      annualGeneration: annualGeneration,
      monthlyGenerations: monthlyGenerations,
      monthlyBalances: monthlyBalances,
      systemPower: installedPower,
      moduleCount: moduleCount,
      monthlyGeneration: monthlyGeneration,
      monthlySavings: monthlySavings,
      paybackYears: paybackYears,
    );
  }

  List<double> _normalize(List<double> values, int size) {
    return _normalizeList(values, size);
  }

  double _annualEquivalentSolarHours({
    required List<double> hsp,
    required double fallbackHsp,
  }) {
    return List<double>.generate(12, (index) {
      final monthHsp = hsp[index] <= 0 ? fallbackHsp : hsp[index];
      return monthHsp * daysInMonth[index];
    }).fold<double>(0, (sum, item) => sum + item);
  }
}

List<double> _normalizeList(List<double> values, int size) {
  if (values.length >= size) return values.take(size).toList();
  return [...values, ...List<double>.filled(size - values.length, 0)];
}

double _compensableAnnualGeneration(
  double annualGeneration,
  double annualConsumption,
) {
  if (annualGeneration <= 0 || annualConsumption <= 0) return 0;
  return annualGeneration < annualConsumption
      ? annualGeneration
      : annualConsumption;
}
