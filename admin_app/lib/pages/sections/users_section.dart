import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/admin_theme.dart';
import '../../models/admin_company.dart';
import '../../models/admin_user.dart';
import '../../widgets/admin_card.dart';
import '../../widgets/tables/user_table.dart';

class UsersByCompanyPanel extends StatelessWidget {
  const UsersByCompanyPanel({
    super.key,
    required this.companies,
    required this.users,
    required this.selectedCompanyId,
    required this.onSelectCompany,
    required this.onEditCompany,
    required this.onCreateUser,
    required this.onEditUser,
    required this.onToggleActive,
  });

  final List<AdminCompany> companies;
  final List<AdminUser> users;
  final String selectedCompanyId;
  final ValueChanged<String> onSelectCompany;
  final ValueChanged<AdminCompany> onEditCompany;
  final ValueChanged<String> onCreateUser;
  final ValueChanged<AdminUser> onEditUser;
  final void Function(AdminUser user, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    if (companies.isEmpty) {
      return const AdminCard(
        child: Center(
          child: Text(
            'Cadastre uma empresa antes de criar usuários.',
            style: TextStyle(color: AdminTheme.muted),
          ),
        ),
      );
    }

    final selectedId =
        companies.any((company) => company.id == selectedCompanyId)
        ? selectedCompanyId
        : companies.first.id;
    final selectedCompany = companies.firstWhere(
      (company) => company.id == selectedId,
    );
    final selectedUsers =
        users.where((user) => user.companyId == selectedId).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final companyList = _CompanyUserSelector(
          companies: companies,
          users: users,
          selectedCompanyId: selectedId,
          onSelectCompany: onSelectCompany,
        );
        final userDetails = _CompanyUsersDetail(
          company: selectedCompany,
          users: selectedUsers,
          onEditCompany: () => onEditCompany(selectedCompany),
          onCreateUser: () => onCreateUser(selectedId),
          onEditUser: onEditUser,
          onToggleActive: onToggleActive,
        );

        if (!wide) {
          return Column(
            children: [companyList, const SizedBox(height: 18), userDetails],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 360, child: companyList),
            const SizedBox(width: 18),
            Expanded(child: userDetails),
          ],
        );
      },
    );
  }
}

class _CompanyUserSelector extends StatelessWidget {
  const _CompanyUserSelector({
    required this.companies,
    required this.users,
    required this.selectedCompanyId,
    required this.onSelectCompany,
  });

  final List<AdminCompany> companies;
  final List<AdminUser> users;
  final String selectedCompanyId;
  final ValueChanged<String> onSelectCompany;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Empresas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecione uma empresa para ver os usuários.',
            style: TextStyle(color: AdminTheme.muted),
          ),
          const SizedBox(height: 16),
          ...companies.map((company) {
            final selected = company.id == selectedCompanyId;
            final count = users
                .where((user) => user.companyId == company.id)
                .length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelectCompany(company.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AdminTheme.blue.withValues(alpha: 0.18)
                        : const Color(0x33071126),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AdminTheme.cyan : AdminTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: selected
                            ? AdminTheme.blue
                            : AdminTheme.blue.withValues(alpha: 0.18),
                        child: const Icon(
                          Icons.business_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '$count usuário(s) • ${company.planSlug}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AdminTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CompanyUsersDetail extends StatelessWidget {
  const _CompanyUsersDetail({
    required this.company,
    required this.users,
    required this.onEditCompany,
    required this.onCreateUser,
    required this.onEditUser,
    required this.onToggleActive,
  });

  final AdminCompany company;
  final List<AdminUser> users;
  final VoidCallback onEditCompany;
  final VoidCallback onCreateUser;
  final ValueChanged<AdminUser> onEditUser;
  final void Function(AdminUser user, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${users.length} usuário(s) vinculados',
                        style: const TextStyle(color: AdminTheme.muted),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onCreateUser,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Novo usuário'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onEditCompany,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Editar empresa'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: _CompanyInfoGrid(company: company, money: money),
          ),
          UserTable(
            users: users,
            onEdit: onEditUser,
            onToggleActive: onToggleActive,
          ),
        ],
      ),
    );
  }
}

class _CompanyInfoGrid extends StatelessWidget {
  const _CompanyInfoGrid({required this.company, required this.money});

  final AdminCompany company;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final dueAt = company.planDueAt;
    final date = DateFormat('dd/MM/yyyy');
    final items = [
      ('Documento', company.document.isEmpty ? '-' : company.document),
      (
        'E-mail de cobrança',
        company.billingEmail.isEmpty ? '-' : company.billingEmail,
      ),
      ('Plano', company.planSlug),
      ('Status', company.status),
      ('Vencimento', dueAt == null ? '-' : date.format(dueAt)),
      ('Usuários', '${company.usersCount} ativo(s)'),
      ('Projetos', '${company.projectsCount} projeto(s)'),
      ('Pendente', money.format(company.pendingAmount)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850 ? 4 : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0x33071126),
                  border: Border.all(color: AdminTheme.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
