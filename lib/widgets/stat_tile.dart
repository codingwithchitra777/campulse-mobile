import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

/// A compact metric tile: a muted label above a prominent value, with an
/// optional leading icon and an optional value color (e.g. profit/loss).
/// Designed to sit in a row/grid of quick stats on the dashboard.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final String? sublabel;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: c.textMuted),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            Text(
              sublabel!,
              style: TextStyle(color: c.textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
