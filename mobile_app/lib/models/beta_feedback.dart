class BetaFeedback {
  const BetaFeedback({
    required this.id,
    required this.rating,
    required this.area,
    required this.message,
    required this.status,
    required this.appVersion,
    required this.deviceInfo,
    required this.createdAt,
    required this.profileName,
  });

  final int id;
  final int rating;
  final String area;
  final String message;
  final String status;
  final String appVersion;
  final String deviceInfo;
  final DateTime? createdAt;
  final String profileName;

  String get statusLabel {
    return switch (status) {
      'open' => 'Aberto',
      'reviewing' => 'Em análise',
      'resolved' => 'Resolvido',
      'archived' => 'Arquivado',
      _ => status,
    };
  }

  String get areaLabel {
    return switch (area) {
      'geral' => 'Geral',
      'login' => 'Login',
      'crm' => 'CRM',
      'projetos' => 'Projetos',
      'dimensionamento' => 'Dimensionamento',
      'financeiro' => 'Financeiro',
      'sincronizacao' => 'Sincronização',
      'visual' => 'Visual',
      _ => area,
    };
  }

  factory BetaFeedback.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'];
    return BetaFeedback(
      id: _int(map['id']),
      rating: _int(map['rating']),
      area: '${map['area'] ?? 'geral'}',
      message: '${map['message'] ?? ''}',
      status: '${map['status'] ?? 'open'}',
      appVersion: '${map['app_version'] ?? ''}',
      deviceInfo: '${map['device_info'] ?? ''}',
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
      profileName: profile is Map ? '${profile['name'] ?? ''}' : '',
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
