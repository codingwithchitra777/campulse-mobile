import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';

/// A small pill showing a profit/loss value in the semantic profit/loss color
/// with a tinted background. Green for ≥0, red for <0. Pass the raw signed
/// [value] and its [currency]; renders `+1,234៛` / `−$56.00`.
class PnlChip extends StatelessWidget {
  final num value;
  final String? currency;
  final bool showIcon;
  final double fontSize;

  const PnlChip({
    super.key,
    required this.value,
    this.currency,
    this.showIcon = true,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final up = value >= 0;
    final color = up ? c.profit : c.loss;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: fontSize + 1,
              color: color,
            ),
            const SizedBox(width: 2),
          ],
          Text(
            Money.format(value, currency, signed: true),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
