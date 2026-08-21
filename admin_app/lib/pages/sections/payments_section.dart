import 'package:flutter/material.dart';

import '../../models/admin_payment.dart';
import '../../widgets/admin_card.dart';
import '../../widgets/tables/payment_table.dart';

class PaymentsSection extends StatelessWidget {
  const PaymentsSection({
    super.key,
    required this.payments,
    required this.onCreatePayment,
    required this.onPaid,
    required this.onCancel,
  });

  final List<AdminPayment> payments;
  final VoidCallback onCreatePayment;
  final ValueChanged<AdminPayment> onPaid;
  final ValueChanged<AdminPayment> onCancel;

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
                final compact = constraints.maxWidth < 520;
                final title = const Text(
                  'Cobranças Pix',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                );
                final button = FilledButton.icon(
                  onPressed: onCreatePayment,
                  icon: const Icon(Icons.pix_rounded),
                  label: const Text('Nova cobrança'),
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
          PaymentTable(payments: payments, onPaid: onPaid, onCancel: onCancel),
        ],
      ),
    );
  }
}
