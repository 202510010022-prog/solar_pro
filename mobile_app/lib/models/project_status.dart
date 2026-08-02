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

  static ProjectStatus? nextSequential(ProjectStatus status) {
    return switch (status) {
      negotiating => approved,
      approved => installing,
      installing => completed,
      completed || rejected => null,
    };
  }

  static List<ProjectStatus> selectableFor({
    required String currentValue,
    required bool canManageAll,
  }) {
    if (canManageAll) return ordered;

    final current = fromDbValue(currentValue) ?? negotiating;
    final options = <ProjectStatus>[current];
    final next = nextSequential(current);
    if (next != null) options.add(next);
    if (current != rejected) options.add(rejected);
    return options.toSet().toList(growable: false);
  }

  static bool isManualCorrection({
    required String currentValue,
    required String targetValue,
  }) {
    final current = fromDbValue(currentValue);
    final target = fromDbValue(targetValue);
    if (current == null || target == null || current == target) return false;

    final normalTargets = <ProjectStatus>{
      current,
      if (nextSequential(current) != null) nextSequential(current)!,
      if (current != rejected) rejected,
    };
    return !normalTargets.contains(target);
  }

  static bool isConverted(String value) =>
      approved.matches(value) ||
      installing.matches(value) ||
      completed.matches(value);

  static bool isPipeline(String value) => !rejected.matches(value);
}
