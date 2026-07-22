import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/alerts_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/loans_screen.dart';
import '../screens/placeholder_screen.dart';
import '../screens/watchlist_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/locale_controller.dart';
import '../theme/theme_controller.dart';
import 'app_card.dart';
import 'hub_tile.dart';
import 'section_header.dart';

/// The slide-out "hamburger" menu. Opened from the top-left profile avatar,
/// it hosts the profile header, every secondary tool, settings, and sign-out —
/// the home the Account tab used to be.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.pop(context); // close the drawer first
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _pushPlaceholder(BuildContext context, String title, IconData icon) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceholderScreen(title: title, icon: icon)),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    Navigator.pop(context); // close the drawer
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(l10n.logout, style: TextStyle(color: c.textPrimary)),
        content: Text('You will be signed out of this device.',
            style: TextStyle(color: c.textSecondary)),
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
                width: 40, height: 4,
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
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

    return Drawer(
      backgroundColor: c.background,
      width: MediaQuery.of(context).size.width * 0.86,
      child: ValueListenableBuilder<GoogleProfile?>(
        valueListenable: AuthService.instance.profile,
        builder: (context, profile, _) {
          final isGuest = profile == null;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
              children: [
                _profileHeader(context, profile),
                const SizedBox(height: AppSpacing.xl),

                // ── Tools ──────────────────────────────────────────────
                const SectionHeader(title: 'Tools'),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      HubTile(
                        icon: Icons.query_stats_rounded,
                        iconColor: c.primary,
                        title: 'Analytics',
                        subtitle: 'Win rate, P/L split, activity stats',
                        onTap: () => _push(context, const AnalyticsScreen()),
                      ),
                      _divider(c),
                      HubTile(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'Watchlist',
                        subtitle: 'Track symbols you don\'t own yet',
                        onTap: () => _push(context, const WatchlistScreen()),
                      ),
                      _divider(c),
                      HubTile(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFEF4444),
                        title: 'Price Alerts',
                        subtitle: 'Get pinged on Telegram at your target',
                        onTap: () => _push(context, const AlertsScreen()),
                      ),
                      _divider(c),
                      HubTile(
                        icon: Icons.handshake_rounded,
                        iconColor: c.profit,
                        title: 'Loans',
                        subtitle: 'Personal money lent & borrowed',
                        onTap: () => _push(context, const LoansScreen()),
                      ),
                      _divider(c),
                      HubTile(
                        icon: Icons.edit_note_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'Journal',
                        subtitle: 'Notes & tags on your trades',
                        soon: true,
                        onTap: () => _pushPlaceholder(context, 'Journal', Icons.edit_note_rounded),
                      ),
                      _divider(c),
                      HubTile(
                        icon: Icons.psychology_rounded,
                        iconColor: const Color(0xFF06B6D4),
                        title: 'AI Coach',
                        subtitle: 'Descriptive read of your patterns',
                        soon: true,
                        onTap: () => _pushPlaceholder(context, 'AI Coach', Icons.psychology_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Settings ───────────────────────────────────────────
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
                        onTap: () => _pushPlaceholder(context, 'Connected accounts', Icons.link_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (!isGuest)
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
                  child: Text('CamPulse • v1.0', style: TextStyle(color: c.textMuted, fontSize: 12)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileHeader(BuildContext context, GoogleProfile? profile) {
    final c = context.colors;
    final name = profile?.name ?? 'Guest';
    final email = profile?.email ?? 'Not signed in';
    final isGuest = profile == null;

    return AppCard(
      gradient: c.primaryGradient,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          ProfileAvatar(profile: profile, radius: 30, onGradient: true),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(email,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(isGuest ? 'Guest' : 'CamPulse member',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppColors c) => Divider(
        height: 1,
        thickness: 1,
        indent: AppSpacing.md + 38 + AppSpacing.md,
        color: c.border.withValues(alpha: 0.6),
      );
}

/// A circular profile avatar: the Google account photo when available, else the
/// initials on a translucent disc. Reused by the app-bar button and the drawer
/// header ([onGradient] tunes the fallback for the violet header card).
class ProfileAvatar extends StatelessWidget {
  final GoogleProfile? profile;
  final double radius;
  final bool onGradient;

  const ProfileAvatar({super.key, required this.profile, this.radius = 18, this.onGradient = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final photo = profile?.photoUrl;
    final initials = _initials(profile?.name);

    final fallbackBg = onGradient ? Colors.white.withValues(alpha: 0.22) : c.primary.withValues(alpha: 0.16);
    final fallbackFg = onGradient ? Colors.white : c.primary;
    final borderColor = onGradient ? Colors.white.withValues(alpha: 0.4) : c.border;

    Widget fallback() => Container(
          width: radius * 2,
          height: radius * 2,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fallbackBg,
            border: Border.all(color: borderColor),
          ),
          child: profile == null
              ? Icon(Icons.person_rounded, color: fallbackFg, size: radius)
              : Text(initials,
                  style: TextStyle(color: fallbackFg, fontSize: radius * 0.72, fontWeight: FontWeight.w700)),
        );

    if (photo == null || photo.isEmpty) return fallback();

    return ClipOval(
      child: Image.network(
        photo,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => fallback(),
        loadingBuilder: (ctx, child, progress) => progress == null ? child : fallback(),
      ),
    );
  }

  static String _initials(String? name) {
    const titles = {'mr', 'mr.', 'ms', 'ms.', 'mrs', 'mrs.', 'dr', 'dr.', 'miss'};
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty && !titles.contains(p.toLowerCase()))
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}
