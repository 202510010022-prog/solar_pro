import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/project_status.dart';
import '../theme/app_theme.dart';
import 'neon_card.dart';

class ProjectStatusChart extends StatelessWidget {
  const ProjectStatusChart({super.key, required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ProjectStatusItem(
        label: ProjectStatus.negotiating.dashboardLabel,
        value: _count(ProjectStatus.negotiating),
        color: AppTheme.orange,
        icon: Icons.forum_rounded,
      ),
      _ProjectStatusItem(
        label: ProjectStatus.approved.dashboardLabel,
        value: _count(ProjectStatus.approved),
        color: AppTheme.green,
        icon: Icons.check_circle_rounded,
      ),
      _ProjectStatusItem(
        label: ProjectStatus.installing.dashboardLabel,
        value: _count(ProjectStatus.installing),
        color: AppTheme.primaryBlue,
        icon: Icons.engineering_rounded,
      ),
      _ProjectStatusItem(
        label: ProjectStatus.completed.dashboardLabel,
        value: _count(ProjectStatus.completed),
        color: AppTheme.neonBlue,
        icon: Icons.verified_rounded,
      ),
      _ProjectStatusItem(
        label: ProjectStatus.rejected.dashboardLabel,
        value: _count(ProjectStatus.rejected),
        color: AppTheme.purple,
        icon: Icons.cancel_rounded,
      ),
    ];
    final total = items.fold<int>(0, (sum, item) => sum + item.value);

    return NeonCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status dos projetos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.text,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Distribuição atual da carteira',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: AppTheme.muted, fontSize: 11),
                    ),
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((item) => _StatusChip(item: item)).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: CustomPaint(
              painter: _ProjectStatusChartPainter(items: items),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  int _count(ProjectStatus status) {
    return projects.where((project) => status.matches(project.status)).length;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.item});

  final _ProjectStatusItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 17, color: item.color),
          const SizedBox(width: 7),
          Text(
            '${item.label}: ',
            style: const TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            '${item.value}',
            style: TextStyle(
              color: item.color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectStatusItem {
  const _ProjectStatusItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;
}

class _ProjectStatusChartPainter extends CustomPainter {
  const _ProjectStatusChartPainter({required this.items});

  final List<_ProjectStatusItem> items;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 28.0;
    const right = 10.0;
    const top = 10.0;
    const bottom = 48.0;
    final chart =
        Rect.fromLTRB(left, top, size.width - right, size.height - bottom);
    if (chart.width <= 0 || chart.height <= 0) return;

    final maxValue = math.max(
      1,
      items.fold<int>(0, (max, item) => math.max(max, item.value)),
    );
    final scaleMax = math.max(4, maxValue).toDouble();
    const labelStyle = TextStyle(
      color: AppTheme.muted,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    final gridPaint = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.75)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = chart.bottom - chart.height / 4 * i;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final value = (scaleMax / 4 * i).round().toString();
      _drawText(canvas, value, Offset(2, y - 7), labelStyle, maxWidth: 22);
    }

    final slotWidth = chart.width / items.length;
    final barWidth = math.min(42.0, math.max(14.0, slotWidth * 0.34));

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final centerX = chart.left + slotWidth * i + slotWidth / 2;
      final barHeight = item.value / scaleMax * chart.height;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          chart.bottom - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(14),
      );

      final shadowPaint = Paint()
        ..color = item.color.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(barRect.shift(const Offset(0, 4)), shadowPaint);

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            item.color,
            item.color.withValues(alpha: 0.72),
          ],
        ).createShader(barRect.outerRect);
      canvas.drawRRect(barRect, fillPaint);

      _drawCenteredText(
        canvas,
        '${item.value}',
        centerX: centerX,
        top: chart.bottom - barHeight - 24,
        width: slotWidth,
        style: TextStyle(
          color: item.color,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      );
      _drawCenteredText(
        canvas,
        item.label,
        centerX: centerX,
        top: chart.bottom + 12,
        width: slotWidth - 8,
        style: labelStyle,
      );
    }
  }

  void _drawCenteredText(
    Canvas canvas,
    String text, {
    required double centerX,
    required double top,
    required double width,
    required TextStyle style,
  }) {
    final safeWidth = math.max(18.0, width);
    _drawText(
      canvas,
      text,
      Offset(centerX - safeWidth / 2, top),
      style,
      maxWidth: safeWidth,
      align: TextAlign.center,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    double maxWidth = 80,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: ui.TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ProjectStatusChartPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}
