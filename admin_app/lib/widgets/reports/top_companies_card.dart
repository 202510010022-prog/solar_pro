import 'package:flutter/material.dart';

import '../../app/admin_theme.dart';
import '../../models/admin_company.dart';

class TopCompaniesCard extends StatelessWidget {
  const TopCompaniesCard({super.key, required this.companies});

  final List<AdminCompany> companies;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x66071126),
        border: Border.all(color: AdminTheme.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: AdminTheme.cyan),
              SizedBox(width: 8),
              Text(
                'Ranking de uso',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (companies.isEmpty)
            const Text(
              'Sem empresas cadastradas.',
              style: TextStyle(color: AdminTheme.muted),
            )
          else
            ...companies.asMap().entries.map((entry) {
              final company = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AdminTheme.blue.withValues(alpha: 0.18),
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${company.projectsCount} projetos • ${company.usersCount} usuários',
                            style: const TextStyle(
                              color: AdminTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
