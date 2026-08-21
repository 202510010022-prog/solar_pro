import 'package:flutter/material.dart';

import '../../models/admin_message.dart';
import '../../widgets/admin_card.dart';
import '../../widgets/tables/message_table.dart';

class MessagesSection extends StatelessWidget {
  const MessagesSection({
    super.key,
    required this.messages,
    required this.onCreateMessage,
  });

  final List<AdminMessage> messages;
  final VoidCallback onCreateMessage;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 560;
                final title = const Text(
                  'Mensagens e comunicados',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                );
                final button = FilledButton.icon(
                  onPressed: onCreateMessage,
                  icon: const Icon(Icons.campaign_rounded),
                  label: const Text('Novo comunicado'),
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 12), button],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    button,
                  ],
                );
              },
            ),
          ),
          MessageTable(messages: messages),
        ],
      ),
    );
  }
}
