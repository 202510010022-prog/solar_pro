import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/app_profile.dart';
import '../models/project.dart';
import '../models/project_payment.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';
import '../widgets/neon_card.dart';

const paymentTypes = [
  'Pix',
  'Boleto',
  'Cartão',
  'Transferência',
  'Dinheiro',
  'Financiamento',
  'Outro',
];

class FinancialPage extends StatefulWidget {
  const FinancialPage({
    super.key,
    required this.repository,
    required this.profile,
  });

  final SolarProRepository repository;
  final AppProfile? profile;

  @override
  State<FinancialPage> createState() => _FinancialPageState();
}

class _FinancialPageState extends State<FinancialPage> {
  late Future<_FinancialData> future;
  final search = TextEditingController();
  final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final date = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    future = _load();
    search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<_FinancialData> _load({bool cacheFirst = true}) async {
    final results = await Future.wait([
      widget.repository.loadProjects(cacheFirst: cacheFirst),
      widget.repository.loadProjectPayments(cacheFirst: cacheFirst),
    ]);
    return _FinancialData(
      projects: results[0] as List<Project>,
      payments: results[1] as List<ProjectPayment>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FinancialData>(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _FinancialData();
        final query = search.text.trim().toLowerCase();
        final paymentsByProject = data.paymentsByProject;
        final items = data.projects.where((project) {
          if (query.isEmpty) return true;
          return project.clientName.toLowerCase().contains(query) ||
              '${project.id}'.contains(query) ||
              project.status.toLowerCase().contains(query);
        }).toList();
        final summary = _FinancialTotals.from(data.projects, paymentsByProject);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => future = _load(cacheFirst: false));
            await future;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Financeiro',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Controle entradas, descontos, parcelas e pagamentos dos projetos.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 16),
              _SummaryCard(summary: summary, money: money),
              const SizedBox(height: 14),
              NeonCard(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    hintText: 'Buscar cliente ou projeto',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const NeonCard(child: LinearProgressIndicator())
              else if (items.isEmpty)
                const NeonCard(
                  child: Text(
                    'Nenhum projeto encontrado para controle financeiro.',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                )
              else
                ...items.map(
                  (project) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProjectFinancialCard(
                      project: project,
                      payments: paymentsByProject[project.id] ?? const [],
                      money: money,
                      date: date,
                      onEditPlan: () => _openPlanDialog(project),
                      onAddPayment: () => _openPaymentDialog(project),
                      onCancelPayment: _cancelPayment,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPlanDialog(Project project) async {
    final projectId = project.id;
    if (projectId == null) return;

    var paymentType = paymentTypes.contains(project.paymentType)
        ? project.paymentType
        : paymentTypes.first;
    DateTime? firstDueDate = project.firstDueDate;
    final downPayment =
        TextEditingController(text: project.downPayment.toStringAsFixed(2));
    final discount =
        TextEditingController(text: project.discount.toStringAsFixed(2));
    final installments =
        TextEditingController(text: '${project.installmentsCount}');
    final installmentValue = TextEditingController(
      text: project.installmentValue.toStringAsFixed(2),
    );
    final notes = TextEditingController(text: project.financialNotes);
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              setDialogState(() => saving = true);
              try {
                await widget.repository.updateProjectFinancialPlan(
                  projectId: projectId,
                  paymentType: paymentType,
                  downPayment: _number(downPayment.text),
                  discount: _number(discount.text),
                  installmentsCount: _int(installments.text),
                  installmentValue: _number(installmentValue.text),
                  firstDueDate: firstDueDate,
                  notes: notes.text,
                );
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                _reload();
                _message('Dados financeiros atualizados.');
              } catch (error) {
                if (!context.mounted) return;
                setDialogState(() => saving = false);
                _message(
                  friendlyNetworkError(
                    error,
                    fallback: 'Não foi possível salvar o financeiro.',
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Financeiro do projeto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: paymentType,
                      decoration:
                          const InputDecoration(labelText: 'Tipo de pagamento'),
                      items: paymentTypes
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(
                                () => paymentType = value ?? paymentType,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _moneyField('Entrada', downPayment)),
                        const SizedBox(width: 10),
                        Expanded(child: _moneyField('Desconto', discount)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _numberField('Parcelas', installments),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _moneyField('Valor parcela', installmentValue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: firstDueDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (selected != null) {
                                setDialogState(() => firstDueDate = selected);
                              }
                            },
                      icon: const Icon(Icons.event_rounded),
                      label: Text(
                        firstDueDate == null
                            ? 'Primeiro vencimento'
                            : 'Vence em ${date.format(firstDueDate!)}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notes,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(saving ? 'Salvando...' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    downPayment.dispose();
    discount.dispose();
    installments.dispose();
    installmentValue.dispose();
    notes.dispose();
  }

  Future<void> _openPaymentDialog(Project project) async {
    final projectId = project.id;
    if (projectId == null) return;

    var paymentType = paymentTypes.contains(project.paymentType)
        ? project.paymentType
        : paymentTypes.first;
    DateTime paidAt = DateTime.now();
    final amount = TextEditingController();
    final notes = TextEditingController();
    final idempotencyKey = const Uuid().v4();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final value = _number(amount.text);
              if (value <= 0) {
                _message('Informe um valor pago maior que zero.');
                return;
              }
              setDialogState(() => saving = true);
              try {
                await widget.repository.createProjectPayment(
                  projectId: projectId,
                  amount: value,
                  paymentType: paymentType,
                  paidAt: paidAt,
                  notes: notes.text,
                  idempotencyKey: idempotencyKey,
                );
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                _reload();
                _message('Pagamento registrado.');
              } catch (error) {
                if (!context.mounted) return;
                setDialogState(() => saving = false);
                _message(
                  friendlyNetworkError(
                    error,
                    fallback: 'Não foi possível registrar o pagamento.',
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Registrar pagamento'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _moneyField('Valor pago', amount),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: paymentType,
                      decoration:
                          const InputDecoration(labelText: 'Tipo de pagamento'),
                      items: paymentTypes
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(
                                () => paymentType = value ?? paymentType,
                              ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: paidAt,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (selected != null) {
                                setDialogState(() => paidAt = selected);
                              }
                            },
                      icon: const Icon(Icons.event_available_rounded),
                      label: Text('Pago em ${date.format(paidAt)}'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notes,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_card_rounded),
                  label: Text(saving ? 'Salvando...' : 'Registrar'),
                ),
              ],
            );
          },
        );
      },
    );

    amount.dispose();
    notes.dispose();
  }

  Future<void> _cancelPayment(ProjectPayment payment) async {
    try {
      await widget.repository.cancelProjectPayment(payment.id);
      _reload();
      _message('Pagamento removido do financeiro.');
    } catch (error) {
      _message(
        friendlyNetworkError(
          error,
          fallback: 'Não foi possível remover o pagamento.',
        ),
      );
    }
  }

  void _reload() {
    setState(() => future = _load(cacheFirst: false));
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _moneyField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }

  double _number(String value) {
    final text = value.trim();
    if (text.contains(',')) {
      return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ??
          0;
    }
    return double.tryParse(text) ?? 0;
  }

  int _int(String value) => int.tryParse(value.trim()) ?? 0;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.money});

  final _FinancialTotals summary;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SummaryMetric(
            title: 'Total líquido',
            value: money.format(summary.netTotal),
            color: AppTheme.primaryBlue,
            icon: Icons.receipt_long_rounded,
          ),
          _SummaryMetric(
            title: 'Pago',
            value: money.format(summary.paidTotal),
            color: AppTheme.green,
            icon: Icons.check_circle_rounded,
          ),
          _SummaryMetric(
            title: 'Falta pagar',
            value: money.format(summary.remainingTotal),
            color:
                summary.remainingTotal > 0 ? AppTheme.orange : AppTheme.green,
            icon: Icons.pending_actions_rounded,
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width >= 900 ? (width - 72) / 3 : double.infinity,
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
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
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

class _ProjectFinancialCard extends StatelessWidget {
  const _ProjectFinancialCard({
    required this.project,
    required this.payments,
    required this.money,
    required this.date,
    required this.onEditPlan,
    required this.onAddPayment,
    required this.onCancelPayment,
  });

  final Project project;
  final List<ProjectPayment> payments;
  final NumberFormat money;
  final DateFormat date;
  final VoidCallback onEditPlan;
  final VoidCallback onAddPayment;
  final ValueChanged<ProjectPayment> onCancelPayment;

  @override
  Widget build(BuildContext context) {
    final paid = payments
        .where((payment) => payment.isPaid)
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final downPayment = project.downPayment;
    final net = max(project.projectValue - project.discount, 0.0);
    final totalPaid = downPayment + paid;
    final remaining = max(net - totalPaid, 0.0);
    final status = _status(remaining, totalPaid);
    final statusColor = switch (status) {
      'Pago' => AppTheme.green,
      'Parcial' => AppTheme.primaryBlue,
      'Atrasado' => AppTheme.orange,
      _ => AppTheme.muted,
    };

    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Icon(Icons.account_balance_wallet_rounded,
                    color: statusColor),
              ),
              const SizedBox(width: 12),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#${project.id ?? '-'} • ${project.paymentType.isEmpty ? 'Pagamento não definido' : project.paymentType}',
                      style:
                          const TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: status, color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          _line('Valor do projeto', money.format(project.projectValue)),
          if (project.discount > 0)
            _line('Desconto', '- ${money.format(project.discount)}'),
          if (downPayment > 0) _line('Entrada', money.format(downPayment)),
          _line('Total pago', money.format(totalPaid)),
          _line('Faltando pagar', money.format(remaining), highlight: true),
          if (project.installmentsCount > 0 || project.installmentValue > 0)
            _line(
              'Parcelas',
              '${project.installmentsCount}x de ${money.format(project.installmentValue)}',
            ),
          if (project.firstDueDate != null)
            _line('Primeiro vencimento', date.format(project.firstDueDate!)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: net <= 0 ? 0 : (totalPaid / net).clamp(0, 1),
            minHeight: 7,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation(statusColor),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEditPlan,
                icon: const Icon(Icons.edit_rounded, size: 17),
                label: const Text('Editar financeiro'),
              ),
              ElevatedButton.icon(
                onPressed: onAddPayment,
                icon: const Icon(Icons.add_card_rounded, size: 17),
                label: const Text('Adicionar pagamento'),
              ),
            ],
          ),
          if (payments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppTheme.border),
            const Text('Pagamentos recebidos',
                style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            ...payments.take(3).map(
                  (payment) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.green.withValues(alpha: 0.12),
                      child: const Icon(Icons.payments_rounded,
                          color: AppTheme.green, size: 18),
                    ),
                    title: Text(money.format(payment.amount)),
                    subtitle: Text(
                      '${payment.paymentType.isEmpty ? 'Pagamento' : payment.paymentType} • ${payment.paidAt == null ? '-' : date.format(payment.paidAt!)}',
                    ),
                    trailing: IconButton(
                      onPressed: () => onCancelPayment(payment),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _status(double remaining, double totalPaid) {
    if (remaining <= 0 && project.projectValue > 0) return 'Pago';
    if (project.firstDueDate != null &&
        DateTime.now().isAfter(project.firstDueDate!) &&
        remaining > 0) {
      return 'Atrasado';
    }
    if (totalPaid > 0) return 'Parcial';
    return 'Em aberto';
  }

  Widget _line(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: AppTheme.muted))),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: highlight ? AppTheme.text : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FinancialData {
  const _FinancialData({
    this.projects = const [],
    this.payments = const [],
  });

  final List<Project> projects;
  final List<ProjectPayment> payments;

  Map<int?, List<ProjectPayment>> get paymentsByProject {
    final map = <int?, List<ProjectPayment>>{};
    for (final payment in payments) {
      map.putIfAbsent(payment.projectId, () => []).add(payment);
    }
    return map;
  }
}

class _FinancialTotals {
  const _FinancialTotals({
    required this.netTotal,
    required this.paidTotal,
    required this.remainingTotal,
  });

  final double netTotal;
  final double paidTotal;
  final double remainingTotal;

  factory _FinancialTotals.from(
    List<Project> projects,
    Map<int?, List<ProjectPayment>> paymentsByProject,
  ) {
    var net = 0.0;
    var paid = 0.0;
    for (final project in projects) {
      final projectNet = max(project.projectValue - project.discount, 0.0);
      final projectPaid =
          (paymentsByProject[project.id] ?? const <ProjectPayment>[])
              .where((payment) => payment.isPaid)
              .fold<double>(0, (sum, payment) => sum + payment.amount);
      net += projectNet;
      paid += project.downPayment + projectPaid;
    }
    return _FinancialTotals(
      netTotal: net,
      paidTotal: paid,
      remainingTotal: max(net - paid, 0.0),
    );
  }
}
