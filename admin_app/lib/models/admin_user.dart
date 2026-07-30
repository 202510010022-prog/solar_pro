class AdminUser {
  const AdminUser({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.name,
    required this.email,
    required this.matricula,
    required this.role,
    required this.permission,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String companyId;
  final String companyName;
  final String name;
  final String email;
  final String matricula;
  final String role;
  final String permission;
  final bool active;
  final DateTime? createdAt;

  String get permissionLabel {
    return switch (permission) {
      'owner' => 'Master',
      'platform_admin' => 'Admin Plataforma',
      'diretor' => 'Diretor',
      'assessor_daf' => 'Assessor DAF',
      'assessor_projetos' => 'Assessor Projetos',
      _ => permission,
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    final company = map['companies'];
    final companyMap = company is Map ? Map<String, dynamic>.from(company) : {};
    return AdminUser(
      id: '${map['id'] ?? ''}',
      companyId: '${map['company_id'] ?? ''}',
      companyName: '${companyMap['name'] ?? 'Empresa'}',
      name: '${map['name'] ?? ''}',
      email: '${map['email'] ?? ''}',
      matricula: '${map['matricula'] ?? ''}',
      role: '${map['role'] ?? ''}',
      permission: '${map['permission'] ?? ''}',
      active: map['active'] != false,
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
    );
  }
}
