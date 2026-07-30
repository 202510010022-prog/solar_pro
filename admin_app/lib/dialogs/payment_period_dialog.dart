import 'package:flutter/material.dart';

class PaymentPeriodDialog extends StatefulWidget {
  const PaymentPeriodDialog({super.key});

  @override
  State<PaymentPeriodDialog> createState() => _PaymentPeriodDialogState();
}

class _PaymentPeriodDialogState extends State<PaymentPeriodDialog> {
  int months = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar pagamento'),
      content: DropdownButtonFormField<int>(
        initialValue: months,
        decoration: const InputDecoration(labelText: 'Período liberado'),
        items: const [
          DropdownMenuItem(value: 1, child: Text('1 mês')),
          DropdownMenuItem(value: 3, child: Text('3 meses')),
          DropdownMenuItem(value: 6, child: Text('6 meses')),
          DropdownMenuItem(value: 12, child: Text('12 meses')),
        ],
        onChanged: (value) => setState(() => months = value ?? 1),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, months),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
