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
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final raw = '$value'.trim();
    return raw.isEmpty || raw == 'null' ? null : raw;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final raw = '$value'.trim();
    if (raw.isEmpty || raw == 'null') return null;
    return double.tryParse(raw);
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
