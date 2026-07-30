import 'package:flutter/material.dart';

import '../app/admin_theme.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, required this.active});

  final String status;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = !active
        ? AdminTheme.muted
        : switch (status) {
            'active' => AdminTheme.green,
            'trial' => AdminTheme.blue,
            'past_due' => AdminTheme.orange,
            'blocked' => Colors.redAccent,
            _ => AdminTheme.purple,
          };
    final label = !active
        ? 'inativa'
        : switch (status) {
            'active' => 'ativa',
            'trial' => 'teste',
            'past_due' => 'atrasada',
            'canceled' => 'cancelada',
            'blocked' => 'bloqueada',
            _ => status,
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class PaymentStatusPill extends StatelessWidget {
  const PaymentStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'paid' => AdminTheme.green,
      'overdue' => Colors.redAccent,
      'canceled' => AdminTheme.muted,
      _ => AdminTheme.orange,
    };
    final label = switch (status) {
      'paid' => 'paga',
      'overdue' => 'atrasada',
      'canceled' => 'cancelada',
      _ => 'pendente',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class MessageTypePill extends StatelessWidget {
  const MessageTypePill({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'billing' => AdminTheme.orange,
      'warning' => Colors.redAccent,
      'success' => AdminTheme.green,
      _ => AdminTheme.cyan,
    };
    final label = switch (type) {
      'billing' => 'Cobrança',
      'warning' => 'Atenção',
      'success' => 'Confirmação',
      _ => 'Informação',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}
