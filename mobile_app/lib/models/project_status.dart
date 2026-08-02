enum ProjectStatus {
  negotiating(
    dbValue: 'Em negociação',
    label: 'Em negociação',
    dashboardLabel: 'Em negociação',
  ),
  approved(
    dbValue: 'Aprovado',
    label: 'Aprovado',
    dashboardLabel: 'Aprovados',
  ),
  installing(
    dbValue: 'Em instalação',
    label: 'Em instalação',
    dashboardLabel: 'Instalação',
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

  static const _legacyClosedDbValue = 'Fechado';

  static const ordered = [
    negotiating,
    approved,
    installing,
    completed,
    rejected,
  ];

  static List<String> get dbValues =>
      ordered.map((status) => status.dbValue).toList(growable: false);

  static ProjectStatus? fromDbValue(String value) {
    if (value.trim() == _legacyClosedDbValue) return approved;
    for (final status in ordered) {
      if (status.dbValue == value.trim()) return status;
    }
    return null;
  }

  static String fallbackDbValue(String? value) {
    final raw = (value ?? '').trim();
    return fromDbValue(raw)?.dbValue ?? negotiating.dbValue;
  }

  static String labelFor(String value) => fromDbValue(value)?.label ?? value;

  bool matches(String value) => fromDbValue(value) == this;

  static bool isConverted(String value) =>
      approved.matches(value) ||
      installing.matches(value) ||
      completed.matches(value);

  static bool isPipeline(String value) => !rejected.matches(value);
}
