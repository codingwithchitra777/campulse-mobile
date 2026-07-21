import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A shimmering placeholder block for loading states. Compose several to
/// mimic the shape of the content that's about to appear (far better than a
/// bare spinner). Animates a subtle highlight sweep.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppSpacing.radiusSm,
  });

  /// A full-width card-shaped skeleton.
  const Skeleton.card({super.key, this.height = 120, this.radius = AppSpacing.radiusMd})
      : width = double.infinity;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * t, 0),
              end: Alignment(1 - 2 * t, 0),
              colors: [
                c.surfaceAlt,
                c.border,
                c.surfaceAlt,
              ],
              stops: const [0.3, 0.5, 0.7],
            ),
          ),
        );
      },
    );
  }
}
