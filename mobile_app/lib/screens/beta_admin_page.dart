import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/beta_feedback.dart';
import '../models/manual_payment.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';
import 'team_users_page.dart';

class BetaAdminPage extends StatefulWidget {
  const BetaAdminPage({super.key, required this.repository});

  final SolarProRepository repository;

  @override
  State<BetaAdminPage> createState() => _BetaAdminPageState();
}

class _BetaAdminPageState extends State<BetaAdminPage> {
  late Future<_BetaAdminData> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_BetaAdminData> _load() async {
    final results = await Future.wait([
      widget.repository.loadBetaFeedback(),
      widget.repository.loadManualPayments(),
    ]);
    return _BetaAdminData(
      feedbacks: results[0] as List<BetaFeedback>,
      payments: results[1] as List<ManualPayment>,
    );
  }

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Central do beta',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Feedbacks'),
              Tab(text: 'Pix'),
              Tab(text: 'Convites'),
            ],
          ),
        ),
        body: FutureBuilder<_BetaAdminData>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(onRetry: _refresh);
            }
            final data = snapshot.data ?? const _BetaAdminData();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: TabBarView(
                children: [
                  _FeedbackTab(
                    feedbacks: data.feedbacks,
                    onStatusChanged: _updateFeedbackStatus,
                  ),
                  _PaymentsTab(
                    payments: data.payments,
                    onCreate: _createPayment,
                    onMarkPaid: _markPaymentPaid,
                    onCancel: _cancelPayment,
                  ),
                  _InvitesTab(repository: widget.repository),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _updateFeedbackStatus(
      BetaFeedback feedback, String status) async {
    try {
      await widget.repository.updateBetaFeedbackStatus(feedback.id, status);
      await _refresh();
      if (!mounted) return;
      _message('Feedback atualizado.');
    } catch (_) {
      if (!mounted) return;
      _message('Não foi possível atualizar o feedback.');
    }
  }

  Future<void> _createPayment({
    required double amount,
    required DateTime dueDate,
    required String pixReference,
    required String notes,
  }) async {
    try {
      await widget.repository.createManualPayment(
        amount: amount,
        dueDate: dueDate,
        pixReference: pixReference,
        notes: notes,
      );
      await _refresh();
      if (!mounted) return;
      _message('Cobrança criada.');
    } catch (error) {
      if (!mounted) return;
      _message(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _markPaymentPaid(ManualPayment payment, int months) async {
    try {
      await widget.repository.markManualPaymentPaid(
        payment.id,
        periodMonths: months,
      );
      await _refresh();
      if (!mounted) return;
      _message('Pagamento marcado como pago e assinatura atualizada.');
    } catch (error) {
      if (!mounted) return;
      _message(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _cancelPayment(ManualPayment payment) async {
    try {
      await widget.repository.cancelManualPayment(payment.id);
      await _refresh();
      if (!mounted) return;
      _message('Cobrança cancelada.');
    } catch (error) {
      if (!mounted) return;
      _message(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab({
    required this.feedbacks,
    required this.onStatusChanged,
  });

  final List<BetaFeedback> feedbacks;
  final Future<void> Function(BetaFeedback feedback, String status)
      onStatusChanged;

  @override
  Widget build(BuildContext context) {
    if (feedbacks.isEmpty) {
      return const _EmptyState(
        icon: Icons.rate_review_outlined,
        title: 'Nenhum feedback recebido',
        subtitle: 'Quando os usuários enviarem feedback, ele aparece aqui.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: feedbacks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = feedbacks[index];
        return NeonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.green.withValues(alpha: 0.12),
                    child: Text(
                      '${item.rating}',
                      style: const TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.areaLabel,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          _feedbackSubtitle(item),
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(label: item.statusLabel),
                ],
              ),
              const SizedBox(height: 12),
              Text(item.message),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: item.status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Aberto')),
                  DropdownMenuItem(
                      value: 'reviewing', child: Text('Em análise')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolvido')),
                  DropdownMenuItem(value: 'archived', child: Text('Arquivado')),
                ],
                onChanged: (value) {
                  if (value == null || value == item.status) return;
                  onStatusChanged(item, value);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _feedbackSubtitle(BetaFeedback item) {
    final author = item.profileName.isEmpty ? 'Usuário beta' : item.profileName;
    final date = item.createdAt == null
        ? ''
        : ' • ${DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt!)}';
    return '$author$date';
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({
    required this.payments,
    required this.onCreate,
    required this.onMarkPaid,
    required this.onCancel,
  });

  final List<ManualPayment> payments;
  final Future<void> Function({
    required double amount,
    required DateTime dueDate,
    required String pixReference,
    required String notes,
  }) onCreate;
  final Future<void> Function(ManualPayment payment, int months) onMarkPaid;
  final Future<void> Function(ManualPayment payment) onCancel;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final summary = _PaymentSummary.fromPayments(payments);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _FinancialSummaryCard(summary: summary, money: money),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: () => _openCreatePaymentDialog(context),
          icon: const Icon(Icons.add_card_rounded),
          label: const Text('Nova cobrança Pix'),
        ),
        const SizedBox(height: 14),
        if (payments.isEmpty)
          const _InlineEmptyState(
            icon: Icons.pix_rounded,
            title: 'Nenhuma cobrança registrada',
            subtitle: 'Crie a primeira cobrança Pix direto por aqui.',
          )
        else
          ...payments.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NeonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: item.isPaid
                              ? AppTheme.green.withValues(alpha: 0.12)
                              : AppTheme.orange.withValues(alpha: 0.14),
                          child: Icon(
                            item.isPaid
                                ? Icons.check_rounded
                                : Icons.pix_rounded,
                            color:
                                item.isPaid ? AppTheme.green : AppTheme.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                money.format(item.amount),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                _paymentSubtitle(item),
                                style: const TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusPill(label: item.statusLabel),
                      ],
                    ),
                    if (item.pixReference.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Pix: ${item.pixReference}'),
                    ],
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.notes,
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                    ],
                    if (item.canBePaid || item.canBeCanceled) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (item.canBePaid)
                            OutlinedButton.icon(
                              onPressed: () => _openPaidDialog(context, item),
                              icon: const Icon(
                                  Icons.check_circle_outline_rounded),
                              label: const Text('Marcar como pago'),
                            ),
                          if (item.canBeCanceled)
                            OutlinedButton.icon(
                              onPressed: () => onCancel(item),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancelar'),
                            ),
                        ],
                      ),
                    ] else if (item.isPaid) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _openReceiptDialog(context, item),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Ver recibo'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _openCreatePaymentDialog(BuildContext context) async {
    final result = await showDialog<_PaymentDraft>(
      context: context,
      builder: (_) => const _CreatePaymentDialog(),
    );
    if (result == null) return;
    await onCreate(
      amount: result.amount,
      dueDate: result.dueDate,
      pixReference: result.pixReference,
      notes: result.notes,
    );
  }

  Future<void> _openPaidDialog(
      BuildContext context, ManualPayment payment) async {
    final months = await showDialog<int>(
      context: context,
      builder: (_) => const _MarkPaidDialog(),
    );
    if (months == null) return;
    await onMarkPaid(payment, months);
  }

  Future<void> _openReceiptDialog(
      BuildContext context, ManualPayment payment) async {
    final receiptMoney = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    await showDialog<void>(
      context: context,
      builder: (_) => _ReceiptDialog(payment: payment, money: receiptMoney),
    );
  }

  String _paymentSubtitle(ManualPayment item) {
    final due = item.dueDate == null
        ? 'Sem vencimento'
        : 'Vence em ${DateFormat('dd/MM/yyyy').format(item.dueDate!)}';
    final paid = item.paidAt == null
        ? ''
        : ' • Pago em ${DateFormat('dd/MM/yyyy').format(item.paidAt!)}';
    return '$due$paid';
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({required this.summary, required this.money});

  final _PaymentSummary summary;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Relatório financeiro mensal',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryChip(
                label: 'Recebido no mês',
                value: money.format(summary.paidThisMonth),
                icon: Icons.savings_rounded,
                color: AppTheme.green,
              ),
              _SummaryChip(
                label: 'Pendente',
                value: money.format(summary.pendingTotal),
                icon: Icons.pix_rounded,
                color: AppTheme.primaryBlue,
              ),
              _SummaryChip(
                label: 'Atrasado',
                value: money.format(summary.overdueTotal),
                icon: Icons.warning_amber_rounded,
                color: AppTheme.orange,
              ),
              _SummaryChip(
                label: 'Pagas no mês',
                value: '${summary.paidCountThisMonth}',
                icon: Icons.check_circle_rounded,
                color: AppTheme.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width >= 820 ? (width - 78) / 2 : double.infinity,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppTheme.muted)),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
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

class _ReceiptDialog extends StatelessWidget {
  const _ReceiptDialog({required this.payment, required this.money});

  final ManualPayment payment;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final receipt = _receiptText(payment, money);
    return AlertDialog(
      title: const Text('Recibo de pagamento'),
      content: SingleChildScrollView(
        child: SelectableText(receipt),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: receipt));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recibo copiado.')),
            );
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copiar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }

  String _receiptText(ManualPayment payment, NumberFormat money) {
    final paidAt = payment.paidAt == null
        ? 'Pagamento confirmado'
        : DateFormat('dd/MM/yyyy HH:mm').format(payment.paidAt!);
    final dueDate = payment.dueDate == null
        ? 'Nao informado'
        : DateFormat('dd/MM/yyyy').format(payment.dueDate!);
    final reference = payment.pixReference.trim().isEmpty
        ? 'Nao informada'
        : payment.pixReference.trim();
    final notes = payment.notes.trim().isEmpty ? '-' : payment.notes.trim();

    return '''
SOLAR PRO
Recibo de pagamento

Cobrança: #${payment.id}
Valor: ${money.format(payment.amount)}
Status: ${payment.statusLabel}
Vencimento: $dueDate
Pago em: $paidAt
Referência Pix: $reference
Observação: $notes

Este recibo confirma o registro manual do pagamento no Solar Pro.
'''
        .trim();
  }
}

class _PaymentSummary {
  const _PaymentSummary({
    required this.paidThisMonth,
    required this.pendingTotal,
    required this.overdueTotal,
    required this.paidCountThisMonth,
  });

  final double paidThisMonth;
  final double pendingTotal;
  final double overdueTotal;
  final int paidCountThisMonth;

  factory _PaymentSummary.fromPayments(List<ManualPayment> payments) {
    final now = DateTime.now();
    var paidThisMonth = 0.0;
    var pendingTotal = 0.0;
    var overdueTotal = 0.0;
    var paidCountThisMonth = 0;

    for (final payment in payments) {
      if (payment.status == 'pending') pendingTotal += payment.amount;
      if (payment.status == 'overdue') overdueTotal += payment.amount;
      final paidAt = payment.paidAt;
      if (payment.isPaid &&
          paidAt != null &&
          paidAt.year == now.year &&
          paidAt.month == now.month) {
        paidThisMonth += payment.amount;
        paidCountThisMonth++;
      }
    }

    return _PaymentSummary(
      paidThisMonth: paidThisMonth,
      pendingTotal: pendingTotal,
      overdueTotal: overdueTotal,
      paidCountThisMonth: paidCountThisMonth,
    );
  }
}

class _CreatePaymentDialog extends StatefulWidget {
  const _CreatePaymentDialog();

  @override
  State<_CreatePaymentDialog> createState() => _CreatePaymentDialogState();
}

class _CreatePaymentDialogState extends State<_CreatePaymentDialog> {
  final amount = TextEditingController();
  final pixReference = TextEditingController();
  final notes = TextEditingController();
  DateTime dueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    amount.dispose();
    pixReference.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova cobrança Pix'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vencimento'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(dueDate)),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pixReference,
              decoration: const InputDecoration(
                labelText: 'Referência Pix',
                hintText: 'Chave, txid ou observação curta',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observação'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.pix_rounded),
          label: const Text('Criar'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null) return;
    setState(() => dueDate = selected);
  }

  void _submit() {
    final value = double.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;
    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido.')),
      );
      return;
    }
    Navigator.pop(
      context,
      _PaymentDraft(
        amount: value,
        dueDate: dueDate,
        pixReference: pixReference.text,
        notes: notes.text,
      ),
    );
  }
}

class _MarkPaidDialog extends StatefulWidget {
  const _MarkPaidDialog();

  @override
  State<_MarkPaidDialog> createState() => _MarkPaidDialogState();
}

class _MarkPaidDialogState extends State<_MarkPaidDialog> {
  int months = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar pagamento'),
      content: DropdownButtonFormField<int>(
        initialValue: months,
        decoration: const InputDecoration(labelText: 'Período liberado'),
        items: const [
          DropdownMenuItem(value: 1, child: Text('1 mês')),
          DropdownMenuItem(value: 3, child: Text('3 meses')),
          DropdownMenuItem(value: 6, child: Text('6 meses')),
          DropdownMenuItem(value: 12, child: Text('12 meses')),
        ],
        onChanged: (value) => setState(() => months = value ?? 1),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, months),
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class _PaymentDraft {
  const _PaymentDraft({
    required this.amount,
    required this.dueDate,
    required this.pixReference,
    required this.notes,
  });

  final double amount;
  final DateTime dueDate;
  final String pixReference;
  final String notes;
}

class _InvitesTab extends StatelessWidget {
  const _InvitesTab({required this.repository});

  final SolarProRepository repository;

  @override
  Widget build(BuildContext context) {
    const inviteMessage = '''
Olá! Seu acesso ao Solar Pro beta foi liberado.

Baixe o app, entre com seu e-mail e senha temporária, e teste principalmente:
- cadastro de clientes
- criação de projetos
- dimensionamento solar
- detalhes do projeto

Depois envie feedback pela aba Mais > Enviar feedback.
''';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NeonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Convite de usuário beta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Por segurança, a criação do usuário ainda deve ser feita no Supabase Authentication. Depois disso, copie esta mensagem para WhatsApp ou e-mail.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeamUsersPage(repository: repository),
                  ),
                ),
                icon: const Icon(Icons.people_alt_rounded),
                label: const Text('Abrir usuários da equipe'),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(inviteMessage),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        NeonCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.green.withValues(alpha: 0.12),
                child: Icon(icon, color: AppTheme.green),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.green.withValues(alpha: 0.12),
            child: Icon(icon, color: AppTheme.green),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: NeonCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.orange),
              const SizedBox(height: 10),
              const Text(
                'Não foi possível carregar a central.',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BetaAdminData {
  const _BetaAdminData({
    this.feedbacks = const [],
    this.payments = const [],
  });

  final List<BetaFeedback> feedbacks;
  final List<ManualPayment> payments;
}
