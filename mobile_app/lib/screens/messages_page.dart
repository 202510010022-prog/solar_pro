import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_message.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, required this.repository});

  final SolarProRepository repository;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late Future<List<AppMessage>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.loadAppMessages();
  }

  void _reload() {
    setState(() => future = widget.repository.loadAppMessages());
  }

  Future<void> _markRead(AppMessage message) async {
    if (!message.isUnread) return;
    try {
      await widget.repository.markAppMessageRead(message.id);
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível marcar como lida.')),
      );
    }
  }

  Future<void> _archive(AppMessage message) async {
    try {
      await widget.repository.archiveAppMessage(message.id);
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensagem arquivada.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível arquivar agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensagens'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<AppMessage>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EmptyMessages(
              icon: Icons.cloud_off_rounded,
              title: 'Mensagens indisponíveis',
              subtitle: 'Verifique a conexão e tente atualizar novamente.',
              onRefresh: _reload,
            );
          }

          final messages = snapshot.data ?? const <AppMessage>[];
          if (messages.isEmpty) {
            return _EmptyMessages(
              icon: Icons.mark_email_read_outlined,
              title: 'Nada novo por aqui',
              subtitle: 'Avisos, cobranças e atualizações aparecerão aqui.',
              onRefresh: _reload,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final message = messages[index];
                return _MessageCard(
                  message: message,
                  onTap: () => _markRead(message),
                  onArchive: () => _archive(message),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: messages.length,
            ),
          );
        },
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.onTap,
    required this.onArchive,
  });

  final AppMessage message;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(message.type);
    final date = message.createdAt == null
        ? ''
        : DateFormat('dd/MM/yyyy HH:mm').format(message.createdAt!);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: NeonCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(_iconFor(message.type), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: message.isUnread
                                ? FontWeight.w900
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (message.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.typeLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.message,
                    style: const TextStyle(color: AppTheme.muted, height: 1.35),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(date,
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 12)),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'archive') onArchive();
                if (value == 'read') onTap();
              },
              itemBuilder: (_) => [
                if (message.isUnread)
                  const PopupMenuItem(
                    value: 'read',
                    child: Text('Marcar como lida'),
                  ),
                const PopupMenuItem(
                  value: 'archive',
                  child: Text('Arquivar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _colorFor(String type) {
    return switch (type) {
      'billing' => AppTheme.orange,
      'warning' => AppTheme.orange,
      'success' => AppTheme.green,
      _ => AppTheme.primaryBlue,
    };
  }

  static IconData _iconFor(String type) {
    return switch (type) {
      'billing' => Icons.pix_rounded,
      'warning' => Icons.warning_amber_rounded,
      'success' => Icons.check_circle_outline_rounded,
      _ => Icons.notifications_none_rounded,
    };
  }
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: NeonCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.green.withValues(alpha: 0.12),
                child: Icon(icon, color: AppTheme.green, size: 30),
              ),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
