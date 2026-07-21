import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A settings/menu row for the Account hub: a tinted icon square, a title
/// (+ optional subtitle), and a trailing widget (defaults to a chevron).
/// Pass [soon] to badge an unbuilt feature, or [trailing] for a switch/value.
class HubTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool soon;
  final bool destructive;

  const HubTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.soon = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = destructive ? c.loss : (iconColor ?? c.primary);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, size: 20, color: tint),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: destructive ? c.loss : c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(color: c.textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              if (soon) _SoonBadge(color: c.textMuted, border: c.border),
              if (trailing != null) trailing!,
              if (trailing == null && !soon && onTap != null)
                Icon(Icons.chevron_right_rounded, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoonBadge extends StatelessWidget {
  final Color color;
  final Color border;
  const _SoonBadge({required this.color, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: border),
      ),
      child: Text(
        'Soon',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
