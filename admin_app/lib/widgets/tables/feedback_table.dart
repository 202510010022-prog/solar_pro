import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/admin_theme.dart';
import '../../models/admin_feedback.dart';

class FeedbackTable extends StatelessWidget {
  const FeedbackTable({
    super.key,
    required this.feedbacks,
    required this.onStatusChanged,
  });

  final List<AdminFeedback> feedbacks;
  final void Function(AdminFeedback feedback, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm');
    if (feedbacks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Nenhum chamado encontrado.',
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
          DataColumn(label: Text('Usuário')),
          DataColumn(label: Text('Área')),
          DataColumn(label: Text('Nota')),
          DataColumn(label: Text('Mensagem')),
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Status')),
        ],
        rows: feedbacks.map((feedback) {
          return DataRow(
            cells: [
              DataCell(Text('#${feedback.id}')),
              DataCell(
                SizedBox(
                  width: 180,
                  child: Text(
                    feedback.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 180,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.profileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (feedback.profileEmail.isNotEmpty)
                        Text(
                          feedback.profileEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AdminTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              DataCell(Text(feedback.areaLabel)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < feedback.rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AdminTheme.orange,
                      size: 18,
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 320,
                  child: Text(
                    feedback.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Text(
                  feedback.createdAt == null
                      ? '-'
                      : date.format(feedback.createdAt!),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    initialValue: feedback.status,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('Aberto')),
                      DropdownMenuItem(
                        value: 'reviewing',
                        child: Text('Em análise'),
                      ),
                      DropdownMenuItem(
                        value: 'resolved',
                        child: Text('Resolvido'),
                      ),
                      DropdownMenuItem(
                        value: 'archived',
                        child: Text('Arquivado'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null && value != feedback.status) {
                        onStatusChanged(feedback, value);
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
