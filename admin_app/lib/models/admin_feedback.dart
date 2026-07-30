class AdminFeedback {
  const AdminFeedback({
    required this.id,
    required this.companyName,
    required this.profileName,
    required this.profileEmail,
    required this.rating,
    required this.area,
    required this.message,
    required this.status,
    required this.appVersion,
    required this.deviceInfo,
    required this.createdAt,
  });

  final int id;
  final String companyName;
  final String profileName;
  final String profileEmail;
  final int rating;
  final String area;
  final String message;
  final String status;
  final String appVersion;
  final String deviceInfo;
  final DateTime? createdAt;

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

  String get statusLabel {
    return switch (status) {
      'open' => 'Aberto',
      'reviewing' => 'Em análise',
      'resolved' => 'Resolvido',
      'archived' => 'Arquivado',
      _ => status,
    };
  }

  factory AdminFeedback.fromMap(Map<String, dynamic> map) {
    final company = map['companies'];
    final profile = map['profiles'];
    final companyMap = company is Map ? Map<String, dynamic>.from(company) : {};
    final profileMap = profile is Map ? Map<String, dynamic>.from(profile) : {};
    return AdminFeedback(
      id: _int(map['id']),
      companyName: '${companyMap['name'] ?? 'Empresa'}',
      profileName: '${profileMap['name'] ?? 'Usuário'}',
      profileEmail: '${profileMap['email'] ?? ''}',
      rating: _int(map['rating']),
      area: '${map['area'] ?? 'geral'}',
      message: '${map['message'] ?? ''}',
      status: '${map['status'] ?? 'open'}',
      appVersion: '${map['app_version'] ?? ''}',
      deviceInfo: '${map['device_info'] ?? ''}',
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
