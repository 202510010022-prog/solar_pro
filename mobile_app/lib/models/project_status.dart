enum ProjectStatus {
  negotiating(
    dbValue: 'Em negociação',
    label: 'Em negociação',
    dashboardLabel: 'Em negociação',
  ),
  closed(
    dbValue: 'Fechado',
    label: 'Fechado',
    dashboardLabel: 'Aprovados',
  ),
  completed(
    dbValue: 'Concluído',
    label: 'Concluído',
    dashboardLabel: 'Concluídos',
  ),
  rejected(
    dbValue: 'Não aprovado',
    label: 'Não aprovado',
    dashboardLabel: 'Não aprovados',
  );

  const ProjectStatus({
    required this.dbValue,
    required this.label,
    required this.dashboardLabel,
  });

  final String dbValue;
  final String label;
  final String dashboardLabel;

  static const ordered = [
    negotiating,
    closed,
    completed,
    rejected,
  ];

  static List<String> get dbValues =>
      ordered.map((status) => status.dbValue).toList(growable: false);

  static ProjectStatus? fromDbValue(String value) {
    for (final status in ordered) {
      if (status.dbValue == value) return status;
    }
    return null;
  }

  static String fallbackDbValue(String? value) {
    final raw = (value ?? '').trim();
    return fromDbValue(raw)?.dbValue ?? negotiating.dbValue;
  }

  static String labelFor(String value) => fromDbValue(value)?.label ?? value;

  bool matches(String value) => value == dbValue;

  static bool isConverted(String value) =>
      closed.matches(value) || completed.matches(value);

  static bool isPipeline(String value) => !rejected.matches(value);
}
