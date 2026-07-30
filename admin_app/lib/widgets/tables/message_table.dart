import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/admin_theme.dart';
import '../../models/admin_message.dart';
import '../status_pills.dart';

class MessageTable extends StatelessWidget {
  const MessageTable({super.key, required this.messages});

  final List<AdminMessage> messages;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm');
    if (messages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Nenhuma mensagem enviada.',
            style: TextStyle(color: AdminTheme.muted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AdminTheme.text,
        ),
        dataTextStyle: const TextStyle(color: AdminTheme.text),
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Empresa')),
          DataColumn(label: Text('Tipo')),
          DataColumn(label: Text('Título')),
          DataColumn(label: Text('Mensagem')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Enviada em')),
          DataColumn(label: Text('Expira em')),
        ],
        rows: messages.map((message) {
          return DataRow(
            cells: [
              DataCell(Text('#${message.id}')),
              DataCell(
                SizedBox(
                  width: 190,
                  child: Text(
                    message.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              DataCell(MessageTypePill(type: message.type)),
              DataCell(
                SizedBox(
                  width: 210,
                  child: Text(
                    message.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 320,
                  child: Text(
                    message.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(message.statusLabel)),
              DataCell(
                Text(
                  message.createdAt == null
                      ? '-'
                      : date.format(message.createdAt!),
                ),
              ),
              DataCell(
                Text(
                  message.expiresAt == null
                      ? '-'
                      : DateFormat('dd/MM/yyyy').format(message.expiresAt!),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
