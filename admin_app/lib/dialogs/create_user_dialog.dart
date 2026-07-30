import 'package:flutter/material.dart';

import '../models/admin_company.dart';
import '../services/admin_repository.dart';
import '../widgets/admin_card.dart';
import '../widgets/field.dart';

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({
    super.key,
    required this.repository,
    required this.companies,
    this.initialCompanyId = '',
  });

  final AdminRepository repository;
  final List<AdminCompany> companies;
  final String initialCompanyId;

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final name = TextEditingController();
  final email = TextEditingController();
  final matricula = TextEditingController();
  final role = TextEditingController(text: 'Assessor de Projetos');
  final password = TextEditingController();
  String companyId = '';
  String permission = 'assessor_projetos';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.companies.isEmpty) return;
    final hasInitial = widget.companies.any(
      (company) => company.id == widget.initialCompanyId,
    );
    companyId = hasInitial
        ? widget.initialCompanyId
        : widget.companies.first.id;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    matricula.dispose();
    role.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await widget.repository.createUser(
        companyId: companyId,
        name: name.text.trim(),
        email: email.text.trim(),
        matricula: matricula.text.trim(),
        role: role.text.trim(),
        permission: permission,
        password: password.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário criado com sucesso.')),
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
        constraints: const BoxConstraints(maxWidth: 720),
        child: AdminCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Novo usuário',
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
                    Field(width: 310, controller: name, label: 'Nome'),
                    Field(width: 310, controller: email, label: 'E-mail'),
                    Field(
                      width: 180,
                      controller: matricula,
                      label: 'Matrícula',
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: permission,
                        decoration: const InputDecoration(
                          labelText: 'Permissão',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'assessor_projetos',
                            child: Text('Assessor Projetos'),
                          ),
                          DropdownMenuItem(
                            value: 'assessor_daf',
                            child: Text('Assessor DAF'),
                          ),
                          DropdownMenuItem(
                            value: 'diretor',
                            child: Text('Diretor'),
                          ),
                          DropdownMenuItem(
                            value: 'owner',
                            child: Text('Master da empresa'),
                          ),
                          DropdownMenuItem(
                            value: 'platform_admin',
                            child: Text('Admin Plataforma'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            permission = value ?? 'assessor_projetos';
                            role.text = switch (permission) {
                              'assessor_daf' => 'Assessor DAF',
                              'diretor' => 'Diretor',
                              'owner' => 'Usuário Master',
                              'platform_admin' => 'Administrador da Plataforma',
                              _ => 'Assessor de Projetos',
                            };
                          });
                        },
                      ),
                    ),
                    Field(width: 260, controller: role, label: 'Cargo'),
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
                          : const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(loading ? 'Criando...' : 'Criar usuário'),
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
