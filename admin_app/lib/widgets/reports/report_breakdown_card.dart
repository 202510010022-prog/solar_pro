import 'package:flutter/material.dart';

import '../../app/admin_theme.dart';
import '../../models/commercial_report_data.dart';

class ReportBreakdownCard extends StatelessWidget {
  const ReportBreakdownCard({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<ReportBreakdownItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, item) => sum + item.value);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x66071126),
        border: Border.all(color: AdminTheme.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AdminTheme.cyan),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'Sem dados suficientes.',
              style: TextStyle(color: AdminTheme.muted),
            )
          else
            ...items.map((item) {
              final percent = total == 0 ? 0.0 : item.value / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(color: AdminTheme.muted),
                          ),
                        ),
                        Text(
                          '${item.value}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: percent.clamp(0, 1),
                        backgroundColor: AdminTheme.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AdminTheme.cyan,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
