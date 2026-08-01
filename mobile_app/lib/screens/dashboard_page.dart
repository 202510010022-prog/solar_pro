import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_profile.dart';
import '../models/manual_payment.dart';
import '../models/project.dart';
import '../models/project_payment.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';
import '../widgets/project_distribution_vertical_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.repository,
    required this.profile,
    required this.onOpenTab,
  });

  final SolarProRepository repository;
  final AppProfile? profile;
  final ValueChanged<int> onOpenTab;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_DashboardData> future;
  final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    future = _loadDashboard();
  }

  Future<_DashboardData> _loadDashboard({bool cacheFirst = true}) async {
    try {
      await widget.repository.syncOverdueManualPayments();
    } catch (_) {
      // Offline-first: alertas de cobranca continuam com o ultimo estado remoto.
    }
    final results = await Future.wait([
      widget.repository.loadProjects(cacheFirst: cacheFirst),
      widget.repository.loadProjectPayments(cacheFirst: cacheFirst),
      widget.repository.loadOpenManualPayments(),
    ]);
    return _DashboardData(
      projects: results[0] as List<Project>,
      projectPayments: results[1] as List<ProjectPayment>,
      openPayments: results[2] as List<ManualPayment>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _DashboardData();
        final projects = data.projects;
        final projectPayments = data.projectPayments;
        final openPayments = data.openPayments;
        final negotiating =
            projects.where((item) => item.status == 'Em negociação').length;
        final closed =
            projects.where((item) => item.status == 'Fechado').length;
        final completed =
            projects.where((item) => item.status == 'Concluído').length;
        final rejected =
            projects.where((item) => item.status == 'Não aprovado').length;
        final active = negotiating + closed;
        final converted = closed + completed;
        final today = DateTime.now();
        final todayProjects = projects
            .where((item) => _sameDay(_parseDate(item.projectDate), today))
            .length;
        final currentMonthProjects = projects.where((item) {
          final date = _parseDate(item.projectDate);
          return date != null &&
              date.year == today.year &&
              date.month == today.month;
        }).toList();
        final monthlyClosed = currentMonthProjects
            .where((item) =>
                item.status == 'Fechado' || item.status == 'Concluído')
            .fold<double>(0, (sum, item) => sum + item.projectValue);
        final revenuePipeline = projects
            .where((item) => item.status != 'Não aprovado')
            .fold<double>(0, (sum, item) => sum + item.projectValue);
        final revenueClosed = projects
            .where((item) =>
                item.status == 'Fechado' || item.status == 'Concluído')
            .fold<double>(0, (sum, item) => sum + item.projectValue);
        final soldPower = projects
            .where((item) =>
                item.status == 'Fechado' || item.status == 'Concluído')
            .fold<double>(0, (sum, item) => sum + item.systemPower);
        final conversion =
            projects.isEmpty ? 0.0 : converted / projects.length * 100;
        final followUpProjects = _followUpProjects(projects);
        final attentionProjects = _attentionProjects(projects);
        final recentProjects = projects.take(4).toList();
        final paymentsByProject = _paymentsByProject(projectPayments);
        final receivedThisMonth = projectPayments
            .where((payment) =>
                payment.status == 'paid' && _sameMonth(payment.paidAt, today))
            .fold<double>(0, (sum, payment) => sum + payment.amount);
        final pendingAmount = projects.fold<double>(0, (sum, project) {
          final remaining = _projectRemaining(
            project,
            paymentsByProject[project.id] ?? const [],
          );
          final overdue = project.firstDueDate != null &&
              today.isAfter(project.firstDueDate!) &&
              remaining > 0;
          return overdue ? sum : sum + remaining;
        });
        final overdueAmount = projects.fold<double>(0, (sum, project) {
          final remaining = _projectRemaining(
            project,
            paymentsByProject[project.id] ?? const [],
          );
          final overdue = project.firstDueDate != null &&
              today.isAfter(project.firstDueDate!) &&
              remaining > 0;
          return overdue ? sum + remaining : sum;
        });

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => future = _loadDashboard(cacheFirst: false));
            await future;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Olá, ${_firstName(widget.profile?.name)}',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.text),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(DateTime.now()),
                style: const TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 18),
              if (openPayments.isNotEmpty) ...[
                _BillingAlertCard(
                  payments: openPayments,
                  money: money,
                  onOpenBilling: () => widget.onOpenTab(5),
                ),
                const SizedBox(height: 14),
              ],
              if (followUpProjects.isNotEmpty) ...[
                _FollowUpCard(
                  projects: followUpProjects,
                  onOpenProjects: () => widget.onOpenTab(2),
                  onSendFollowUp: _sendFollowUp,
                ),
                const SizedBox(height: 14),
              ],
              _QuickActions(onOpenTab: widget.onOpenTab),
              const SizedBox(height: 16),
              const Text('Resumo do dia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              _ResponsiveWrap(
                minItemWidth: 210,
                spacing: 12,
                children: [
                  (width) => _Kpi(
                        width: width,
                        title: 'Criados hoje',
                        value: '$todayProjects',
                        icon: Icons.today_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                  (width) => _Kpi(
                        width: width,
                        title: 'Em negociação',
                        value: '$negotiating',
                        icon: Icons.forum_rounded,
                        color: AppTheme.orange,
                      ),
                  (width) => _Kpi(
                        width: width,
                        title: 'Convertidos no mês',
                        value: money.format(monthlyClosed),
                        icon: Icons.check_circle_rounded,
                        color: AppTheme.green,
                      ),
                  (width) => _Kpi(
                        width: width,
                        title: 'Projetos ativos',
                        value: '$active',
                        icon: Icons.bolt_rounded,
                        color: AppTheme.neonBlue,
                      ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Indicadores principais',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _WideKpi(
                    title: 'Receita prevista',
                    value: money.format(revenuePipeline),
                    subtitle: 'Pipeline válido',
                    icon: Icons.trending_up_rounded,
                    color: AppTheme.green,
                  ),
                  _WideKpi(
                    title: 'Receita fechada',
                    value: money.format(revenueClosed),
                    subtitle: 'Aprovados + concluídos',
                    icon: Icons.savings_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  _WideKpi(
                    title: 'Taxa de conversão',
                    value: '${conversion.toStringAsFixed(1)}%',
                    subtitle: 'Projetos convertidos',
                    icon: Icons.track_changes_rounded,
                    color: AppTheme.orange,
                  ),
                  _WideKpi(
                    title: 'Potência vendida',
                    value: '${soldPower.toStringAsFixed(2)} kWp',
                    subtitle: 'Aprovados + concluídos',
                    icon: Icons.solar_power_rounded,
                    color: AppTheme.neonBlue,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FinancialSummaryCard(
                receivedThisMonth: receivedThisMonth,
                pending: pendingAmount,
                overdue: overdueAmount,
                money: money,
                onOpenBilling: () => widget.onOpenTab(4),
              ),
              const SizedBox(height: 14),
              _StatusDistribution(
                negotiating: negotiating,
                closed: closed,
                completed: completed,
                rejected: rejected,
              ),
              const SizedBox(height: 14),
              _AttentionCard(
                projects: attentionProjects,
                money: money,
                onOpenProjects: () => widget.onOpenTab(2),
              ),
              const SizedBox(height: 10),
              _RecentActivityCard(projects: recentProjects),
            ],
          ),
        );
      },
    );
  }

  List<Project> _attentionProjects(List<Project> projects) {
    final now = DateTime.now();
    final items = [...projects];
    items.sort((a, b) {
      final aScore = _attentionScore(a, now);
      final bScore = _attentionScore(b, now);
      return bScore.compareTo(aScore);
    });
    return items
        .where((item) => _attentionScore(item, now) > 0)
        .take(4)
        .toList();
  }

  List<Project> _followUpProjects(List<Project> projects) {
    final now = DateTime.now();
    final items = projects.where((project) {
      if (project.status != 'Em negociação') return false;
      final reference = project.updatedAt ?? _parseDate(project.projectDate);
      if (reference == null) return false;
      return now.difference(reference).inDays >= 3;
    }).toList();
    items.sort((a, b) {
      final aReference = a.updatedAt ?? _parseDate(a.projectDate) ?? now;
      final bReference = b.updatedAt ?? _parseDate(b.projectDate) ?? now;
      return aReference.compareTo(bReference);
    });
    return items.take(4).toList();
  }

  Future<void> _sendFollowUp(Project project) async {
    try {
      await widget.repository.createFollowUpMessage(project);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow-up criado em Mensagens.')),
      );
      setState(() => future = _loadDashboard(cacheFirst: false));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível criar o follow-up agora.'),
        ),
      );
    }
  }

  int _attentionScore(Project project, DateTime now) {
    var score = 0;
    final date = _parseDate(project.projectDate);
    final age = date == null ? 0 : now.difference(date).inDays;
    if (project.status == 'Em negociação' && age >= 7) score += 3;
    if (project.projectValue <= 0) score += 2;
    if (project.paybackYears >= 6) score += 1;
    if (project.systemPower <= 0) score += 1;
    return score;
  }

  DateTime? _parseDate(String value) => DateTime.tryParse(value);

  bool _sameDay(DateTime? a, DateTime b) {
    return a != null &&
        a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  bool _sameMonth(DateTime? a, DateTime b) {
    return a != null && a.year == b.year && a.month == b.month;
  }

  Map<int?, List<ProjectPayment>> _paymentsByProject(
    List<ProjectPayment> payments,
  ) {
    final map = <int?, List<ProjectPayment>>{};
    for (final payment in payments) {
      map.putIfAbsent(payment.projectId, () => []).add(payment);
    }
    return map;
  }

  double _projectRemaining(Project project, List<ProjectPayment> payments) {
    final net = max(project.projectValue - project.discount, 0.0);
    final paid = payments.where((payment) => payment.isPaid).fold<double>(
          project.downPayment,
          (sum, payment) => sum + payment.amount,
        );
    return max(net - paid, 0.0);
  }

  String _firstName(String? name) {
    final value = name?.trim();
    if (value == null || value.isEmpty) return 'bem-vindo';
    return value.split(RegExp(r'\s+')).first;
  }
}

typedef _ResponsiveCardBuilder = Widget Function(double width);

class _ResponsiveWrap extends StatelessWidget {
  const _ResponsiveWrap({
    required this.children,
    this.minItemWidth = 220,
    this.spacing = 12,
  });

  final List<_ResponsiveCardBuilder> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final columns = max(1, (available / minItemWidth).floor());
        final itemWidth = (available - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) child(itemWidth),
          ],
        );
      },
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: NeonCard(
        child: Row(
          children: [
            CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideKpi extends StatelessWidget {
  const _WideKpi({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width > 920 ? (width - 68) / 2 : double.infinity,
      child: NeonCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.muted)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                  Text(subtitle,
                      style:
                          const TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FinancialSummaryCard extends StatelessWidget {
  const FinancialSummaryCard({
    super.key,
    required this.receivedThisMonth,
    required this.pending,
    required this.overdue,
    required this.money,
    required this.onOpenBilling,
  });

  final double receivedThisMonth;
  final double pending;
  final double overdue;
  final NumberFormat money;
  final VoidCallback onOpenBilling;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Financeiro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenBilling,
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text('Ver financeiro'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760
                  ? 3
                  : constraints.maxWidth >= 500
                      ? 2
                      : 1;
              final spacing = columns == 1 ? 0.0 : 10.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: 10,
                children: [
                  _FinancialMetric(
                    width: itemWidth,
                    title: 'Recebido neste mês',
                    value: money.format(receivedThisMonth),
                    subtitle: 'Pago este mês',
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.green,
                  ),
                  _FinancialMetric(
                    width: itemWidth,
                    title: 'Pendente',
                    value: money.format(pending),
                    subtitle: 'Em aberto',
                    icon: Icons.schedule_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  _FinancialMetric(
                    width: itemWidth,
                    title: 'Atrasado',
                    value: money.format(overdue),
                    subtitle: 'Vencido',
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.orange,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FinancialMetric extends StatelessWidget {
  const _FinancialMetric({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.muted)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({
    required this.projects,
    required this.onOpenProjects,
    required this.onSendFollowUp,
  });

  final List<Project> projects;
  final VoidCallback onOpenProjects;
  final ValueChanged<Project> onSendFollowUp;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.orange.withValues(alpha: 0.12),
                child: const Icon(Icons.notifications_active,
                    color: AppTheme.orange),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Follow-ups pendentes',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Propostas em negociação sem movimento há 3 dias ou mais.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onOpenProjects, child: const Text('Ver')),
            ],
          ),
          const SizedBox(height: 12),
          ...projects.map(
            (project) => _FollowUpTile(
              project: project,
              onSend: () => onSendFollowUp(project),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpTile extends StatelessWidget {
  const _FollowUpTile({required this.project, required this.onSend});

  final Project project;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final days = _daysWithoutMovement(project);
    final projectId = project.id == null ? '-' : '#${project.id}';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.schedule_send, color: AppTheme.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.clientName.isEmpty
                      ? 'Cliente sem nome'
                      : project.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '$projectId • sem movimento há $days dia(s)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  int _daysWithoutMovement(Project project) {
    final reference =
        project.updatedAt ?? DateTime.tryParse(project.projectDate);
    if (reference == null) return 0;
    return DateTime.now().difference(reference).inDays;
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 460 ? 2 : 1;
          final spacing = columns == 1 ? 0.0 : 10.0;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ações rápidas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Wrap(
                spacing: spacing,
                runSpacing: 10,
                children: [
                  _ActionButton(
                    width: itemWidth,
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Novo cliente',
                    onTap: () => onOpenTab(1),
                  ),
                  _ActionButton(
                    width: itemWidth,
                    icon: Icons.bolt_rounded,
                    label: 'Dimensionar',
                    onTap: () => onOpenTab(3),
                  ),
                  _ActionButton(
                    width: itemWidth,
                    icon: Icons.folder_open_rounded,
                    label: 'Ver projetos',
                    onTap: () => onOpenTab(2),
                  ),
                  _ActionButton(
                    width: itemWidth,
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Financeiro',
                    onTap: () => onOpenTab(4),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.width,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.projects,
    required this.money,
    required this.onOpenProjects,
  });

  final List<Project> projects;
  final NumberFormat money;
  final VoidCallback onOpenProjects;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Precisam de atenção',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              TextButton(
                  onPressed: onOpenProjects, child: const Text('Ver todos')),
            ],
          ),
          const SizedBox(height: 8),
          if (projects.isEmpty)
            const Text('Nenhum projeto crítico no momento.',
                style: TextStyle(color: AppTheme.muted))
          else
            ...projects.map(
              (project) => _ProjectMiniTile(
                project: project,
                subtitle: _attentionReason(project),
                trailing: money.format(project.projectValue),
                color: AppTheme.orange,
              ),
            ),
        ],
      ),
    );
  }

  String _attentionReason(Project project) {
    final date = DateTime.tryParse(project.projectDate);
    final age = date == null ? 0 : DateTime.now().difference(date).inDays;
    if (project.status == 'Em negociação' && age >= 7) {
      return 'Em negociação há $age dias';
    }
    if (project.projectValue <= 0) {
      return 'Valor do projeto pendente';
    }
    if (project.paybackYears >= 6) {
      return 'Payback acima do ideal';
    }
    if (project.systemPower <= 0) {
      return 'Dimensionamento incompleto';
    }
    return project.status;
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Últimas atividades',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (projects.isEmpty)
            const Text('Nenhuma atividade encontrada.',
                style: TextStyle(color: AppTheme.muted))
          else
            ...projects.map(
              (project) => _ProjectMiniTile(
                project: project,
                subtitle: 'Projeto #${project.id ?? '-'} • ${project.status}',
                trailing: project.projectDate,
                color: _statusColor(project.status),
              ),
            ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'Fechado' => AppTheme.green,
      'Concluído' => AppTheme.neonBlue,
      'Não aprovado' => AppTheme.purple,
      _ => AppTheme.orange,
    };
  }
}

class _ProjectMiniTile extends StatelessWidget {
  const _ProjectMiniTile({
    required this.project,
    required this.subtitle,
    required this.trailing,
    required this.color,
  });

  final Project project;
  final String subtitle;
  final String trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.bolt_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.clientName.isEmpty
                      ? 'Cliente sem nome'
                      : project.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            trailing,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BillingAlertCard extends StatelessWidget {
  const _BillingAlertCard({
    required this.payments,
    required this.money,
    required this.onOpenBilling,
  });

  final List<ManualPayment> payments;
  final NumberFormat money;
  final VoidCallback onOpenBilling;

  @override
  Widget build(BuildContext context) {
    final overdue =
        payments.where((payment) => payment.status == 'overdue').toList();
    final first = overdue.isNotEmpty ? overdue.first : payments.first;
    final color = overdue.isNotEmpty ? AppTheme.orange : AppTheme.primaryBlue;
    final title = overdue.isNotEmpty
        ? '${overdue.length} cobrança(s) atrasada(s)'
        : '${payments.length} cobrança(s) pendente(s)';
    final due = first.dueDate == null
        ? 'Sem vencimento'
        : DateFormat('dd/MM/yyyy').format(first.dueDate!);

    return NeonCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(
              overdue.isNotEmpty
                  ? Icons.warning_amber_rounded
                  : Icons.pix_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  '${money.format(first.amount)} • vence em $due',
                  style: const TextStyle(color: AppTheme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onOpenBilling,
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
}

class _StatusDistribution extends StatelessWidget {
  const _StatusDistribution({
    required this.negotiating,
    required this.closed,
    required this.completed,
    required this.rejected,
  });

  final int negotiating;
  final int closed;
  final int completed;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Distribuição dos projetos',
              style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ProjectDistributionVerticalChart(
            items: [
              ProjectDistributionBarItem(
                label: 'Em negociação',
                value: negotiating,
                color: AppTheme.orange,
              ),
              ProjectDistributionBarItem(
                label: 'Aprovados',
                value: closed,
                color: AppTheme.green,
              ),
              ProjectDistributionBarItem(
                label: 'Concluídos',
                value: completed,
                color: AppTheme.neonBlue,
              ),
              ProjectDistributionBarItem(
                label: 'Não aprovados',
                value: rejected,
                color: AppTheme.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    this.projects = const [],
    this.projectPayments = const [],
    this.openPayments = const [],
  });

  final List<Project> projects;
  final List<ProjectPayment> projectPayments;
  final List<ManualPayment> openPayments;
}
