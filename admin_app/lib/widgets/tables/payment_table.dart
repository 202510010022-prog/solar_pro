import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/admin_theme.dart';
import '../../models/admin_payment.dart';
import '../status_pills.dart';

class PaymentTable extends StatelessWidget {
  const PaymentTable({
    super.key,
    required this.payments,
    required this.onPaid,
    required this.onCancel,
  });

  final List<AdminPayment> payments;
  final void Function(AdminPayment payment) onPaid;
  final void Function(AdminPayment payment) onCancel;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final date = DateFormat('dd/MM/yyyy');
    if (payments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Nenhuma cobrança encontrada.',
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
          DataColumn(label: Text('Valor')),
          DataColumn(label: Text('Vencimento')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Referência Pix')),
          DataColumn(label: Text('Ações')),
        ],
        rows: payments.map((payment) {
          return DataRow(
            cells: [
              DataCell(Text('#${payment.id}')),
              DataCell(
                SizedBox(
                  width: 230,
                  child: Text(
                    payment.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              DataCell(Text(money.format(payment.amount))),
              DataCell(
                Text(
                  payment.dueDate == null ? '-' : date.format(payment.dueDate!),
                ),
              ),
              DataCell(PaymentStatusPill(status: payment.status)),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(
                    payment.pixReference.isEmpty ? '-' : payment.pixReference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AdminTheme.muted),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: payment.canBePaid
                          ? () => onPaid(payment)
                          : null,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      tooltip: 'Marcar como paga',
                    ),
                    IconButton(
                      onPressed: payment.canBeCanceled
                          ? () => onCancel(payment)
                          : null,
                      icon: const Icon(Icons.cancel_outlined),
                      tooltip: 'Cancelar cobrança',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
