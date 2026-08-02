import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_profile.dart';
import '../models/team_invite_result.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';

class TeamUsersPage extends StatefulWidget {
  const TeamUsersPage({super.key, required this.repository});

  final SolarProRepository repository;

  @override
  State<TeamUsersPage> createState() => _TeamUsersPageState();
}

class _TeamUsersPageState extends State<TeamUsersPage> {
  late Future<List<AppProfile>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.loadTeamProfiles();
  }

  Future<void> _refresh() async {
    setState(() {
      future = widget.repository.loadTeamProfiles();
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Usuários da equipe',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openInviteDialog,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Convidar'),
      ),
      body: FutureBuilder<List<AppProfile>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _TeamErrorState(onRetry: _refresh);
          }
          final profiles = snapshot.data ?? const [];
          if (profiles.isEmpty) {
            return const _TeamEmptyState();
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return NeonCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: profile.active
                            ? AppTheme.green
                            : AppTheme.muted.withValues(alpha: 0.18),
                        child: Text(
                          _initials(profile.name),
                          style: TextStyle(
                            color:
                                profile.active ? Colors.white : AppTheme.muted,
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
                              profile.name.isEmpty
                                  ? 'Usuário sem nome'
                                  : profile.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${profile.email}\nMatrícula ${profile.matricula} • ${_permissionLabel(profile.permission)}',
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _TeamUserActions(
                        profile: profile,
                        onEdit: () => _openEditDialog(profile),
                        onToggle: () => _toggleActive(profile, !profile.active),
                        onDelete: () => _deleteUser(profile),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleActive(AppProfile profile, bool active) async {
    try {
      await widget.repository.updateTeamUser(
        profileId: profile.id,
        name: profile.name,
        email: profile.email,
        matricula: profile.matricula,
        permission: _editablePermission(profile.permission),
        role: _permissionLabel(_editablePermission(profile.permission)),
        active: active,
      );
      await _refresh();
      if (!mounted) return;
      _message(active ? 'Usuário ativado.' : 'Usuário desativado.');
    } catch (_) {
      if (!mounted) return;
      _message('Não foi possível atualizar o usuário.');
    }
  }

  Future<void> _deleteUser(AppProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir usuário?'),
        content: Text(
          'O acesso de ${profile.name} será removido da equipe. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deleteTeamUser(profile.id);
      await _refresh();
      if (!mounted) return;
      _message('Usuário excluído.');
    } catch (error) {
      if (!mounted) return;
      _message(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _openEditDialog(AppProfile profile) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _EditTeamUserDialog(
        repository: widget.repository,
        profile: profile,
      ),
    );
    if (updated != true || !mounted) return;
    await _refresh();
    if (!mounted) return;
    _message('Usuário atualizado.');
  }

  Future<void> _openInviteDialog() async {
    final result = await showDialog<TeamInviteResult>(
      context: context,
      builder: (_) => _InviteUserDialog(repository: widget.repository),
    );
    if (result == null || !mounted) return;
    await _refresh();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _InviteResultDialog(result: result),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'SP';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _TeamUserActions extends StatelessWidget {
  const _TeamUserActions({
    required this.profile,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final AppProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (profile.permission == 'owner') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.green.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.green.withValues(alpha: 0.25)),
        ),
        child: const Text(
          'Master protegido',
          style: TextStyle(
            color: AppTheme.green,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final showLabels = MediaQuery.sizeOf(context).width >= 760;
        if (!showLabels) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Editar dados e senha',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: profile.active ? 'Congelar acesso' : 'Reativar acesso',
                onPressed: onToggle,
                icon: Icon(
                  profile.active
                      ? Icons.lock_outline_rounded
                      : Icons.lock_open_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Excluir assessor',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar'),
            ),
            OutlinedButton.icon(
              onPressed: onToggle,
              icon: Icon(
                profile.active
                    ? Icons.lock_outline_rounded
                    : Icons.lock_open_rounded,
                size: 18,
              ),
              label: Text(profile.active ? 'Congelar' : 'Reativar'),
            ),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }
}

class _EditTeamUserDialog extends StatefulWidget {
  const _EditTeamUserDialog({
    required this.repository,
    required this.profile,
  });

  final SolarProRepository repository;
  final AppProfile profile;

  @override
  State<_EditTeamUserDialog> createState() => _EditTeamUserDialogState();
}

class _EditTeamUserDialogState extends State<_EditTeamUserDialog> {
  late final name = TextEditingController(text: widget.profile.name);
  late final email = TextEditingController(text: widget.profile.email);
  late final matricula = TextEditingController(text: widget.profile.matricula);
  final password = TextEditingController();
  late var permission = _editablePermission(widget.profile.permission);
  late var active = widget.profile.active;
  bool sending = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    matricula.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar usuário'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              enabled: !sending,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              enabled: !sending,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: matricula,
              enabled: !sending,
              decoration: const InputDecoration(labelText: 'Matrícula'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: permission,
              decoration: const InputDecoration(labelText: 'Permissão'),
              items: const [
                DropdownMenuItem(
                  value: 'assessor_projetos',
                  child: Text('Assessor de projetos'),
                ),
                DropdownMenuItem(
                  value: 'assessor_daf',
                  child: Text('Assessor DAF'),
                ),
                DropdownMenuItem(value: 'diretor', child: Text('Diretor')),
              ],
              onChanged: sending
                  ? null
                  : (value) => setState(() => permission = value ?? permission),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              enabled: !sending,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nova senha opcional',
                hintText: 'Preencha somente se quiser redefinir',
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              value: active,
              onChanged:
                  sending ? null : (value) => setState(() => active = value),
              title: const Text('Usuário ativo'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: sending ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: sending ? null : _submit,
          icon: sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(sending ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final cleanName = name.text.trim();
    final cleanEmail = email.text.trim();
    final cleanMatricula = matricula.text.trim();
    if (cleanName.length < 3 ||
        cleanEmail.length < 5 ||
        cleanMatricula.length < 3) {
      _message('Preencha nome, e-mail e matrícula.');
      return;
    }

    setState(() => sending = true);
    try {
      await widget.repository.updateTeamUser(
        profileId: widget.profile.id,
        name: cleanName,
        email: cleanEmail,
        matricula: cleanMatricula,
        permission: permission,
        role: _permissionLabel(permission),
        active: active,
        password: password.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => sending = false);
      _message(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _InviteUserDialog extends StatefulWidget {
  const _InviteUserDialog({required this.repository});

  final SolarProRepository repository;

  @override
  State<_InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<_InviteUserDialog> {
  final name = TextEditingController();
  final email = TextEditingController();
  final matricula = TextEditingController();
  final password = TextEditingController();
  var permission = 'assessor_projetos';
  bool sending = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    matricula.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Convidar usuário'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              enabled: !sending,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              enabled: !sending,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: matricula,
              enabled: !sending,
              decoration: const InputDecoration(labelText: 'Matrícula'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: permission,
              decoration: const InputDecoration(labelText: 'Permissão'),
              items: const [
                DropdownMenuItem(
                  value: 'assessor_projetos',
                  child: Text('Assessor de projetos'),
                ),
                DropdownMenuItem(
                  value: 'assessor_daf',
                  child: Text('Assessor DAF'),
                ),
                DropdownMenuItem(value: 'diretor', child: Text('Diretor')),
              ],
              onChanged: sending
                  ? null
                  : (value) => setState(() => permission = value ?? permission),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              enabled: !sending,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha opcional',
                hintText: 'Vazio gera senha temporária',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: sending ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: sending ? null : _submit,
          icon: sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(sending ? 'Criando...' : 'Criar usuário'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final cleanName = name.text.trim();
    final cleanEmail = email.text.trim();
    final cleanMatricula = matricula.text.trim();
    if (cleanName.length < 3 ||
        cleanEmail.length < 5 ||
        cleanMatricula.length < 3) {
      _message('Preencha nome, e-mail e matrícula.');
      return;
    }

    setState(() => sending = true);
    try {
      final result = await widget.repository.inviteTeamUser(
        name: cleanName,
        email: cleanEmail,
        matricula: cleanMatricula,
        permission: permission,
        role: _permissionLabel(permission),
        password: password.text,
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      setState(() => sending = false);
      _message(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _InviteResultDialog extends StatelessWidget {
  const _InviteResultDialog({required this.result});

  final TeamInviteResult result;

  @override
  Widget build(BuildContext context) {
    final hasTempPassword = result.temporaryPassword.isNotEmpty;
    final message = '''
Usuário criado com sucesso.

Nome: ${result.name}
E-mail: ${result.email}
Matrícula: ${result.matricula}
Cargo: ${result.role}
${hasTempPassword ? 'Senha temporária: ${result.temporaryPassword}' : 'Senha: definida manualmente'}
''';

    return AlertDialog(
      title: const Text('Usuário criado'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(message.trim()),
            if (hasTempPassword) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.green.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppTheme.green.withValues(alpha: 0.35),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Senha temporária gerada',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      result.temporaryPassword,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (hasTempPassword)
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: result.temporaryPassword),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Senha copiada.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copiar senha'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _TeamEmptyState extends StatelessWidget {
  const _TeamEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: NeonCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_alt_outlined, color: AppTheme.green),
              SizedBox(height: 10),
              Text(
                'Nenhum usuário encontrado.',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamErrorState extends StatelessWidget {
  const _TeamErrorState({required this.onRetry});

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
                'Não foi possível carregar a equipe.',
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

String _permissionLabel(String permission) {
  return switch (permission) {
    'assessor_daf' => 'Assessor DAF',
    'diretor' => 'Diretor',
    'owner' => 'Master',
    'platform_admin' => 'Admin Plataforma',
    _ => 'Assessor de Projetos',
  };
}

String _editablePermission(String permission) {
  return switch (permission) {
    'assessor_daf' => 'assessor_daf',
    'diretor' => 'diretor',
    _ => 'assessor_projetos',
  };
}
