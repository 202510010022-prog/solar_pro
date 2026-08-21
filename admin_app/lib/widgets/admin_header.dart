import 'package:flutter/material.dart';

import '../app/admin_section.dart';
import '../app/admin_theme.dart';

class AdminHeader extends StatelessWidget {
  const AdminHeader({
    super.key,
    required this.section,
    this.onOpenMenu,
    required this.onLogout,
    required this.onRefresh,
    required this.onCreate,
    required this.onCreatePayment,
    required this.onCreateMessage,
    required this.onCreateUser,
  });

  final AdminSection section;
  final VoidCallback? onOpenMenu;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final VoidCallback onCreatePayment;
  final VoidCallback onCreateMessage;
  final VoidCallback onCreateUser;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final title = _HeaderTitle(section: section, compact: compact);
        final actions = [
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('Nova empresa'),
          ),
          OutlinedButton.icon(
            onPressed: onCreatePayment,
            icon: const Icon(Icons.pix_rounded),
            label: const Text('Cobrança Pix'),
          ),
          OutlinedButton.icon(
            onPressed: onCreateMessage,
            icon: const Icon(Icons.campaign_rounded),
            label: const Text('Comunicado'),
          ),
          OutlinedButton.icon(
            onPressed: onCreateUser,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Usuário'),
          ),
        ];

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onOpenMenu != null) ...[
                    IconButton.filledTonal(
                      onPressed: onOpenMenu,
                      icon: const Icon(Icons.menu_rounded),
                      tooltip: 'Menu',
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: title),
                  IconButton.filledTonal(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Atualizar',
                  ),
                  const SizedBox(width: 6),
                  IconButton.outlined(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: 'Sair',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final action in actions) ...[
                      action,
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            if (onOpenMenu != null) ...[
              IconButton.filledTonal(
                onPressed: onOpenMenu,
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menu',
              ),
              const SizedBox(width: 10),
            ],
            Expanded(child: title),
            IconButton.filledTonal(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Atualizar',
            ),
            const SizedBox(width: 10),
            for (final action in actions) ...[
              action,
              const SizedBox(width: 10),
            ],
            IconButton.outlined(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sair',
            ),
          ],
        );
      },
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.section, required this.compact});

  final AdminSection section;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 22 : 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          section.subtitle,
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AdminTheme.muted),
        ),
      ],
    );
  }
}
