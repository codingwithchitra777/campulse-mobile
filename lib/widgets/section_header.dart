import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A row heading for a group of content: a bold title on the left and an
/// optional trailing action (e.g. "See all"). Keeps vertical rhythm consistent
/// across screens.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: TextStyle(
                      color: c.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: c.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
