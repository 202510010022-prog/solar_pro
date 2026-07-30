class PvgisValidationResult {
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
  });

  final double estimatedAnnualGeneration;
  final double pvgisAnnualGeneration;
  final List<double> monthlyGenerations;
  final List<double> monthlyHsp;
  final double differencePercent;
  final double latitude;
  final double longitude;
  final String locationSource;
  final String locationLabel;

  bool get needsReview => differencePercent.abs() > 15;
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
    );
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
