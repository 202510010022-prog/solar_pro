import 'admin_company.dart';
import 'admin_payment.dart';
import 'admin_user.dart';

class CommercialReportData {
  const CommercialReportData({
    required this.monthlyReceived,
    required this.pendingRevenue,
    required this.overdueRevenue,
    required this.conversionRate,
    required this.statusItems,
    required this.usersByPlanItems,
    required this.topCompanies,
  });

  final double monthlyReceived;
  final double pendingRevenue;
  final double overdueRevenue;
  final double conversionRate;
  final List<ReportBreakdownItem> statusItems;
  final List<ReportBreakdownItem> usersByPlanItems;
  final List<AdminCompany> topCompanies;

  factory CommercialReportData.from({
    required List<AdminCompany> companies,
    required List<AdminPayment> payments,
    required List<AdminUser> users,
  }) {
    final now = DateTime.now();
    final monthlyReceived = payments
        .where(
          (payment) =>
              payment.status == 'paid' &&
              payment.paidAt != null &&
              payment.paidAt!.year == now.year &&
              payment.paidAt!.month == now.month,
        )
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final pendingRevenue = payments
        .where((payment) => payment.status == 'pending')
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final overdueRevenue = payments
        .where((payment) => payment.status == 'overdue')
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final trialCount = companies.where((item) => item.status == 'trial').length;
    final activeCount = companies
        .where((item) => item.status == 'active')
        .length;
    final conversionBase = trialCount + activeCount;
    final conversionRate = conversionBase == 0
        ? 0.0
        : (activeCount / conversionBase) * 100;

    final byStatus = <String, int>{};
    for (final company in companies) {
      final label = _statusLabel(company.status, company.active);
      byStatus[label] = (byStatus[label] ?? 0) + 1;
    }

    final usersByPlan = <String, int>{};
    final planByCompany = {
      for (final company in companies) company.id: company.planSlug,
    };
    for (final user in users.where((user) => user.active)) {
      final plan = planByCompany[user.companyId] ?? 'sem plano';
      usersByPlan[plan] = (usersByPlan[plan] ?? 0) + 1;
    }

    final topCompanies = [...companies]
      ..sort((a, b) {
        final aScore = (a.projectsCount * 3) + a.usersCount;
        final bScore = (b.projectsCount * 3) + b.usersCount;
        return bScore.compareTo(aScore);
      });

    return CommercialReportData(
      monthlyReceived: monthlyReceived,
      pendingRevenue: pendingRevenue,
      overdueRevenue: overdueRevenue,
      conversionRate: conversionRate,
      statusItems: byStatus.entries
          .map((entry) => ReportBreakdownItem(entry.key, entry.value))
          .toList(),
      usersByPlanItems: usersByPlan.entries
          .map((entry) => ReportBreakdownItem(entry.key, entry.value))
          .toList(),
      topCompanies: topCompanies.take(5).toList(),
    );
  }

  static String _statusLabel(String status, bool active) {
    if (!active) return 'Inativa';
    return switch (status) {
      'active' => 'Ativa',
      'trial' => 'Teste',
      'past_due' => 'Atrasada',
      'blocked' => 'Bloqueada',
      'canceled' => 'Cancelada',
      _ => status,
    };
  }
}

class ReportBreakdownItem {
  const ReportBreakdownItem(this.label, this.value);

  final String label;
  final int value;
}
