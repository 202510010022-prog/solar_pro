import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const rejectionReasons = [
  'Cliente sem orçamento/condição financeira',
  'Cliente desistiu',
  'Cliente escolheu concorrente',
  'Telhado/estrutura inadequada',
  'Sem contato/não retornou',
  'Preço acima do esperado',
  'Outro (especificar)',
];

Future<String?> showRejectionReasonDialog(
  BuildContext context, {
  String? initialReason,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RejectionReasonDialog(initialReason: initialReason),
  );
}

class RejectionReasonDialog extends StatefulWidget {
  const RejectionReasonDialog({super.key, this.initialReason});

  final String? initialReason;

  @override
  State<RejectionReasonDialog> createState() => _RejectionReasonDialogState();
}

class _RejectionReasonDialogState extends State<RejectionReasonDialog> {
  late String? selectedReason = _initialSelectedReason();
  late final TextEditingController otherController =
      TextEditingController(text: _initialOtherReason());

  bool get isOther => selectedReason == rejectionReasons.last;

  bool get canConfirm {
    if (selectedReason == null) return false;
    if (!isOther) return true;
    return otherController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    otherController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Motivo da não aprovação'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecione um motivo para registrar o projeto como não aprovado.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                items: rejectionReasons
                    .map(
                      (reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedReason = value),
                decoration: const InputDecoration(labelText: 'Motivo'),
              ),
              if (isOther) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: otherController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Especifique o motivo',
                    hintText: 'Descreva brevemente o motivo',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canConfirm
              ? () => Navigator.pop(context, _normalizedReason())
              : null,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  String? _initialSelectedReason() {
    final reason = widget.initialReason?.trim() ?? '';
    if (reason.isEmpty) return null;
    if (rejectionReasons.contains(reason)) return reason;
    if (reason.startsWith('Outro: ')) return rejectionReasons.last;
    return rejectionReasons.last;
  }

  String _initialOtherReason() {
    final reason = widget.initialReason?.trim() ?? '';
    if (reason.startsWith('Outro: ')) return reason.substring(7).trim();
    if (reason.isEmpty || rejectionReasons.contains(reason)) return '';
    return reason;
  }

  String _normalizedReason() {
    if (isOther) return 'Outro: ${otherController.text.trim()}';
    return selectedReason ?? '';
  }
}
