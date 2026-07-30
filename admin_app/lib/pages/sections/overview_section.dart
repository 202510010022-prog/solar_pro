import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/admin_theme.dart';
import '../../models/admin_company.dart';
import '../../models/admin_feedback.dart';
import '../../models/admin_message.dart';
import '../../models/admin_payment.dart';
import '../../widgets/stat_card.dart';

class SummaryGrid extends StatelessWidget {
  const SummaryGrid({super.key, required this.companies});

  final List<AdminCompany> companies;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final active = companies.where((item) => item.active).length;
    final users = companies.fold<int>(0, (sum, item) => sum + item.usersCount);
    final projects = companies.fold<int>(
      0,
      (sum, item) => sum + item.projectsCount,
    );
    final pending = companies.fold<double>(
      0,
      (sum, item) => sum + item.pendingAmount,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1050 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 2.6,
          children: [
            StatCard(
              icon: Icons.business_rounded,
              label: 'Empresas ativas',
              value: '$active',
              color: AdminTheme.blue,
            ),
            StatCard(
              icon: Icons.groups_rounded,
              label: 'Usuários ativos',
              value: '$users',
              color: AdminTheme.green,
            ),
            StatCard(
              icon: Icons.folder_copy_rounded,
              label: 'Projetos',
              value: '$projects',
              color: AdminTheme.purple,
            ),
            StatCard(
              icon: Icons.pix_rounded,
              label: 'Pendente',
              value: money.format(pending),
              color: AdminTheme.orange,
            ),
          ],
        );
      },
    );
  }
}

class OperationalSummary extends StatelessWidget {
  const OperationalSummary({
    super.key,
    required this.payments,
    required this.feedbacks,
    required this.messages,
  });

  final List<AdminPayment> payments;
  final List<AdminFeedback> feedbacks;
  final List<AdminMessage> messages;

  @override
  Widget build(BuildContext context) {
    final openPayments = payments
        .where(
          (payment) =>
              payment.status == 'pending' || payment.status == 'overdue',
        )
        .length;
    final openFeedbacks = feedbacks
        .where(
          (feedback) =>
              feedback.status == 'open' || feedback.status == 'reviewing',
        )
        .length;
    final resolvedFeedbacks = feedbacks
        .where((feedback) => feedback.status == 'resolved')
        .length;
    final unreadMessages = messages
        .where((message) => message.status == 'unread')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1100 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: constraints.maxWidth > 900 ? 3.2 : 5,
          children: [
            StatCard(
              icon: Icons.pix_rounded,
              label: 'Cobranças abertas',
              value: '$openPayments',
              color: AdminTheme.orange,
            ),
            StatCard(
              icon: Icons.support_agent_rounded,
              label: 'Chamados em aberto',
              value: '$openFeedbacks',
              color: AdminTheme.cyan,
            ),
            StatCard(
              icon: Icons.task_alt_rounded,
              label: 'Chamados resolvidos',
              value: '$resolvedFeedbacks',
              color: AdminTheme.green,
            ),
            StatCard(
              icon: Icons.campaign_rounded,
              label: 'Mensagens não lidas',
              value: '$unreadMessages',
              color: AdminTheme.purple,
            ),
          ],
        );
      },
    );
  }
}
