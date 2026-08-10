import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProjectDistributionVerticalChart extends StatelessWidget {
  const ProjectDistributionVerticalChart({
    super.key,
    required this.items,
  });

  final List<ProjectDistributionBarItem> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.where((item) => item.value > 0).toList();
    final total = items.fold<int>(0, (sum, item) => sum + item.value);
    final semantics =
        items.map((item) => '${item.label}: ${item.value}').join(', ');

    return Semantics(
      label: 'Distribuição dos projetos. $semantics',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;
          final chartSize = (constraints.maxWidth * (compact ? 0.56 : 0.46))
              .clamp(150.0, 188.0);

          final chart = SizedBox.square(
            dimension: chartSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(chartSize),
                  painter: _ProjectDistributionDonutPainter(
                    items: visibleItems,
                    total: total,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'projetos',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final legend = _ProjectDistributionLegend(
            items: items,
            total: total,
            compact: compact,
          );

          if (compact) {
            return Column(
              children: [
                Center(child: chart),
                const SizedBox(height: 16),
                legend,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              chart,
              const SizedBox(width: 18),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }
}

class ProjectDistributionBarItem {
  const ProjectDistributionBarItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _ProjectDistributionLegend extends StatelessWidget {
  const _ProjectDistributionLegend({
    required this.items,
    required this.total,
    required this.compact,
  });

  final List<ProjectDistributionBarItem> items;
  final int total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final children = items.map((item) {
      final percent = total == 0 ? 0.0 : item.value / total * 100;
      return _ProjectDistributionLegendItem(
        item: item,
        percent: percent,
      );
    }).toList();

    if (compact) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: children
            .map(
              (child) => SizedBox(
                width: 142,
                child: child,
              ),
            )
            .toList(),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children
          .map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: child,
            ),
          )
          .toList(),
    );
  }
}

class _ProjectDistributionLegendItem extends StatelessWidget {
  const _ProjectDistributionLegendItem({
    required this.item,
    required this.percent,
  });

  final ProjectDistributionBarItem item;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${item.value}',
          style: TextStyle(
            color: item.color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '${percent.round()}%',
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProjectDistributionDonutPainter extends CustomPainter {
  const _ProjectDistributionDonutPainter({
    required this.items,
    required this.total,
  });

  final List<ProjectDistributionBarItem> items;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final strokeWidth = (side * 0.16).clamp(20.0, 28.0);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side - strokeWidth,
      height: side - strokeWidth,
    );

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.border.withValues(alpha: 0.74);

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);

    if (total <= 0 || items.isEmpty) return;

    var startAngle = -math.pi / 2;
    const gap = 0.035;

    for (final item in items) {
      final rawSweep = math.pi * 2 * item.value / total;
      final sweep = math.max(0.02, rawSweep - gap);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweep,
          colors: [
            item.color.withValues(alpha: 0.78),
            item.color,
          ],
        ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += rawSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectDistributionDonutPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.total != total;
  }
}
