import 'package:flutter/material.dart';

import '../app/admin_theme.dart';
import '../models/admin_plan.dart';
import '../services/admin_repository.dart';
import '../widgets/admin_card.dart';
import '../widgets/field.dart';

class CreateCompanyDialog extends StatefulWidget {
  const CreateCompanyDialog({
    super.key,
    required this.repository,
    required this.plans,
  });

  final AdminRepository repository;
  final List<AdminPlan> plans;

  @override
  State<CreateCompanyDialog> createState() => _CreateCompanyDialogState();
}

class _CreateCompanyDialogState extends State<CreateCompanyDialog> {
  final companyName = TextEditingController();
  final document = TextEditingController();
  final billingEmail = TextEditingController();
  final masterName = TextEditingController();
  final masterEmail = TextEditingController();
  final matricula = TextEditingController();
  final password = TextEditingController();
  String planSlug = 'starter';
  String status = 'trial';
  int trialDays = 14;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.plans.isNotEmpty) planSlug = widget.plans.first.slug;
  }

  @override
  void dispose() {
    companyName.dispose();
    document.dispose();
    billingEmail.dispose();
    masterName.dispose();
    masterEmail.dispose();
    matricula.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await widget.repository.createCompany(
        companyName: companyName.text.trim(),
        document: document.text.trim(),
        planSlug: planSlug,
        status: status,
        billingEmail: billingEmail.text.trim(),
        trialDays: trialDays,
        masterName: masterName.text.trim(),
        masterEmail: masterEmail.text.trim(),
        matricula: matricula.text.trim(),
        password: password.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empresa e master criados.')),
      );
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
        constraints: const BoxConstraints(maxWidth: 760),
        child: AdminCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nova empresa',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Field(
                      width: 360,
                      controller: companyName,
                      label: 'Empresa',
                    ),
                    Field(width: 220, controller: document, label: 'CNPJ/CPF'),
                    Field(
                      width: 320,
                      controller: billingEmail,
                      label: 'E-mail financeiro',
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
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
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: 'trial',
                            child: Text('Teste'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Ativa'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => status = value ?? status),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: TextFormField(
                        initialValue: '$trialDays',
                        decoration: const InputDecoration(
                          labelText: 'Dias iniciais',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            trialDays = int.tryParse(value) ?? 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AdminTheme.border),
                const SizedBox(height: 12),
                const Text(
                  'Usuário master',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Field(width: 300, controller: masterName, label: 'Nome'),
                    Field(width: 300, controller: masterEmail, label: 'E-mail'),
                    Field(
                      width: 180,
                      controller: matricula,
                      label: 'Matrícula',
                    ),
                    Field(width: 220, controller: password, label: 'Senha'),
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
                          : const Icon(Icons.check_rounded),
                      label: Text(loading ? 'Criando...' : 'Criar empresa'),
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
