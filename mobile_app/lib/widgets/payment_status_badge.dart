import 'dart:math';

import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/project_payment.dart';
import '../theme/app_theme.dart';

enum ProjectPaymentBadgeState {
  paid('Pago integralmente', AppTheme.green, Icons.check_circle_rounded),
  partial('Pagamento parcial', AppTheme.orange, Icons.paid_rounded),
  pending('Pagamento pendente', AppTheme.muted, Icons.schedule_rounded),
  overdue('Vencido', Colors.redAccent, Icons.warning_rounded);

  const ProjectPaymentBadgeState(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

class ProjectPaymentSnapshot {
  const ProjectPaymentSnapshot({
    required this.netValue,
    required this.totalPaid,
    required this.remaining,
    required this.state,
  });

  final double netValue;
  final double totalPaid;
  final double remaining;
  final ProjectPaymentBadgeState state;

  factory ProjectPaymentSnapshot.fromProject(
    Project project,
    List<ProjectPayment> payments, {
    DateTime? now,
  }) {
    final paid = payments.where((payment) => payment.isPaid).fold<double>(
          0,
          (sum, payment) => sum + payment.amount,
        );
    final net = max(project.projectValue - project.discount, 0.0);
    final totalPaid = project.downPayment + paid;
    final remaining = max(net - totalPaid, 0.0);
    final today = now ?? DateTime.now();
    final isOverdue = project.firstDueDate != null &&
        today.isAfter(project.firstDueDate!) &&
        remaining > 0;

    final state =
        switch ((remaining <= 0 && net > 0, totalPaid > 0, isOverdue)) {
      (true, _, _) => ProjectPaymentBadgeState.paid,
      (_, _, true) => ProjectPaymentBadgeState.overdue,
      (_, true, _) => ProjectPaymentBadgeState.partial,
      _ => ProjectPaymentBadgeState.pending,
    };

    return ProjectPaymentSnapshot(
      netValue: net,
      totalPaid: totalPaid,
      remaining: remaining,
      state: state,
    );
  }
}

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({
    super.key,
    required this.project,
    required this.payments,
    this.compact = false,
  });

  final Project project;
  final List<ProjectPayment> payments;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final snapshot = ProjectPaymentSnapshot.fromProject(project, payments);
    final state = snapshot.state;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: state.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: state.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(state.icon, color: state.color, size: compact ? 15 : 17),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              state.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: state.color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
