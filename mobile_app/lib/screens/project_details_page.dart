import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/project.dart';
import '../models/project_payment.dart';
import '../models/project_status.dart';
import '../theme/app_theme.dart';
import '../widgets/monthly_energy_bars.dart';
import '../widgets/neon_card.dart';
import '../widgets/payment_status_badge.dart';

class ProjectDetailsPage extends StatelessWidget {
  const ProjectDetailsPage({
    super.key,
    required this.project,
    this.payments = const [],
    this.canUseFinancial = false,
  });

  final Project project;
  final List<ProjectPayment> payments;
  final bool canUseFinancial;

  static const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do projeto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            project.clientName.isEmpty
                ? 'Cliente sem nome'
                : project.clientName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '${ProjectStatus.labelFor(project.status)} • ${project.projectDate}',
            style: const TextStyle(color: AppTheme.muted),
          ),
          if (canUseFinancial) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: PaymentStatusBadge(project: project, payments: payments),
            ),
          ],
          if (ProjectStatus.rejected.matches(project.status) &&
              project.rejectionReason.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _RejectionReasonCard(reason: project.rejectionReason),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                  title: 'Potência',
                  value: '${project.systemPower.toStringAsFixed(2)} kWp'),
              _Metric(title: 'Módulos', value: '${project.moduleCount}'),
              _Metric(
                  title: 'Produção anual',
                  value: '${project.annualGeneration.toStringAsFixed(0)} kWh'),
              _Metric(
                  title: 'Payback',
                  value: '${project.paybackYears.toStringAsFixed(2)} anos'),
            ],
          ),
          const SizedBox(height: 14),
          _ProjectSellerCard(project: project),
          const SizedBox(height: 14),
          _ProjectAddressCard(project: project),
          const SizedBox(height: 14),
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumo financeiro',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                _row('Valor do projeto', money.format(project.projectValue)),
                _row('Mão de obra', money.format(project.laborCost)),
                _row('Módulos',
                    '${project.moduleCount} x ${money.format(project.moduleUnitCost)}'),
                _row('Inversor', money.format(project.inverterCost)),
                _row('Suportes', money.format(project.supportCost)),
                ...project.extraMaterials.map(
                  (item) => _row(item.name, money.format(item.value)),
                ),
                _divider(),
                _row('Economia mensal estimada',
                    money.format(project.monthlySavings)),
                _row('Geração média mensal',
                    '${project.monthlyGeneration.toStringAsFixed(0)} kWh'),
                _row('Consumo anual',
                    '${project.annualConsumption.toStringAsFixed(0)} kWh'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Geração x consumo',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _LegendDot(label: 'Consumo', color: AppTheme.orange),
                    _LegendDot(label: 'Geração', color: AppTheme.primaryBlue),
                    _LegendDot(label: 'Saldo positivo', color: AppTheme.green),
                    _LegendDot(
                        label: 'Saldo negativo', color: Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    final itemWidth = (constraints.maxWidth - spacing) / 2;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: List.generate(12, (index) {
                        final consumption =
                            _at(project.monthlyConsumptions, index);
                        final generation =
                            _at(project.monthlyGenerations, index);
                        final balance = _at(project.monthlyBalances, index);
                        return SizedBox(
                          width: itemWidth,
                          child: _MonthComparison(
                            month: months[index],
                            consumption: consumption,
                            generation: generation,
                            balance: balance,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.muted)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child:
                    Text(label, style: const TextStyle(color: AppTheme.muted)),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 1,
        color: AppTheme.border,
      ),
    );
  }

  double _at(List<double> values, int index) =>
      index < values.length ? values[index] : 0;
}

class _ProjectSellerCard extends StatelessWidget {
  const _ProjectSellerCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final sellerName = project.sellerName?.trim();
    final hasSeller = sellerName != null && sellerName.isNotEmpty;

    return NeonCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.10),
            child: const Icon(
              Icons.badge_rounded,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vendedor responsável',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  hasSeller ? sellerName : 'Vendedor não atribuído',
                  style: TextStyle(
                    color: hasSeller ? AppTheme.text : AppTheme.muted,
                    fontWeight: hasSeller ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectAddressCard extends StatelessWidget {
  const _ProjectAddressCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final address = project.address;
    final addressLine = address.addressLine.trim();
    final complement = address.addressComplement.trim();
    final hasAddress = addressLine.isNotEmpty || complement.isNotEmpty;

    return NeonCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.green.withValues(alpha: 0.12),
            child: const Icon(Icons.location_on_rounded, color: AppTheme.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Endereço da instalação',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  hasAddress ? addressLine : 'Endereço não informado',
                  style: TextStyle(
                    color: hasAddress ? AppTheme.text : AppTheme.muted,
                    fontWeight: hasAddress ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (complement.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    complement,
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectionReasonCard extends StatelessWidget {
  const _RejectionReasonCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.purple.withValues(alpha: 0.12),
            child: const Icon(Icons.cancel_rounded, color: AppTheme.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Motivo da não aprovação',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  reason.trim(),
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthComparison extends StatelessWidget {
  const _MonthComparison({
    required this.month,
    required this.consumption,
    required this.generation,
    required this.balance,
  });

  final String month;
  final double consumption;
  final double generation;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return MonthlyEnergyBars(
      month: month,
      consumption: consumption,
      generation: generation,
      balance: balance,
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width > 720 ? 220 : (width - 44) / 2,
      child: NeonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 6),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
      ],
    );
  }
}
