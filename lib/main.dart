import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/dashboard_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/add_trade_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

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
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0F172A),
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
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
  final GlobalKey<State> _histKey = GlobalKey();

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
    _histKey.currentState?.setState(() {});
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
          isGuest ? const LoginScreen() : HistoryScreen(key: _histKey),
        ];

        final titles = [
          l10n.titleDashboard,
          l10n.titlePortfolio,
          l10n.titleAddTrade,
          l10n.titleTradeLedger,
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
                      ? Text(l10n.guestLabel, style: const TextStyle(color: Colors.grey, fontSize: 13))
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
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard),
                label: l10n.navDashboard,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.business_center_outlined),
                activeIcon: const Icon(Icons.business_center),
                label: l10n.navPortfolio,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.add_box_outlined),
                activeIcon: const Icon(Icons.add_box),
                label: l10n.navRecord,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history_edu_outlined),
                activeIcon: const Icon(Icons.history_edu),
                label: l10n.navLedger,
              ),
            ],
          ),
        );
      },
    );
  }
}