import 'package:flutter/material.dart';

import '../../models/admin_company.dart';
import '../../models/admin_plan.dart';
import '../../widgets/admin_card.dart';
import '../../widgets/tables/company_table.dart';

class CompaniesSection extends StatelessWidget {
  const CompaniesSection({
    super.key,
    required this.companies,
    required this.plans,
    required this.onQueryChanged,
    required this.onEdit,
  });

  final List<AdminCompany> companies;
  final List<AdminPlan> plans;
  final ValueChanged<String> onQueryChanged;
  final void Function(AdminCompany company, List<AdminPlan> plans) onEdit;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Empresas cadastradas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    onChanged: onQueryChanged,
                    decoration: const InputDecoration(
                      hintText: 'Buscar empresa...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ),
          CompanyTable(companies: companies, plans: plans, onEdit: onEdit),
        ],
      ),
    );
  }
}
