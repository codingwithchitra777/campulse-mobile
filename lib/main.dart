import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/dashboard_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/add_trade_screen.dart';
import 'screens/history_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/locale_controller.dart';
import 'theme/theme_controller.dart';
import 'widgets/app_drawer.dart';

void main() {
  runApp(const CamPulseApp());
}

class CamPulseApp extends StatefulWidget {
  const CamPulseApp({super.key});

  @override
  State<CamPulseApp> createState() => _CamPulseAppState();
}

class _CamPulseAppState extends State<CamPulseApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      AuthService.instance.restoreSession(),
      ThemeController.instance.restore(),
      LocaleController.instance.restore(),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeController.instance,
        LocaleController.instance,
      ]),
      builder: (context, _) {
        return MaterialApp(
          title: 'CamPulse',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeController.instance.mode,
          locale: LocaleController.instance.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: _ready
              ? const MainLayout()
              : Builder(
                  builder: (context) => Scaffold(
                    body: const Center(child: CircularProgressIndicator()),
                  ),
                ),
        );
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void _go(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<GoogleProfile?>(
      valueListenable: AuthService.instance.profile,
      builder: (context, profile, _) {
        final isGuest = profile == null;
        // Key screens by the active user so a login/logout recreates them and
        // their initState re-fetches — no manual GlobalKey.setState plumbing.
        final userKey = profile?.userId ?? 'guest';

        Widget guarded(Widget page) => isGuest ? const LoginScreen() : page;

        final screens = <Widget>[
          DashboardScreen(key: ValueKey('dash_$userKey'), onRefresh: () {}, onNavigate: _go),
          guarded(PortfolioScreen(key: ValueKey('port_$userKey'))),
          guarded(AddTradeScreen(
            key: ValueKey('add_$userKey'),
            onTradeAdded: () => _go(0),
          )),
          guarded(WatchlistScreen(key: ValueKey('watch_$userKey'), embedded: true)),
          guarded(HistoryScreen(key: ValueKey('hist_$userKey'))),
        ];

        final titles = [
          l10n.titleDashboard,
          l10n.titlePortfolio,
          l10n.titleAddTrade,
          'Watchlist',
          'History',
        ];

        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            titleSpacing: 0,
            title: Text(titles[_currentIndex]),
            leading: Builder(
              builder: (context) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Center(child: ProfileAvatar(profile: profile, radius: 18)),
              ),
            ),
          ),
          body: Stack(
            children: [
              IndexedStack(index: _currentIndex, children: screens),
              _FloatingNav(
                currentIndex: _currentIndex,
                onTap: _go,
                dashboardLabel: l10n.navDashboard,
                portfolioLabel: l10n.navPortfolio,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The glassy floating bottom nav: Dashboard · Portfolio · [+ Record] · History
/// · Account. Colors come from the active theme so it works in light & dark.
class _FloatingNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String dashboardLabel;
  final String portfolioLabel;

  const _FloatingNav({
    required this.currentIndex,
    required this.onTap,
    required this.dashboardLabel,
    required this.portfolioLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: AppSpacing.lg,
      child: SafeArea(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: c.navBar.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 2),
                border: Border.all(color: c.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: dashboardLabel,
                    selected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.pie_chart_outline_rounded,
                    activeIcon: Icons.pie_chart_rounded,
                    label: portfolioLabel,
                    selected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _RecordFab(onTap: () => onTap(2)),
                  _NavItem(
                    icon: Icons.star_outline_rounded,
                    activeIcon: Icons.star_rounded,
                    label: 'Watchlist',
                    selected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                  _NavItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long_rounded,
                    label: 'History',
                    selected: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.primary : c.textMuted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordFab extends StatelessWidget {
  final VoidCallback onTap;
  const _RecordFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: c.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(Icons.add_rounded, color: c.onPrimary, size: 28),
      ),
    );
  }
}
