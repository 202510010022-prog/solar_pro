import 'package:flutter/material.dart';

import '../app/admin_theme.dart';
import '../models/admin_company.dart';
import '../services/admin_repository.dart';
import '../widgets/admin_card.dart';
import '../widgets/field.dart';

class CreateMessageDialog extends StatefulWidget {
  const CreateMessageDialog({
    super.key,
    required this.repository,
    required this.companies,
  });

  final AdminRepository repository;
  final List<AdminCompany> companies;

  @override
  State<CreateMessageDialog> createState() => _CreateMessageDialogState();
}

class _CreateMessageDialogState extends State<CreateMessageDialog> {
  final title = TextEditingController();
  final message = TextEditingController();
  final expiresAt = TextEditingController();
  String companyId = '';
  String type = 'info';
  bool sendToAll = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.companies.isNotEmpty) companyId = widget.companies.first.id;
  }

  @override
  void dispose() {
    title.dispose();
    message.dispose();
    expiresAt.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!sendToAll && companyId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione a empresa.')));
      return;
    }

    setState(() => loading = true);
    try {
      await widget.repository.createMessage(
        companyId: companyId,
        sendToAll: sendToAll,
        title: title.text.trim(),
        message: message.text.trim(),
        type: type,
        expiresAt: expiresAt.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comunicado enviado ao app.')),
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
                  'Novo comunicado',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                SwitchListTile(
                  value: sendToAll,
                  onChanged: (value) => setState(() => sendToAll = value),
                  title: const Text('Enviar para todas as empresas ativas'),
                  subtitle: const Text(
                    'Use com cuidado para comunicados gerais da plataforma.',
                    style: TextStyle(color: AdminTheme.muted),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!sendToAll) ...[
                  const SizedBox(height: 12),
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
                    onChanged: (value) =>
                        setState(() => companyId = value ?? ''),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: const [
                          DropdownMenuItem(
                            value: 'info',
                            child: Text('Informação'),
                          ),
                          DropdownMenuItem(
                            value: 'warning',
                            child: Text('Atenção'),
                          ),
                          DropdownMenuItem(
                            value: 'success',
                            child: Text('Confirmação'),
                          ),
                          DropdownMenuItem(
                            value: 'billing',
                            child: Text('Cobrança'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => type = value ?? 'info'),
                      ),
                    ),
                    Field(
                      width: 220,
                      controller: expiresAt,
                      label: 'Expira em',
                    ),
                    Field(width: 640, controller: title, label: 'Título'),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: message,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Mensagem',
                    hintText: 'Escreva o comunicado que aparecerá no app...',
                  ),
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
                          : const Icon(Icons.campaign_rounded),
                      label: Text(loading ? 'Enviando...' : 'Enviar'),
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
