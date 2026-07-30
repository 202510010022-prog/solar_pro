import 'package:flutter/material.dart';

import '../app/admin_theme.dart';
import '../models/admin_company.dart';
import '../models/admin_user.dart';
import '../services/admin_repository.dart';
import '../widgets/admin_card.dart';
import '../widgets/field.dart';

class EditUserDialog extends StatefulWidget {
  const EditUserDialog({
    super.key,
    required this.repository,
    required this.user,
    required this.companies,
  });

  final AdminRepository repository;
  final AdminUser user;
  final List<AdminCompany> companies;

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final name = TextEditingController(text: widget.user.name);
  late final email = TextEditingController(text: widget.user.email);
  late final matricula = TextEditingController(text: widget.user.matricula);
  late final role = TextEditingController(text: widget.user.role);
  final password = TextEditingController();
  late String companyId = widget.user.companyId;
  late String permission = widget.user.permission;
  late bool active = widget.user.active;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final hasCompany = widget.companies.any(
      (company) => company.id == companyId,
    );
    if (!hasCompany && widget.companies.isNotEmpty) {
      companyId = widget.companies.first.id;
    }
    if (![
      'assessor_projetos',
      'assessor_daf',
      'diretor',
      'owner',
      'platform_admin',
    ].contains(permission)) {
      permission = 'assessor_projetos';
    }
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
      await widget.repository.updateUser(
        userId: widget.user.id,
        companyId: companyId,
        name: name.text.trim(),
        email: email.text.trim(),
        matricula: matricula.text.trim(),
        role: role.text.trim(),
        permission: permission,
        active: active,
        password: password.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário atualizado com sucesso.')),
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
                  'Editar usuário',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Altere dados de acesso, permissão e senha quando necessário.',
                  style: TextStyle(color: AdminTheme.muted),
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
                    Field(width: 320, controller: name, label: 'Nome'),
                    Field(width: 320, controller: email, label: 'E-mail'),
                    Field(
                      width: 180,
                      controller: matricula,
                      label: 'Matrícula',
                    ),
                    SizedBox(
                      width: 240,
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
                    Field(
                      width: 260,
                      controller: password,
                      label: 'Nova senha opcional',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: active,
                  onChanged: (value) => setState(() => active = value),
                  title: const Text('Usuário ativo'),
                  subtitle: const Text(
                    'Usuários inativos perdem acesso ao app.',
                    style: TextStyle(color: AdminTheme.muted),
                  ),
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
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(loading ? 'Salvando...' : 'Salvar usuário'),
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
