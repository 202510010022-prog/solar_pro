class AppProfile {
  const AppProfile({
    required this.id,
    required this.companyId,
    required this.name,
    required this.email,
    required this.matricula,
    required this.role,
    required this.permission,
    required this.active,
  });

  final String id;
  final String companyId;
  final String name;
  final String email;
  final String matricula;
  final String role;
  final String permission;
  final bool active;

  bool get canUseFinancial =>
      permission == 'assessor_daf' ||
      permission == 'diretor' ||
      permission == 'admin' ||
      permission == 'owner';

  bool get canManageAll =>
      permission == 'diretor' || permission == 'admin' || permission == 'owner';

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    return AppProfile(
      id: '${map['id'] ?? ''}',
      companyId: '${map['company_id'] ?? ''}',
      name: '${map['name'] ?? ''}',
      email: '${map['email'] ?? ''}',
      matricula: '${map['matricula'] ?? ''}',
      role: '${map['role'] ?? ''}',
      permission: '${map['permission'] ?? 'assessor_projetos'}',
      active: map['active'] != false,
    );
  }
}
