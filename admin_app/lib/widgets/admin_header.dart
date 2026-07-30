import 'package:flutter/material.dart';

import '../app/admin_section.dart';
import '../app/admin_theme.dart';

class AdminHeader extends StatelessWidget {
  const AdminHeader({
    super.key,
    required this.section,
    required this.onLogout,
    required this.onRefresh,
    required this.onCreate,
    required this.onCreatePayment,
    required this.onCreateMessage,
    required this.onCreateUser,
  });

  final AdminSection section;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final VoidCallback onCreatePayment;
  final VoidCallback onCreateMessage;
  final VoidCallback onCreateUser;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                section.subtitle,
                style: const TextStyle(color: AdminTheme.muted),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Atualizar',
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_business_rounded),
          label: const Text('Nova empresa'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onCreatePayment,
          icon: const Icon(Icons.pix_rounded),
          label: const Text('Cobrança Pix'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onCreateMessage,
          icon: const Icon(Icons.campaign_rounded),
          label: const Text('Comunicado'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onCreateUser,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Usuário'),
        ),
        const SizedBox(width: 10),
        IconButton.outlined(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Sair',
        ),
      ],
    );
  }
}
