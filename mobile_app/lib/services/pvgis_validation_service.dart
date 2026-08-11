class PvgisValidationResult {
  static const reviewThresholdPercent = 15.0;
  static const presentationEquivalenceThresholdPercent = 0.05;

  const PvgisValidationResult({
    required this.estimatedAnnualGeneration,
    required this.pvgisAnnualGeneration,
    required this.monthlyGenerations,
    required this.monthlyHsp,
    required this.differencePercent,
    required this.latitude,
    required this.longitude,
    required this.locationSource,
    required this.locationLabel,
    required this.orientationMode,
    this.pvSlope,
    this.pvAzimuth,
    this.pvgisAspect,
    this.pvgisSystemLossPercent,
    this.pvgisRadiationDatabase,
    this.pvgisAnnualGenerationSource,
    this.monthlyAverageDailyGenerationKwh = const [],
    this.monthlyPlaneIrradiationKwhM2 = const [],
    this.monthlyGenerationSdKwh = const [],
    this.pvgisAnnualPlaneIrradiationKwhM2,
    this.pvgisAnnualGenerationSdKwh,
    this.pvgisLAoiPercent,
    this.pvgisLSpecPercent,
    this.pvgisLTgPercent,
    this.pvgisLTotalPercent,
  });

  final double estimatedAnnualGeneration;
  final double pvgisAnnualGeneration;
  final List<double> monthlyGenerations;

  /// HSP médio diário de cada mês em h/dia, vindo do PVGIS H(i)_d.
  final List<double> monthlyHsp;
  final double differencePercent;
  final double latitude;
  final double longitude;
  final String locationSource;
  final String locationLabel;
  final String orientationMode;
  final double? pvSlope;
  final double? pvAzimuth;
  final double? pvgisAspect;
  final double? pvgisSystemLossPercent;
  final String? pvgisRadiationDatabase;
  final String? pvgisAnnualGenerationSource;

  /// Produção fotovoltaica média diária de cada mês [kWh/dia], PVGIS E_d.
  final List<double> monthlyAverageDailyGenerationKwh;

  /// Irradiação mensal no plano dos módulos [kWh/m²/mês], PVGIS H(i)_m.
  final List<double> monthlyPlaneIrradiationKwhM2;

  /// Desvio padrão da produção mensal [kWh], PVGIS SD_m.
  final List<double> monthlyGenerationSdKwh;

  /// Irradiação anual no plano dos módulos [kWh/m²/ano], PVGIS H(i)_y.
  final double? pvgisAnnualPlaneIrradiationKwhM2;

  /// Desvio padrão anual da geração [kWh], PVGIS SD_y.
  final double? pvgisAnnualGenerationSdKwh;

  /// Perdas detalhadas PVGIS [%]; o sinal original do PVGIS é preservado.
  final double? pvgisLAoiPercent;
  final double? pvgisLSpecPercent;
  final double? pvgisLTgPercent;
  final double? pvgisLTotalPercent;

  double get absoluteDifferencePercent => differencePercent.abs();
  bool get isPvgisHigher => differencePercent > 0;
  bool get isPvgisLower => differencePercent < 0;
  bool get isEquivalentForDisplay =>
      absoluteDifferencePercent < presentationEquivalenceThresholdPercent;
  bool get needsReview => absoluteDifferencePercent > reviewThresholdPercent;
  String get badgeLabel => needsReview ? 'Revisar' : 'OK';

  factory PvgisValidationResult.fromMap(Map<String, dynamic> map) {
    final monthly = map['monthly_generations'];
    final hsp = map['monthly_hsp'];
    return PvgisValidationResult(
      estimatedAnnualGeneration: _double(map['estimated_annual_generation']),
      pvgisAnnualGeneration: _double(map['pvgis_annual_generation']),
      monthlyGenerations: monthly is List
          ? monthly.map(_double).take(12).toList()
          : const <double>[],
      monthlyHsp:
          hsp is List ? hsp.map(_double).take(12).toList() : const <double>[],
      differencePercent: _double(map['difference_percent']),
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
      locationSource: '${map['location_source'] ?? ''}',
      locationLabel: '${map['location_label'] ?? ''}',
      orientationMode: '${map['orientation_mode'] ?? 'automatic'}',
      pvSlope: _nullableDouble(map['pv_slope']),
      pvAzimuth: _nullableDouble(map['pv_azimuth']),
      pvgisAspect: _nullableDouble(map['pvgis_aspect']),
      pvgisSystemLossPercent: _nullableDouble(map['pvgis_system_loss_percent']),
      pvgisRadiationDatabase: _nullableString(map['pvgis_radiation_database']),
      pvgisAnnualGenerationSource:
          _nullableString(map['pvgis_annual_generation_source']),
      monthlyAverageDailyGenerationKwh: _optionalMonthlyDoubleList(
        map['monthly_average_daily_generation_kwh'],
      ),
      monthlyPlaneIrradiationKwhM2: _optionalMonthlyDoubleList(
        map['monthly_plane_irradiation_kwh_m2'],
      ),
      monthlyGenerationSdKwh: _optionalMonthlyDoubleList(
        map['monthly_generation_sd_kwh'],
      ),
      pvgisAnnualPlaneIrradiationKwhM2: _nullableDouble(
        map['pvgis_annual_plane_irradiation_kwh_m2'],
      ),
      pvgisAnnualGenerationSdKwh: _nullableDouble(
        map['pvgis_annual_generation_sd_kwh'],
      ),
      pvgisLAoiPercent: _nullableDouble(map['pvgis_l_aoi_percent']),
      pvgisLSpecPercent: _nullableDouble(map['pvgis_l_spec_percent']),
      pvgisLTgPercent: _nullableDouble(map['pvgis_l_tg_percent']),
      pvgisLTotalPercent: _nullableDouble(map['pvgis_l_total_percent']),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final raw = '$value'.trim();
    return raw.isEmpty || raw == 'null' ? null : raw;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final number = value.toDouble();
      return number.isFinite ? number : null;
    }
    final raw = '$value'.trim();
    if (raw.isEmpty || raw == 'null') return null;
    final number = double.tryParse(raw);
    return number?.isFinite == true ? number : null;
  }

  static List<double> _optionalMonthlyDoubleList(dynamic value) {
    if (value is! List || value.length != 12) return const <double>[];
    final parsed = <double>[];
    for (final item in value) {
      final number = _nullableDouble(item);
      if (number == null) return const <double>[];
      parsed.add(number);
    }
    return List<double>.unmodifiable(parsed);
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
