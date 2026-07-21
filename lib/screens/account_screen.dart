import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/locale_controller.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_card.dart';
import '../widgets/hub_tile.dart';
import '../widgets/section_header.dart';
import 'placeholder_screen.dart';

/// The Account hub — the home for every secondary feature. A profile header,
/// a Tools list (features that live on the web today, coming to mobile), and
/// Settings (appearance, language, connected accounts) + sign out.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _openPlaceholder(BuildContext context, String title, IconData icon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceholderScreen(title: title, icon: icon),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(l10n.logout, style: TextStyle(color: c.textPrimary)),
        content: Text(
          'You will be signed out of this device.',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: c.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.loss),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (ok == true) AuthService.instance.logout();
  }

  void _pickLanguage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) {
        Widget option(String code, String label) {
          final selected = LocaleController.instance.code == code;
          return ListTile(
            title: Text(label, style: TextStyle(color: c.textPrimary)),
            trailing: selected ? Icon(Icons.check_rounded, color: c.primary) : null,
            onTap: () {
              LocaleController.instance.setCode(code);
              Navigator.pop(ctx);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              option('en', l10n.languageEnglish),
              option('km', l10n.languageKhmer),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final profile = AuthService.instance.profile.value;
    final name = profile?.name ?? 'Guest';
    final email = profile?.email ?? '';
    final initials = _initials(name);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        110, // clear the floating bottom nav
      ),
      children: [
        // ── Profile header ────────────────────────────────────────────
        AppCard(
          gradient: c.primaryGradient,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: const Text(
                        'CamPulse member',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Tools ─────────────────────────────────────────────────────
        const SectionHeader(title: 'Tools'),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              HubTile(
                icon: Icons.query_stats_rounded,
                iconColor: c.primary,
                title: 'Analytics',
                subtitle: 'Win rate, hold time, per-currency stats',
                soon: true,
                onTap: () => _openPlaceholder(context, 'Analytics', Icons.query_stats_rounded),
              ),
              _divider(c),
              HubTile(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Watchlist',
                subtitle: 'Track symbols you don\'t own yet',
                soon: true,
                onTap: () => _openPlaceholder(context, 'Watchlist', Icons.star_rounded),
              ),
              _divider(c),
              HubTile(
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFFEF4444),
                title: 'Price Alerts',
                subtitle: 'Get pinged on Telegram at your target',
                soon: true,
                onTap: () => _openPlaceholder(context, 'Price Alerts', Icons.notifications_active_rounded),
              ),
              _divider(c),
              HubTile(
                icon: Icons.edit_note_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Journal',
                subtitle: 'Notes & tags on your trades',
                soon: true,
                onTap: () => _openPlaceholder(context, 'Journal', Icons.edit_note_rounded),
              ),
              _divider(c),
              HubTile(
                icon: Icons.psychology_rounded,
                iconColor: const Color(0xFF06B6D4),
                title: 'AI Coach',
                subtitle: 'Descriptive read of your patterns',
                soon: true,
                onTap: () => _openPlaceholder(context, 'AI Coach', Icons.psychology_rounded),
              ),
              _divider(c),
              HubTile(
                icon: Icons.handshake_rounded,
                iconColor: c.profit,
                title: 'Loans',
                subtitle: 'Personal money lent & borrowed',
                soon: true,
                onTap: () => _openPlaceholder(context, 'Loans', Icons.handshake_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Settings ──────────────────────────────────────────────────
        const SectionHeader(title: 'Settings'),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              ListenableBuilder(
                listenable: ThemeController.instance,
                builder: (context, _) => HubTile(
                  icon: ThemeController.instance.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: 'Appearance',
                  subtitle: ThemeController.instance.isDark ? 'Dark' : 'Light',
                  trailing: Switch(
                    value: ThemeController.instance.isDark,
                    activeThumbColor: c.primary,
                    onChanged: (v) => ThemeController.instance.setDark(v),
                  ),
                ),
              ),
              _divider(c),
              ListenableBuilder(
                listenable: LocaleController.instance,
                builder: (context, _) => HubTile(
                  icon: Icons.translate_rounded,
                  title: 'Language',
                  subtitle: LocaleController.instance.code == 'km'
                      ? l10n.languageKhmer
                      : l10n.languageEnglish,
                  onTap: () => _pickLanguage(context),
                ),
              ),
              _divider(c),
              HubTile(
                icon: Icons.link_rounded,
                title: 'Connected accounts',
                subtitle: 'Link Telegram for alerts & the bot',
                soon: true,
                onTap: () => _openPlaceholder(context, 'Connected accounts', Icons.link_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Sign out ──────────────────────────────────────────────────
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: HubTile(
            icon: Icons.logout_rounded,
            title: l10n.logout,
            destructive: true,
            onTap: () => _confirmSignOut(context),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            'CamPulse • v1.0',
            style: TextStyle(color: c.textMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _divider(AppColors c) => Divider(
        height: 1,
        thickness: 1,
        indent: AppSpacing.md + 38 + AppSpacing.md,
        color: c.border.withValues(alpha: 0.6),
      );

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}
