class AdminCompany {
  const AdminCompany({
    required this.id,
    required this.name,
    required this.document,
    required this.planSlug,
    required this.status,
    required this.billingEmail,
    required this.active,
    required this.createdAt,
    required this.trialEndsAt,
    required this.subscriptionEndsAt,
    required this.usersCount,
    required this.projectsCount,
    required this.pendingAmount,
  });

  final String id;
  final String name;
  final String document;
  final String planSlug;
  final String status;
  final String billingEmail;
  final bool active;
  final DateTime? createdAt;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionEndsAt;
  final int usersCount;
  final int projectsCount;
  final double pendingAmount;

  factory AdminCompany.fromMap(Map<String, dynamic> map) {
    return AdminCompany(
      id: '${map['id'] ?? ''}',
      name: '${map['name'] ?? ''}',
      document: '${map['document'] ?? ''}',
      planSlug: '${map['plan_slug'] ?? 'starter'}',
      status: '${map['subscription_status'] ?? 'trial'}',
      billingEmail: '${map['billing_email'] ?? ''}',
      active: map['active'] != false,
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
      trialEndsAt: DateTime.tryParse('${map['trial_ends_at'] ?? ''}'),
      subscriptionEndsAt: DateTime.tryParse(
        '${map['subscription_ends_at'] ?? ''}',
      ),
      usersCount: _int(map['users_count']),
      projectsCount: _int(map['projects_count']),
      pendingAmount: _double(map['pending_amount']),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  DateTime? get planDueAt => subscriptionEndsAt ?? trialEndsAt;

  int? get daysUntilDue {
    final dueAt = planDueAt;
    if (dueAt == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueAt.year, dueAt.month, dueAt.day);
    return due.difference(today).inDays;
  }
}
