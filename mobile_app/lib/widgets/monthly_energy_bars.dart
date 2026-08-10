import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MonthlyEnergyBars extends StatelessWidget {
  const MonthlyEnergyBars({
    super.key,
    required this.month,
    required this.consumption,
    required this.generation,
    required this.balance,
  });

  final String month;
  final double consumption;
  final double generation;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final balanceColor = balance >= 0 ? AppTheme.green : Colors.redAccent;
    final maxValue = [
      consumption,
      generation,
      balance.abs(),
      1.0,
    ].reduce(math.max);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 190;
        final bars = Row(
          children: [
            _EnergyBar(
              label: 'Cons.',
              value: consumption,
              valueLabel: consumption.toStringAsFixed(0),
              maxValue: maxValue,
              color: AppTheme.orange,
              compact: compact,
            ),
            _EnergyBar(
              label: 'Ger.',
              value: generation,
              valueLabel: generation.toStringAsFixed(0),
              maxValue: maxValue,
              color: AppTheme.primaryBlue,
              compact: compact,
            ),
            _EnergyBar(
              label: 'Saldo',
              value: balance.abs(),
              valueLabel: balance.toStringAsFixed(0),
              maxValue: maxValue,
              color: balanceColor,
              compact: compact,
            ),
          ],
        );

        return Container(
          padding: EdgeInsets.fromLTRB(10, compact ? 10 : 12, 10, 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MonthLabel(month: month),
                    const SizedBox(height: 6),
                    bars,
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: 38, child: _MonthLabel(month: month)),
                    const SizedBox(width: 8),
                    Expanded(child: bars),
                  ],
                ),
        );
      },
    );
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel({required this.month});

  final String month;

  @override
  Widget build(BuildContext context) {
    return Text(
      month,
      style: const TextStyle(
        color: AppTheme.text,
        fontWeight: FontWeight.w900,
        fontSize: 13,
      ),
    );
  }
}

class _EnergyBar extends StatelessWidget {
  const _EnergyBar({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.maxValue,
    required this.color,
    required this.compact,
  });

  final String label;
  final double value;
  final String valueLabel;
  final double maxValue;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    final maxBarHeight = compact ? 48.0 : 64.0;
    final barHeight =
        value <= 0 ? 0.0 : (maxBarHeight * ratio).clamp(4.0, maxBarHeight);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: compact ? 54 : 70,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: compact ? 13 : 18,
                height: barHeight,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$valueLabel kWh',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: compact ? 8.4 : 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
