import 'dart:math' as math;
import 'dart:ui' as ui;

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
    final semantics =
        items.map((item) => '${item.label}: ${item.value}').join(', ');

    return Semantics(
      label: 'Distribuição dos projetos. $semantics',
      child: SizedBox(
        height: 232,
        width: double.infinity,
        child: CustomPaint(
          painter: _ProjectDistributionPainter(items: items),
          child: const SizedBox.expand(),
        ),
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

class _ProjectDistributionPainter extends CustomPainter {
  const _ProjectDistributionPainter({required this.items});

  final List<ProjectDistributionBarItem> items;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty || size.width <= 0 || size.height <= 0) return;

    const left = 30.0;
    const right = 12.0;
    const top = 26.0;
    const bottom = 44.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    if (chart.width <= 0 || chart.height <= 0) return;

    final maxValue = items.fold<int>(
      0,
      (currentMax, item) => math.max(currentMax, item.value),
    );
    final maxY = math.max(4, (maxValue * 1.25).ceil()).toDouble();

    final gridPaint = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.86)
      ..strokeWidth = 1;
    const axisStyle = TextStyle(
      color: AppTheme.muted,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    for (var i = 0; i <= 4; i++) {
      final y = chart.bottom - chart.height / 4 * i;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final value = (maxY / 4 * i).round().toString();
      _drawText(
        canvas,
        value,
        Offset(0, y - 7),
        axisStyle,
        maxWidth: 24,
        align: TextAlign.right,
      );
    }

    final slotWidth = chart.width / items.length;
    final barWidth = math.min(28.0, math.max(14.0, slotWidth * 0.34));

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final centerX = chart.left + slotWidth * i + slotWidth / 2;
      final safeValue = math.max(0, item.value);
      final barHeight = safeValue == 0 ? 0.0 : safeValue / maxY * chart.height;
      final barLeft = centerX - barWidth / 2;
      final barTop = chart.bottom - barHeight;

      if (barHeight > 0) {
        final barRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
          topLeft: const Radius.circular(9),
          topRight: const Radius.circular(9),
          bottomLeft: const Radius.circular(3),
          bottomRight: const Radius.circular(3),
        );
        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              item.color,
              item.color.withValues(alpha: 0.72),
            ],
          ).createShader(barRect.outerRect);
        canvas.drawRRect(barRect, barPaint);
      }

      final valueY = math.max(0.0, barTop - 22);
      _drawCenteredText(
        canvas,
        '${item.value}',
        centerX: centerX,
        top: valueY,
        width: slotWidth,
        style: TextStyle(
          color: item.color,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      );

      _drawCenteredText(
        canvas,
        item.label,
        centerX: centerX,
        top: chart.bottom + 10,
        width: slotWidth - 4,
        style: const TextStyle(
          color: AppTheme.muted,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1.08,
        ),
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
  bool shouldRepaint(covariant _ProjectDistributionPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}
