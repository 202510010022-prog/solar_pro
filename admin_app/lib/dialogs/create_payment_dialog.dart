import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/admin_company.dart';
import '../services/admin_repository.dart';
import '../widgets/admin_card.dart';
import '../widgets/field.dart';

class CreatePaymentDialog extends StatefulWidget {
  const CreatePaymentDialog({
    super.key,
    required this.repository,
    required this.companies,
  });

  final AdminRepository repository;
  final List<AdminCompany> companies;

  @override
  State<CreatePaymentDialog> createState() => _CreatePaymentDialogState();
}

class _CreatePaymentDialogState extends State<CreatePaymentDialog> {
  final amount = TextEditingController();
  final dueDate = TextEditingController();
  final pixReference = TextEditingController();
  final notes = TextEditingController();
  final idempotencyKey = const Uuid().v4();
  String companyId = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.companies.isNotEmpty) companyId = widget.companies.first.id;
    dueDate.text = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().add(const Duration(days: 7)));
  }

  @override
  void dispose() {
    amount.dispose();
    dueDate.dispose();
    pixReference.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final parsedAmount = _parseMoney(amount.text);
    final parsedDate = DateTime.tryParse(dueDate.text.trim());
    if (parsedAmount == null || parsedAmount <= 0 || parsedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe valor e vencimento válidos.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await widget.repository.createPayment(
        companyId: companyId,
        amount: parsedAmount,
        dueDate: parsedDate,
        pixReference: pixReference.text.trim(),
        notes: notes.text.trim(),
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cobrança criada e enviada ao app.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = '$error'.contains('Esta cobranca ja foi registrada')
          ? 'Esta cobrança já foi registrada.'
          : '$error'.replaceFirst('Bad state: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  double? _parseMoney(String value) {
    final text = value.trim();
    if (text.contains(',')) {
      return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));
    }
    return double.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: AdminCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nova cobrança Pix',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: companyId.isEmpty ? null : companyId,
                decoration: const InputDecoration(labelText: 'Empresa'),
                items: widget.companies
                    .map(
                      (company) => DropdownMenuItem(
                        value: company.id,
                        child: Text(company.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => companyId = value ?? ''),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Field(width: 180, controller: amount, label: 'Valor'),
                  Field(width: 180, controller: dueDate, label: 'Vencimento'),
                  Field(
                    width: 360,
                    controller: pixReference,
                    label: 'Referência Pix',
                  ),
                  Field(width: 560, controller: notes, label: 'Observações'),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: loading ? null : submit,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.pix_rounded),
                    label: Text(loading ? 'Criando...' : 'Criar cobrança'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
