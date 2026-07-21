import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/dashboard_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/add_trade_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/account_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'dart:ui';


void main() {
  runApp(const CsxTradingJournalApp());
}

class CsxTradingJournalApp extends StatefulWidget {
  const CsxTradingJournalApp({super.key});

  @override
  State<CsxTradingJournalApp> createState() => _CsxTradingJournalAppState();
}

class _CsxTradingJournalAppState extends State<CsxTradingJournalApp> {
  Locale _locale = const Locale('en');
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    AuthService.instance.restoreSession().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CamPulse',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080C14),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
      ),
      home: _ready
          ? MainLayout(currentLocale: _locale, onLocaleChanged: _setLocale)
          : const Scaffold(
              backgroundColor: Color(0xFF080C14),
              body: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

class MainLayout extends StatefulWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;

  const MainLayout({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // Refresh trigger keys, so the previously-loaded screens reload with the
  // newly signed-in (or signed-out) user's data.
  final GlobalKey<State> _dashKey = GlobalKey();
  final GlobalKey<State> _portKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    AuthService.instance.profile.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.instance.profile.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    _dashKey.currentState?.setState(() {});
    _portKey.currentState?.setState(() {});
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<GoogleProfile?>(
      valueListenable: AuthService.instance.profile,
      builder: (context, googleProfile, _) {
        final isGuest = googleProfile == null;

        final List<Widget> screens = [
          DashboardScreen(
            key: _dashKey,
            onRefresh: () {
              setState(() {});
            },
          ),
          isGuest ? const LoginScreen() : PortfolioScreen(key: _portKey),
          isGuest
              ? const LoginScreen()
              : AddTradeScreen(
                  onTradeAdded: () {
                    setState(() {});
                  },
                ),
          isGuest ? const LoginScreen() : const WatchlistScreen(),
          isGuest ? const LoginScreen() : const AccountScreen(),
        ];

        final titles = [
          l10n.titleDashboard,
          l10n.titlePortfolio,
          l10n.titleAddTrade,
          'Watchlist',
          'Account',
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(titles[_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            actions: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: widget.currentLocale.languageCode,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      items: [
                        DropdownMenuItem<String>(value: 'en', child: Text(l10n.languageEnglish)),
                        DropdownMenuItem<String>(value: 'km', child: Text(l10n.languageKhmer)),
                      ],
                      onChanged: (code) {
                        if (code != null) widget.onLocaleChanged(Locale(code));
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: isGuest
                      ? const SizedBox.shrink() // Removed "Guest" label entirely
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  googleProfile.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => AuthService.instance.logout(),
                                child: Tooltip(
                                  message: l10n.logout,
                                  child: const Icon(Icons.logout, size: 16, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: Container(
                    height: 66,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D121E).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNavItem(icon: Icons.dashboard_outlined, label: l10n.navDashboard, index: 0),
                            _buildNavItem(icon: Icons.business_center_outlined, label: l10n.navPortfolio, index: 1),
                            
                            // Center Record FAB
                            GestureDetector(
                              onTap: () => _onTabTapped(2),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 28),
                              ),
                            ),
                            
                            _buildNavItem(icon: Icons.star_border, label: 'Watchlist', index: 3),
                            _buildNavItem(icon: Icons.person_outline, label: 'Account', index: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : const Color(0xFF94A3B8),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}