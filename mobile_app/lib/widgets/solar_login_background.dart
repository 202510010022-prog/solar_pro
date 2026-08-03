import 'dart:math' as math;

import 'package:flutter/material.dart';

class SolarLoginBackground extends StatelessWidget {
  const SolarLoginBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFCF4),
                Color(0xFFF7F9FC),
                Color(0xFFEAF5FF),
              ],
              stops: [0, 0.56, 1],
            ),
          ),
        ),
        const IgnorePointer(
          child: CustomPaint(painter: _SolarLoginBackgroundPainter()),
        ),
        child,
      ],
    );
  }
}

class _SolarLoginBackgroundPainter extends CustomPainter {
  const _SolarLoginBackgroundPainter();

  static const solarYellow = Color(0xFFFDD22A);
  static const solarPurple = Color(0xFF2300AE);
  static const lightPurple = Color(0xFFE9E4FF);

  @override
  void paint(Canvas canvas, Size size) {
    _paintSunGlow(canvas, size);
    _paintClouds(canvas, size);
    _paintTopWaves(canvas, size);
    _paintBottomWaves(canvas, size);
  }

  void _paintSunGlow(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.14, size.height * 0.075);
    final radius = size.shortestSide * 0.085;
    canvas.drawCircle(
      center,
      radius * 3.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            solarYellow.withValues(alpha: 0.30),
            solarYellow.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius * 3.8),
        ),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.white.withValues(alpha: 0.86),
    );
  }

  void _paintClouds(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    final cloudCenters = [
      Offset(size.width * 0.70, size.height * 0.10),
      Offset(size.width * 0.96, size.height * 0.17),
    ];
    for (final center in cloudCenters) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: size.width * 0.22,
          height: size.height * 0.055,
        ),
        paint,
      );
      canvas.drawCircle(center.translate(-28, -10), 28, paint);
      canvas.drawCircle(center.translate(24, -16), 34, paint);
    }
  }

  void _paintTopWaves(Canvas canvas, Size size) {
    _paintWaveCluster(
      canvas,
      size,
      origin: Offset(size.width * 0.44, -size.height * 0.025),
      width: size.width * 0.72,
      height: size.height * 0.13,
      color: solarYellow,
      phase: 0.45,
      strokeWidth: 0.85,
      opacity: 0.25,
    );
  }

  void _paintBottomWaves(Canvas canvas, Size size) {
    _paintWaveCluster(
      canvas,
      size,
      origin: Offset(-size.width * 0.18, size.height * 0.84),
      width: size.width * 1.18,
      height: size.height * 0.16,
      color: solarPurple,
      phase: 1.35,
      strokeWidth: 0.85,
      opacity: 0.14,
    );
    _paintWaveCluster(
      canvas,
      size,
      origin: Offset(-size.width * 0.05, size.height * 0.89),
      width: size.width * 1.10,
      height: size.height * 0.12,
      color: lightPurple,
      phase: 2.2,
      strokeWidth: 0.75,
      opacity: 0.22,
    );
  }

  void _paintWaveCluster(
    Canvas canvas,
    Size size, {
    required Offset origin,
    required double width,
    required double height,
    required Color color,
    required double phase,
    required double strokeWidth,
    required double opacity,
  }) {
    const count = 14;
    for (var i = 0; i < count; i++) {
      final offset = i / (count - 1);
      final path = Path();
      for (var step = 0; step <= 100; step++) {
        final progress = step / 100;
        final x = origin.dx + width * progress;
        final wave = math.sin(progress * math.pi * 2.05 + phase);
        final y = origin.dy +
            offset * height +
            wave * height * 0.25 +
            math.sin(progress * math.pi * 4.2 + phase) * height * 0.045;
        if (step == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: opacity * (0.55 + offset * 0.45)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SolarLoginBackgroundPainter oldDelegate) {
    return false;
  }
}
