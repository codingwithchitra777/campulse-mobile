import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shown for hub features that aren't built on mobile yet. Keeps the feature
/// visible in the IA (so users know it's coming) without faking functionality.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    this.message = 'This feature is coming to mobile soon.',
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: c.primary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textMuted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: c.border),
                ),
                child: Text(
                  'Available on the web app today',
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
