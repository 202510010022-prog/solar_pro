class AppSubscription {
  const AppSubscription({
    required this.companyId,
    required this.companyName,
    required this.planSlug,
    required this.planName,
    required this.status,
    required this.trialEndsAt,
    required this.subscriptionEndsAt,
    required this.billingProvider,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.maxUsers,
    required this.maxProjectsPerMonth,
    required this.allowFinancial,
    required this.allowReports,
    required this.allowTeamSync,
  });

  final String companyId;
  final String companyName;
  final String planSlug;
  final String planName;
  final String status;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionEndsAt;
  final String billingProvider;
  final double monthlyPrice;
  final double annualPrice;
  final int? maxUsers;
  final int? maxProjectsPerMonth;
  final bool allowFinancial;
  final bool allowReports;
  final bool allowTeamSync;

  bool get isActive {
    if (status == 'active') return true;
    if (status == 'trial') {
      final end = trialEndsAt;
      return end == null || end.isAfter(DateTime.now());
    }
    return false;
  }

  String get statusLabel {
    return switch (status) {
      'trial' => 'Teste grátis',
      'active' => 'Ativa',
      'past_due' => 'Pagamento atrasado',
      'canceled' => 'Cancelada',
      'blocked' => 'Bloqueada',
      _ => status,
    };
  }

  String get providerLabel {
    return switch (billingProvider) {
      'manual' => 'Manual',
      'asaas' => 'Asaas',
      'mercado_pago' => 'Mercado Pago',
      'stripe' => 'Stripe',
      _ => billingProvider,
    };
  }

  factory AppSubscription.fromMap(Map<String, dynamic> map) {
    return AppSubscription(
      companyId: '${map['company_id'] ?? ''}',
      companyName: '${map['company_name'] ?? ''}',
      planSlug: '${map['plan_slug'] ?? 'starter'}',
      planName: '${map['plan_name'] ?? 'Starter'}',
      status: '${map['subscription_status'] ?? 'blocked'}',
      trialEndsAt: _date(map['trial_ends_at']),
      subscriptionEndsAt: _date(map['subscription_ends_at']),
      billingProvider: '${map['billing_provider'] ?? 'manual'}',
      monthlyPrice: _double(map['monthly_price']),
      annualPrice: _double(map['annual_price']),
      maxUsers: _nullableInt(map['max_users']),
      maxProjectsPerMonth: _nullableInt(map['max_projects_per_month']),
      allowFinancial: map['allow_financial'] == true,
      allowReports: map['allow_reports'] == true,
      allowTeamSync: map['allow_team_sync'] != false,
    );
  }

  static DateTime? _date(dynamic value) {
    final raw = '${value ?? ''}'.trim();
    if (raw.isEmpty || raw == 'null') return null;
    return DateTime.tryParse(raw);
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}

class SubscriptionValidation {
  const SubscriptionValidation.allowed() : message = null;
  const SubscriptionValidation.blocked(this.message);

  final String? message;

  bool get allowed => message == null;
}
