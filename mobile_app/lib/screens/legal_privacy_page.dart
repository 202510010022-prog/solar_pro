import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/legal_config.dart';
import '../models/app_profile.dart';
import '../theme/app_theme.dart';
import '../utils/legal_launcher.dart';
import '../widgets/neon_card.dart';

class LegalPrivacyPage extends StatelessWidget {
  const LegalPrivacyPage({super.key, required this.profile});

  final AppProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal e Privacidade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Central legal do Solar Pro',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Acesse políticas, termos, suporte e solicite análise de exclusão da sua conta.',
            style: TextStyle(color: AppTheme.muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          NeonCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _LegalTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de Privacidade',
                  subtitle: 'Como os dados são tratados no Solar Pro',
                  onTap: () => _openUrl(context, LegalConfig.privacyUrl),
                ),
                const Divider(height: 1, color: AppTheme.border),
                _LegalTile(
                  icon: Icons.description_outlined,
                  title: 'Termos de Uso',
                  subtitle: 'Regras de uso do aplicativo',
                  onTap: () => _openUrl(context, LegalConfig.termsUrl),
                ),
                const Divider(height: 1, color: AppTheme.border),
                _LegalTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Excluir minha conta e dados',
                  subtitle: 'Solicite análise de exclusão conforme a LGPD',
                  onTap: () => _showDeletionDialog(context),
                ),
                const Divider(height: 1, color: AppTheme.border),
                _LegalTile(
                  icon: Icons.support_agent_rounded,
                  title: 'Ajuda e suporte',
                  subtitle: 'Contato para dúvidas, privacidade e suporte',
                  onTap: () => _openUrl(context, LegalConfig.supportUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const NeonCard(
            child: Text(
              'A solicitação de exclusão não apaga dados automaticamente. Ela abre um pedido de análise para confirmar identidade, vínculo com a empresa e eventuais retenções legais ou operacionais aplicáveis.',
              style: TextStyle(color: AppTheme.muted, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final opened = await openExternalUri(Uri.parse(url));
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir este link.')),
      );
    }
  }

  Future<void> _showDeletionDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Solicitar exclusão da conta'),
          content: const SingleChildScrollView(
            child: Text(
              'Você pode solicitar a análise de exclusão da sua conta Solar Pro. '
              'Alguns registros empresariais, fiscais, contratuais, de segurança '
              'ou legalmente necessários podem precisar ser preservados quando aplicável.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _openUrl(context, LegalConfig.dataDeletionUrl);
              },
              child: const Text('Ver política de exclusão'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _sendDeletionEmail(context);
              },
              child: const Text('Enviar solicitação por e-mail'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendDeletionEmail(BuildContext context) async {
    final mailto = Uri(
      scheme: 'mailto',
      path: LegalConfig.supportEmail,
      queryParameters: {
        'subject': 'Solicitação de exclusão de conta - Solar Pro',
        'body': _deletionEmailBody(profile),
      },
    );
    final opened = await openExternalUri(mailto);
    if (!opened && context.mounted) {
      _showEmailFallback(context);
    }
  }

  Future<void> _showEmailFallback(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enviar solicitação por e-mail'),
          content: const Text(
            'Não foi possível abrir o aplicativo de e-mail.\n\n'
            'Envie sua solicitação para:\n'
            '${LegalConfig.supportEmail}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(
                  const ClipboardData(text: LegalConfig.supportEmail),
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('E-mail copiado.')),
                );
              },
              child: const Text('Copiar e-mail'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}

String deletionRequestEmailBody(AppProfile? profile) {
  final name = profile?.name.trim();
  final email = profile?.email.trim();
  final companyId = profile?.companyId.trim();
  return '''
Olá,

solicito a análise da exclusão da minha conta Solar Pro.

Nome: ${name?.isNotEmpty == true ? name : 'Não informado'}
E-mail: ${email?.isNotEmpty == true ? email : 'Não informado'}
Empresa/Company ID: ${companyId?.isNotEmpty == true ? companyId : 'Não informado'}

Entendo que alguns registros empresariais ou legalmente necessários
podem precisar ser preservados quando aplicável.

Obrigado.
''';
}

String _deletionEmailBody(AppProfile? profile) {
  return deletionRequestEmailBody(profile);
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppTheme.green.withValues(alpha: 0.10),
          child: Icon(icon, color: AppTheme.green),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.open_in_new_rounded),
        onTap: onTap,
      ),
    );
  }
}
