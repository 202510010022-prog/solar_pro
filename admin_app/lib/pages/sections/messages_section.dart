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
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mensagens e comunicados',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onCreateMessage,
                  icon: const Icon(Icons.campaign_rounded),
                  label: const Text('Novo comunicado'),
                ),
              ],
            ),
          ),
          MessageTable(messages: messages),
        ],
      ),
    );
  }
}
