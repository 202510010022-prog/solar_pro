import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/app_profile.dart';
import '../models/app_subscription.dart';
import '../models/project.dart';
import '../models/project_payment.dart';
import '../models/project_status.dart';
import '../services/proposal_service.dart';
import '../services/report_file_saver.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';
import '../widgets/monthly_energy_bars.dart';
import '../widgets/neon_card.dart';
import '../widgets/payment_status_badge.dart';

class ProjectDetailsPage extends StatefulWidget {
  const ProjectDetailsPage({
    super.key,
    required this.project,
    required this.repository,
    this.profile,
    this.subscription,
    this.payments = const [],
    this.canUseFinancial = false,
  });

  final Project project;
  final SolarProRepository repository;
  final AppProfile? profile;
  final AppSubscription? subscription;
  final List<ProjectPayment> payments;
  final bool canUseFinancial;

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  SavedReport? proposal;
  bool generatingProposal = false;

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
    final project = widget.project;
    final canExportProposal = _canExportProposal;
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
          if (widget.canUseFinancial) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: PaymentStatusBadge(
                project: project,
                payments: widget.payments,
              ),
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
          const SizedBox(height: 14),
          _ProposalCard(
            canExport: canExportProposal,
            generating: generatingProposal,
            generatedFileName: proposal?.fileName,
            onGenerate: _generateProposal,
            onShare: proposal == null
                ? null
                : () => ProposalService(widget.repository).shareProposal(
                      proposal!,
                    ),
            onDownload: proposal == null
                ? null
                : () => ProposalService(widget.repository).downloadProposal(
                      proposal!,
                    ),
            onPrint: proposal == null
                ? null
                : () => ProposalService(widget.repository).printProposal(
                      proposal!,
                    ),
          ),
        ],
      ),
    );
  }

  bool get _canExportProposal {
    final profile = widget.profile;
    if (profile?.canManageAll == true) return true;
    final sellerId = widget.project.sellerId;
    return profile != null && sellerId != null && sellerId == profile.id;
  }

  Future<void> _generateProposal() async {
    setState(() => generatingProposal = true);
    try {
      final service = ProposalService(widget.repository);
      final generated = await service.generateProjectProposal(
        project: widget.project,
        subscription: widget.subscription,
      );
      if (!mounted) return;
      setState(() => proposal = generated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${generated.fileName} gerado.'),
          action: SnackBarAction(
            label: kIsWeb ? 'Baixar' : 'Compartilhar',
            onPressed: kIsWeb
                ? () => service.downloadProposal(generated)
                : () => service.shareProposal(generated),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyNetworkError(error))),
      );
    } finally {
      if (mounted) setState(() => generatingProposal = false);
    }
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

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.canExport,
    required this.generating,
    required this.generatedFileName,
    required this.onGenerate,
    required this.onShare,
    required this.onDownload,
    required this.onPrint,
  });

  final bool canExport;
  final bool generating;
  final String? generatedFileName;
  final VoidCallback onGenerate;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;
  final VoidCallback? onPrint;

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
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.10),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proposta comercial',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Gere um PDF individual deste orçamento para enviar ao cliente.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!canExport) ...[
            const SizedBox(height: 14),
            const Text(
              'Disponível apenas para o vendedor responsável ou gestores.',
              style: TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: generating ? null : onGenerate,
                icon: generating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined),
                label: Text(
                  generating
                      ? 'Gerando proposta...'
                      : 'Exportar proposta em PDF',
                ),
              ),
            ),
            if (generatedFileName != null) ...[
              const SizedBox(height: 12),
              Text(
                generatedFileName!,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Compartilhar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Baixar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onPrint,
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Imprimir'),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
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
