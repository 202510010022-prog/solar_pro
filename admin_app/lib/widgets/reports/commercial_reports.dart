import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/admin_theme.dart';
import '../../models/admin_company.dart';
import '../../models/admin_payment.dart';
import '../../models/admin_user.dart';
import '../../models/commercial_report_data.dart';
import '../admin_card.dart';
import '../stat_card.dart';
import 'report_breakdown_card.dart';
import 'top_companies_card.dart';

class CommercialReports extends StatelessWidget {
  const CommercialReports({
    super.key,
    required this.companies,
    required this.payments,
    required this.users,
  });

  final List<AdminCompany> companies;
  final List<AdminPayment> payments;
  final List<AdminUser> users;

  @override
  Widget build(BuildContext context) {
    final report = CommercialReportData.from(
      companies: companies,
      payments: payments,
      users: users,
    );
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0x3300AAFF),
                child: Icon(Icons.analytics_rounded, color: AdminTheme.cyan),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relatórios comerciais',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Receita, conversão, planos e uso da plataforma.',
                      style: TextStyle(color: AdminTheme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1100 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 2.8,
                children: [
                  StatCard(
                    icon: Icons.payments_rounded,
                    label: 'Receita recebida no mês',
                    value: money.format(report.monthlyReceived),
                    color: AdminTheme.green,
                  ),
                  StatCard(
                    icon: Icons.pending_actions_rounded,
                    label: 'Receita pendente',
                    value: money.format(report.pendingRevenue),
                    color: AdminTheme.orange,
                  ),
                  StatCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Receita atrasada',
                    value: money.format(report.overdueRevenue),
                    color: Colors.redAccent,
                  ),
                  StatCard(
                    icon: Icons.trending_up_rounded,
                    label: 'Conversão teste → ativo',
                    value: '${report.conversionRate.toStringAsFixed(1)}%',
                    color: AdminTheme.cyan,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 980;
              final children = [
                ReportBreakdownCard(
                  title: 'Status das empresas',
                  icon: Icons.business_center_rounded,
                  items: report.statusItems,
                ),
                ReportBreakdownCard(
                  title: 'Usuários por plano',
                  icon: Icons.group_rounded,
                  items: report.usersByPlanItems,
                ),
                TopCompaniesCard(companies: report.topCompanies),
              ];
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children
                      .map(
                        (child) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: child,
                          ),
                        ),
                      )
                      .toList(),
                );
              }
              return Column(
                children: children
                    .map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: child,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
