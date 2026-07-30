import 'package:flutter/material.dart';

import '../app/admin_section.dart';
import '../app/admin_theme.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.section,
    required this.onSelect,
  });

  final AdminSection section;
  final ValueChanged<AdminSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xAA020817),
        border: Border(right: BorderSide(color: AdminTheme.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: AdminTheme.blue,
                  child: Icon(Icons.solar_power_rounded),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SOLAR PRO',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'ADMIN',
                      style: TextStyle(
                        color: AdminTheme.cyan,
                        letterSpacing: 2,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 34),
            _SideItem(
              icon: Icons.business_rounded,
              title: 'Visão geral',
              active: section == AdminSection.overview,
              onTap: () => onSelect(AdminSection.overview),
            ),
            _SideItem(
              icon: Icons.apartment_rounded,
              title: 'Empresas',
              active: section == AdminSection.companies,
              onTap: () => onSelect(AdminSection.companies),
            ),
            _SideItem(
              icon: Icons.payments_outlined,
              title: 'Cobranças',
              active: section == AdminSection.payments,
              onTap: () => onSelect(AdminSection.payments),
            ),
            _SideItem(
              icon: Icons.groups_rounded,
              title: 'Empresas e usuários',
              active: section == AdminSection.users,
              onTap: () => onSelect(AdminSection.users),
            ),
            _SideItem(
              icon: Icons.feedback_outlined,
              title: 'Feedbacks',
              active: section == AdminSection.feedbacks,
              onTap: () => onSelect(AdminSection.feedbacks),
            ),
            _SideItem(
              icon: Icons.campaign_outlined,
              title: 'Mensagens',
              active: section == AdminSection.messages,
              onTap: () => onSelect(AdminSection.messages),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AdminTheme.green.withValues(alpha: 0.08),
                border: Border.all(
                  color: AdminTheme.green.withValues(alpha: 0.35),
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Painel separado do app cliente.\nOperação comercial com mais controle.',
                style: TextStyle(color: AdminTheme.muted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: active
                ? AdminTheme.blue.withValues(alpha: 0.22)
                : Colors.transparent,
            border: Border.all(
              color: active ? AdminTheme.cyan : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: active ? AdminTheme.cyan : AdminTheme.muted),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: active ? AdminTheme.text : AdminTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
