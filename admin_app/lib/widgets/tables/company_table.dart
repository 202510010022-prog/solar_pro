import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/admin_theme.dart';
import '../../models/admin_company.dart';
import '../../models/admin_plan.dart';
import '../status_pills.dart';

class CompanyTable extends StatelessWidget {
  const CompanyTable({
    super.key,
    required this.companies,
    required this.plans,
    required this.onEdit,
  });

  final List<AdminCompany> companies;
  final List<AdminPlan> plans;
  final void Function(AdminCompany company, List<AdminPlan> plans) onEdit;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    if (companies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Nenhuma empresa encontrada.',
            style: TextStyle(color: AdminTheme.muted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AdminTheme.text,
        ),
        dataTextStyle: const TextStyle(color: AdminTheme.text),
        columns: const [
          DataColumn(label: Text('Empresa')),
          DataColumn(label: Text('Plano')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Vencimento')),
          DataColumn(label: Text('Usuários')),
          DataColumn(label: Text('Projetos')),
          DataColumn(label: Text('Pendente')),
          DataColumn(label: Text('Ações')),
        ],
        rows: companies.map((company) {
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 260,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        company.billingEmail.isEmpty
                            ? company.document
                            : company.billingEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AdminTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(Text(company.planSlug)),
              DataCell(
                StatusPill(status: company.status, active: company.active),
              ),
              DataCell(PlanDueCell(company: company)),
              DataCell(Text('${company.usersCount}')),
              DataCell(Text('${company.projectsCount}')),
              DataCell(Text(money.format(company.pendingAmount))),
              DataCell(
                IconButton(
                  onPressed: () => onEdit(company, plans),
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Editar empresa',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class PlanDueCell extends StatelessWidget {
  const PlanDueCell({super.key, required this.company});

  final AdminCompany company;

  @override
  Widget build(BuildContext context) {
    final dueAt = company.planDueAt;
    final days = company.daysUntilDue;
    final date = DateFormat('dd/MM/yyyy');

    final Color color;
    final String label;
    if (dueAt == null || days == null) {
      color = AdminTheme.muted;
      label = 'Sem vencimento';
    } else if (days < 0) {
      color = Colors.redAccent;
      label = 'Vencido há ${days.abs()}d';
    } else if (days == 0) {
      color = AdminTheme.orange;
      label = 'Vence hoje';
    } else if (days <= 7) {
      color = AdminTheme.orange;
      label = 'Vence em ${days}d';
    } else if (days <= 15) {
      color = AdminTheme.cyan;
      label = 'Vence em ${days}d';
    } else {
      color = AdminTheme.green;
      label = 'Em dia';
    }

    return SizedBox(
      width: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dueAt == null ? '-' : date.format(dueAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.40)),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
