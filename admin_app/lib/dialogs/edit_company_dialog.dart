import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/admin_company.dart';
import '../models/admin_plan.dart';
import '../services/admin_repository.dart';
import '../widgets/admin_card.dart';
import '../widgets/field.dart';

class EditCompanyDialog extends StatefulWidget {
  const EditCompanyDialog({
    super.key,
    required this.repository,
    required this.company,
    required this.plans,
  });

  final AdminRepository repository;
  final AdminCompany company;
  final List<AdminPlan> plans;

  @override
  State<EditCompanyDialog> createState() => _EditCompanyDialogState();
}

class _EditCompanyDialogState extends State<EditCompanyDialog> {
  late final name = TextEditingController(text: widget.company.name);
  late final document = TextEditingController(text: widget.company.document);
  late final billingEmail = TextEditingController(
    text: widget.company.billingEmail,
  );
  late String planSlug = widget.company.planSlug;
  late String status = widget.company.status;
  late bool active = widget.company.active;
  final endsAt = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final date = widget.company.subscriptionEndsAt;
    endsAt.text = date == null ? '' : DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  void dispose() {
    name.dispose();
    document.dispose();
    billingEmail.dispose();
    endsAt.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await widget.repository.updateCompany(
        companyId: widget.company.id,
        name: name.text.trim(),
        document: document.text.trim(),
        planSlug: planSlug,
        status: status,
        billingEmail: billingEmail.text.trim(),
        active: active,
        subscriptionEndsAt: endsAt.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Empresa atualizada.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: AdminCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.company.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nome da empresa',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Field(width: 260, controller: document, label: 'Documento'),
                    Field(
                      width: 280,
                      controller: billingEmail,
                      label: 'E-mail de cobrança',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: planSlug,
                  decoration: const InputDecoration(labelText: 'Plano'),
                  items: widget.plans
                      .map(
                        (plan) => DropdownMenuItem(
                          value: plan.slug,
                          child: Text(plan.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => planSlug = value ?? planSlug),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'trial', child: Text('Teste')),
                    DropdownMenuItem(value: 'active', child: Text('Ativa')),
                    DropdownMenuItem(
                      value: 'past_due',
                      child: Text('Atrasada'),
                    ),
                    DropdownMenuItem(
                      value: 'blocked',
                      child: Text('Bloqueada'),
                    ),
                    DropdownMenuItem(
                      value: 'canceled',
                      child: Text('Cancelada'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => status = value ?? status),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endsAt,
                  decoration: const InputDecoration(
                    labelText: 'Fim da assinatura',
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: Icon(Icons.event_rounded),
                  ),
                ),
                SwitchListTile(
                  value: active,
                  onChanged: (value) => setState(() => active = value),
                  title: const Text('Empresa ativa'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 18),
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
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
