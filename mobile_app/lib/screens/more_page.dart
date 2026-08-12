import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../config/legal_config.dart';
import '../models/app_profile.dart';
import '../models/app_subscription.dart';
import '../models/manual_payment.dart';
import '../services/report_service.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../utils/legal_launcher.dart';
import '../widgets/neon_card.dart';
import 'legal_privacy_page.dart';
import 'messages_page.dart';
import 'team_users_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    required this.repository,
    required this.profile,
    required this.subscription,
    required this.onLogout,
  });

  final SolarProRepository repository;
  final AppProfile? profile;
  final AppSubscription? subscription;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final currentProfile = profile;
    final currentSubscription = subscription;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Mais',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Conta, sincronização e atalhos do Solar Pro.',
            style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 16),
        NeonCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.green,
                child: Text(
                  _initials(currentProfile?.name ?? 'Solar Pro'),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentProfile?.name.isNotEmpty == true
                          ? currentProfile!.name
                          : 'Usuário Solar Pro',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentProfile == null
                          ? 'Perfil carregando...'
                          : 'Matrícula ${currentProfile.matricula} • ${currentProfile.role}',
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SubscriptionCard(subscription: currentSubscription),
        if (currentProfile?.canManageAll == true) ...[
          const SizedBox(height: 14),
          _BillingStatusCard(repository: repository),
        ],
        const SizedBox(height: 14),
        NeonCard(
          child: Column(
            children: [
              const _InfoRow(
                icon: Icons.cloud_done_outlined,
                title: 'Sincronização',
                subtitle: 'Dados conectados ao Supabase',
                color: AppTheme.green,
              ),
              const Divider(color: AppTheme.border),
              _InfoRow(
                icon: Icons.verified_user_outlined,
                title: 'Permissão',
                subtitle: currentProfile?.permission ?? 'Indefinida',
                color: AppTheme.primaryBlue,
              ),
              const Divider(color: AppTheme.border),
              const _InfoRow(
                icon: Icons.phone_android_rounded,
                title: 'Versão do aplicativo',
                subtitle: 'Solar Pro Mobile 0.1.0',
                color: AppTheme.orange,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        NeonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Relatórios',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.file_download_outlined,
                title: 'Exportar relatório',
                subtitle: currentProfile?.canManageAll == true
                    ? 'Gere CSV ou PDF com os projetos da empresa'
                    : 'Gere CSV ou PDF apenas com seus projetos',
                onTap: () => _openReportDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        NeonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Comunicação',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.mark_email_unread_outlined,
                title: 'Mensagens',
                subtitle: 'Avisos importantes, cobranças e comunicados',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MessagesPage(repository: repository),
                  ),
                ),
              ),
              _ActionTile(
                icon: Icons.rate_review_outlined,
                title: 'Enviar feedback',
                subtitle: 'Conte o que funcionou, travou ou precisa melhorar',
                onTap: () => _openFeedbackDialog(context),
              ),
              if (currentProfile?.canManageAll == true)
                _ActionTile(
                  icon: Icons.people_alt_outlined,
                  title: 'Usuários da equipe',
                  subtitle: 'Criar convites e ativar ou desativar acessos',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeamUsersPage(repository: repository),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        NeonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Legal e suporte',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Legal e Privacidade',
                subtitle: 'Políticas, termos e solicitação de exclusão',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LegalPrivacyPage(profile: currentProfile),
                  ),
                ),
              ),
              _ActionTile(
                icon: Icons.help_outline_rounded,
                title: 'Ajuda e suporte',
                subtitle: 'Dúvidas, privacidade e contato da equipe',
                onTap: () => _openSupport(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        NeonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Atalhos futuros',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.settings_outlined,
                title: 'Configurações',
                subtitle: 'Preferências, empresa e parâmetros padrão',
                onTap: () => _comingSoon(context),
              ),
              _ActionTile(
                icon: Icons.history_rounded,
                title: 'Histórico de sincronização',
                subtitle: 'Últimos envios e atualizações',
                onTap: () => _comingSoon(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sair da conta'),
        ),
      ],
    );
  }

  Future<void> _openSupport(BuildContext context) async {
    final opened = await openExternalUri(Uri.parse(LegalConfig.supportUrl));
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir este link.')),
      );
    }
  }

  Future<void> _openFeedbackDialog(BuildContext context) async {
    final currentProfile = profile;
    if (currentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil ainda não carregado.')),
      );
      return;
    }

    const areas = {
      'geral': 'Geral',
      'login': 'Login',
      'crm': 'CRM',
      'projetos': 'Projetos',
      'dimensionamento': 'Dimensionamento',
      'financeiro': 'Financeiro',
      'sincronizacao': 'Sincronização',
      'visual': 'Visual',
    };
    final controller = TextEditingController();
    var area = 'geral';
    var rating = 5;
    var sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final message = controller.text.trim();
              if (message.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Escreva um feedback um pouco mais completo.'),
                  ),
                );
                return;
              }

              setDialogState(() => sending = true);
              try {
                await repository.submitBetaFeedback(
                  companyId: currentProfile.companyId,
                  rating: rating,
                  area: area,
                  message: message,
                );
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback enviado. Obrigado!')),
                );
              } catch (_) {
                if (!context.mounted) return;
                setDialogState(() => sending = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível enviar o feedback agora.'),
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Feedback do beta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: rating,
                      decoration: const InputDecoration(labelText: 'Nota'),
                      items: List.generate(
                        5,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1} de 5'),
                        ),
                      ),
                      onChanged: sending
                          ? null
                          : (value) =>
                              setDialogState(() => rating = value ?? 5),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: area,
                      decoration: const InputDecoration(labelText: 'Área'),
                      items: areas.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: sending
                          ? null
                          : (value) =>
                              setDialogState(() => area = value ?? 'geral'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      enabled: !sending,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Comentário',
                        hintText: 'Ex: ficou confuso salvar um projeto...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      sending ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: sending ? null : submit,
                  icon: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(sending ? 'Enviando...' : 'Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _openReportDialog(BuildContext context) async {
    var type = ReportType.projects;
    var format = ReportFormat.pdf;
    var exporting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> export() async {
              setDialogState(() => exporting = true);
              final service = ReportService(repository);
              try {
                final report = await service.generateProjectsReport(
                  type: type,
                  format: format,
                  profile: profile,
                );
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      kIsWeb
                          ? '${report.fileName} gerado. Clique em Baixar.'
                          : report.path == null
                              ? '${report.fileName} gerado.'
                              : 'Relatório salvo em ${report.path}.',
                    ),
                    action: SnackBarAction(
                      label: kIsWeb ? 'Baixar' : 'Compartilhar',
                      onPressed: () => kIsWeb
                          ? service.downloadReport(report)
                          : service.shareReport(report),
                    ),
                  ),
                );
              } catch (_) {
                if (!context.mounted) return;
                setDialogState(() => exporting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível gerar o relatório.'),
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Exportar relatório'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ReportType>(
                    initialValue: type,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de relatório'),
                    items: ReportType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: exporting
                        ? null
                        : (value) => setDialogState(() => type = value ?? type),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ReportFormat>(
                    initialValue: format,
                    decoration:
                        const InputDecoration(labelText: 'Formato do arquivo'),
                    items: ReportFormat.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: exporting
                        ? null
                        : (value) =>
                            setDialogState(() => format = value ?? format),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      exporting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: exporting ? null : export,
                  icon: exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download_outlined),
                  label: Text(exporting ? 'Gerando...' : 'Gerar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Função reservada para a próxima etapa.')),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'SP';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription});

  final AppSubscription? subscription;

  @override
  Widget build(BuildContext context) {
    final data = subscription;
    if (data == null) {
      return const NeonCard(
        child: _InfoRow(
          icon: Icons.workspace_premium_outlined,
          title: 'Assinatura',
          subtitle: 'Carregando dados do plano...',
          color: AppTheme.orange,
        ),
      );
    }

    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: data.isActive
                    ? AppTheme.green.withValues(alpha: 0.12)
                    : AppTheme.orange.withValues(alpha: 0.14),
                child: Icon(
                  data.isActive
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  color: data.isActive ? AppTheme.green : AppTheme.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plano ${data.planName}',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w900)),
                    Text(data.statusLabel,
                        style: const TextStyle(color: AppTheme.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PlanLine(
              label: 'Mensalidade', value: money.format(data.monthlyPrice)),
          _PlanLine(label: 'Cobrança', value: data.providerLabel),
          if (data.trialEndsAt != null)
            _PlanLine(
                label: 'Fim do teste',
                value: DateFormat('dd/MM/yyyy').format(data.trialEndsAt!)),
          _PlanLine(
              label: 'Usuários',
              value: data.maxUsers == null ? 'Ilimitado' : '${data.maxUsers}'),
          _PlanLine(
            label: 'Projetos/mês',
            value: data.maxProjectsPerMonth == null
                ? 'Ilimitado'
                : '${data.maxProjectsPerMonth}',
          ),
          const Divider(color: AppTheme.border),
          _FeatureLine(label: 'Financeiro', enabled: data.allowFinancial),
          _FeatureLine(label: 'Relatórios', enabled: data.allowReports),
          _FeatureLine(
              label: 'Sincronização em equipe', enabled: data.allowTeamSync),
        ],
      ),
    );
  }
}

class _BillingStatusCard extends StatelessWidget {
  const _BillingStatusCard({required this.repository});

  final SolarProRepository repository;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return FutureBuilder<List<ManualPayment>>(
      future: repository.loadOpenManualPayments(),
      builder: (context, snapshot) {
        final payments = snapshot.data ?? const <ManualPayment>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const NeonCard(
            child: _InfoRow(
              icon: Icons.pix_rounded,
              title: 'Cobranças',
              subtitle: 'Carregando status financeiro...',
              color: AppTheme.primaryBlue,
            ),
          );
        }
        if (payments.isEmpty) {
          return const NeonCard(
            child: _InfoRow(
              icon: Icons.check_circle_outline_rounded,
              title: 'Cobranças',
              subtitle: 'Nenhuma cobrança pendente no momento.',
              color: AppTheme.green,
            ),
          );
        }
        final overdue =
            payments.where((payment) => payment.status == 'overdue').toList();
        final first = overdue.isNotEmpty ? overdue.first : payments.first;
        final color =
            overdue.isNotEmpty ? AppTheme.orange : AppTheme.primaryBlue;
        final status = overdue.isNotEmpty ? 'atrasada' : 'pendente';
        final due = first.dueDate == null
            ? 'sem vencimento'
            : 'vence em ${DateFormat('dd/MM/yyyy').format(first.dueDate!)}';
        return NeonCard(
          child: _InfoRow(
            icon: overdue.isNotEmpty
                ? Icons.warning_amber_rounded
                : Icons.pix_rounded,
            title: 'Cobrança $status',
            subtitle: '${money.format(first.amount)} • $due',
            color: color,
          ),
        );
      },
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            color: enabled ? AppTheme.green : AppTheme.muted,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        const TextStyle(color: AppTheme.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
        child: Icon(icon, color: AppTheme.primaryBlue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.muted)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
