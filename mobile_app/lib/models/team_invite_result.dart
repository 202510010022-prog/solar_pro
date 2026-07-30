class TeamInviteResult {
  const TeamInviteResult({
    required this.email,
    required this.name,
    required this.matricula,
    required this.role,
    required this.permission,
    required this.temporaryPassword,
    required this.message,
  });

  final String email;
  final String name;
  final String matricula;
  final String role;
  final String permission;
  final String temporaryPassword;
  final String message;

  factory TeamInviteResult.fromMap(Map<String, dynamic> map) {
    final user = map['user'];
    final userMap = user is Map ? user : const {};
    return TeamInviteResult(
      email: '${userMap['email'] ?? ''}',
      name: '${userMap['name'] ?? ''}',
      matricula: '${userMap['matricula'] ?? ''}',
      role: '${userMap['role'] ?? ''}',
      permission: '${userMap['permission'] ?? ''}',
      temporaryPassword: '${map['temporary_password'] ?? ''}',
      message: '${map['message'] ?? ''}',
    );
  }
}
