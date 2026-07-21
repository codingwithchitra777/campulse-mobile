import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The standard surface for grouped content: rounded, soft-shadowed,
/// theme-aware. Prefer this over ad-hoc `Container`/`Card` so every panel
/// looks the same. Set [onTap] to make it tappable (adds ripple).
///
/// Gradient cards get the ByteTown "credit-card" treatment automatically: a
/// coloured glow shadow and a glossy highlight sweep, no border.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
    this.gradient,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(AppSpacing.radiusLg);
    final isGradient = gradient != null;

    // Gradient heroes float on a coloured glow; plain cards use a soft shadow.
    final shadows = !elevated
        ? null
        : isGradient
            ? [BoxShadow(color: c.primary.withValues(alpha: 0.38), blurRadius: 28, offset: const Offset(0, 14))]
            : c.softShadow;

    Widget content = Padding(padding: padding, child: child);

    // Glossy highlight on gradient cards (subtle diagonal sheen, top-right).
    if (isGradient) {
      content = Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          content,
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isGradient ? null : (color ?? c.surface),
        gradient: gradient,
        borderRadius: radius,
        border: isGradient ? null : Border.all(color: c.border),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: content,
          ),
        ),
      ),
    );
  }
}
