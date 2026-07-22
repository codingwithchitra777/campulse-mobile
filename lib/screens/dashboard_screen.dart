import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import '../widgets/app_card.dart';
import '../widgets/pnl_chip.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onRefresh;

  /// Switches the bottom-nav tab (0 Dashboard · 1 Portfolio · 2 Record ·
  /// 3 History · 4 Account) — used by the quick-action row under the hero.
  final ValueChanged<int>? onNavigate;

  const DashboardScreen({super.key, required this.onRefresh, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// Running totals for one currency — never blended across currencies.
class _Agg {
  double value = 0;
  double realised = 0;
  double unrealised = 0;
  int positions = 0;
  double get ret => realised + unrealised;
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = false;

  List<dynamic> _topTickers = [];
  Map<String, dynamic>? _chartsData;
  Map<String, dynamic>? _exchangeHistory;
  Map<String, dynamic>? _goldHistory;
  Map<String, dynamic>? _latestExchangeRate;

  String _valuationMode = 'BID';
  final String _selectedMarket = 'ALL';
  final String _baseCurrency = 'KHR';

  /// Per-currency aggregates, primary currency first.
  final Map<String, _Agg> _byCurrency = {};
  int _totalPositions = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    try {
      final latestExchange = await _api.getLatestExchangeRate('USD', 'KHR');
      final exchangeHistory = await _api.getExchangeRateHistory('USD', 'KHR');
      final goldHistory = await _api.getMarketPriceHistory('XAU-KH');

      List<dynamic> topTickers = [];
      Map<String, dynamic>? chartsData;
      final byCcy = <String, _Agg>{};
      int positions = 0;

      if (!AuthService.instance.isGuest) {
        final portfolio = await _api.getPortfolio(valuationMode: _valuationMode);
        topTickers = await _api.getTopTickers();
        chartsData = await _api.getChartsTimeline(
          _selectedMarket == 'ALL' ? null : _selectedMarket,
          _baseCurrency,
          _valuationMode,
        );

        for (final h in portfolio) {
          final ccy = (h['currency'] as String?) ?? 'KHR';
          final qty = (h['remainingQty'] as num?)?.toDouble() ?? 0;
          final price = (h['lastPrice'] as num?)?.toDouble() ?? 0;
          final realised = (h['realisedPnl'] as num?)?.toDouble() ?? 0;
          final unrealised = (h['unrealisedPnl'] as num?)?.toDouble() ?? 0;

          final agg = byCcy.putIfAbsent(ccy, () => _Agg());
          agg.value += qty * price;
          agg.realised += realised;
          agg.unrealised += unrealised;
          if (qty > 0) agg.positions += 1;
          positions += 1;
        }
      }

      setState(() {
        _latestExchangeRate = latestExchange;
        _exchangeHistory = exchangeHistory;
        _goldHistory = goldHistory;
        _topTickers = topTickers;
        _chartsData = chartsData;
        _byCurrency
          ..clear()
          ..addAll(_sortedByValue(byCcy));
        _totalPositions = positions;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingDashboard('$e'))),
        );
      }
    }
  }

  /// KHR first, then by descending value — so the hero shows the main currency.
  Map<String, _Agg> _sortedByValue(Map<String, _Agg> m) {
    final entries = m.entries.toList()
      ..sort((a, b) {
        if (a.key == 'KHR') return -1;
        if (b.key == 'KHR') return 1;
        return b.value.value.compareTo(a.value.value);
      });
    return {for (final e in entries) e.key: e.value};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 110,
        ),
        child: AuthService.instance.isGuest
            ? _GuestHero(l10n: l10n)
            : _loading
                ? _buildSkeleton(context)
                : _buildContent(context, l10n),
      ),
    );
  }

  // ── Loading skeleton ────────────────────────────────────────────────
  Widget _buildSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Skeleton(width: 160, height: 14),
        SizedBox(height: AppSpacing.lg),
        Skeleton.card(height: 150),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: Skeleton(height: 76)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Skeleton(height: 76)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Skeleton(height: 76)),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        Skeleton.card(height: 220),
      ],
    );
  }

  // ── Authenticated content ───────────────────────────────────────────
  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    final primaryCcy = _byCurrency.keys.isNotEmpty ? _byCurrency.keys.first : 'KHR';
    final primary = _byCurrency[primaryCcy] ?? _Agg();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _greeting(context),
        const SizedBox(height: AppSpacing.lg),
        _buildHero(context, l10n, primaryCcy, primary),
        const SizedBox(height: AppSpacing.lg),
        _buildQuickActions(context),
        const SizedBox(height: AppSpacing.lg),
        _buildQuickStats(context, primaryCcy, primary),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: l10n.portfolioPerformance),
        AppCard(
          child: SizedBox(height: 200, child: _buildEquityChart(context)),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: l10n.marketMovers),
        _buildMovers(context, l10n),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: _miniChartCard(
                context, l10n.exchangeRateTrend,
                _exchangeSpots(), context.colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _miniChartCard(
                context, l10n.goldPriceTrend,
                _goldSpots(), context.colors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _greeting(BuildContext context) {
    final c = context.colors;
    final name = _firstName(AuthService.instance.profile.value?.name ?? '');
    final hour = DateTime.now().hour;
    final part = hour < 12 ? 'Good morning' : (hour < 18 ? 'Good afternoon' : 'Good evening');
    return Text(
      name.isEmpty ? part : '$part, $name',
      style: TextStyle(color: c.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

  /// First real given name, skipping honorifics like "Mr."/"Dr.".
  static String _firstName(String full) {
    const titles = {'mr', 'mr.', 'ms', 'ms.', 'mrs', 'mrs.', 'dr', 'dr.', 'miss'};
    for (final t in full.split(RegExp(r'\s+')).where((t) => t.isNotEmpty)) {
      if (!titles.contains(t.toLowerCase())) return t;
    }
    return '';
  }

  Widget _buildHero(BuildContext context, AppLocalizations l10n, String ccy, _Agg agg) {
    final c = context.colors;
    final secondary = _byCurrency.entries.where((e) => e.key != ccy).toList();

    return AppCard(
      gradient: c.primaryGradient,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.portfolioValue.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              _valuationToggle(context, l10n),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            Money.format(agg.value, ccy),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _heroReturnPill(agg.ret, ccy),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'total return',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
              ),
            ],
          ),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: AppSpacing.md),
            for (final e in secondary)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${e.key} holdings',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                    Text(
                      Money.format(e.value.value, e.key),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.md),
          _rateChip(context),
        ],
      ),
    );
  }

  Widget _heroReturnPill(num value, String ccy) {
    final up = value >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 14, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            Money.format(value, ccy, signed: true),
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _rateChip(BuildContext context) {
    String rateText = '—';
    final r = _latestExchangeRate?['rate'];
    if (r != null && r['bidRate'] != null) {
      rateText = '${r['bidRate']} / ${r['askRate']}';
    }
    return Row(
      children: [
        Icon(Icons.currency_exchange_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 5),
        Text(
          'USD/KHR  $rateText',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _valuationToggle(BuildContext context, AppLocalizations l10n) {
    Widget seg(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? context.colors.primary : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        children: [
          seg(l10n.valuationBid, _valuationMode == 'BID', () {
            if (_valuationMode != 'BID') {
              setState(() => _valuationMode = 'BID');
              _loadAllData();
            }
          }),
          seg(l10n.valuationAsk, _valuationMode == 'ASK', () {
            if (_valuationMode != 'ASK') {
              setState(() => _valuationMode = 'ASK');
              _loadAllData();
            }
          }),
        ],
      ),
    );
  }

  /// ByteTown-style circular quick actions under the balance hero. Each is a
  /// soft-tinted round button + label; most jump to a bottom-nav tab, but some
  /// (e.g. Watchlist) push their own screen via [onTap].
  Widget _buildQuickActions(BuildContext context) {
    Widget action(IconData icon, String label, {int? tab, VoidCallback? onTap, Color? tint}) {
      final c = context.colors;
      final color = tint ?? c.primary;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap ?? (tab != null ? () => widget.onNavigate?.call(tab) : null),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final c = context.colors;
    return Row(
      children: [
        action(Icons.add_rounded, 'Record', tab: 2),
        action(Icons.pie_chart_rounded, 'Portfolio', tab: 1, tint: c.primaryDark),
        action(Icons.star_rounded, 'Watchlist', tab: 3, tint: c.warning),
        action(Icons.receipt_long_rounded, 'History', tab: 4, tint: c.profit),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, String ccy, _Agg agg) {
    final c = context.colors;
    Widget tile(String label, String value, {Color? color, IconData? icon}) {
      return Expanded(
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: c.textMuted),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(label,
                        style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(color: color ?? c.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile('Realised', Money.format(agg.realised, ccy, signed: true),
            color: c.pnl(agg.realised), icon: Icons.check_circle_outline_rounded),
        const SizedBox(width: AppSpacing.md),
        tile('Unrealised', Money.format(agg.unrealised, ccy, signed: true),
            color: c.pnl(agg.unrealised), icon: Icons.trending_up_rounded),
        const SizedBox(width: AppSpacing.md),
        tile('Positions', '$_totalPositions', icon: Icons.layers_outlined),
      ],
    );
  }

  // ── Charts ──────────────────────────────────────────────────────────
  List<FlSpot> _equitySpots() {
    final equity = _chartsData?['equity'];
    if (equity is! List || equity.isEmpty) return [];
    // Each entry is {date, value} — pull the numeric value.
    return [
      for (int i = 0; i < equity.length; i++)
        FlSpot(i.toDouble(), (equity[i]['value'] as num?)?.toDouble() ?? 0),
    ];
  }

  List<FlSpot> _exchangeSpots() {
    final items = _exchangeHistory?['items'];
    if (items is! List || items.isEmpty) return [];
    final rev = items.reversed.toList();
    return [
      for (int i = 0; i < rev.length; i++)
        FlSpot(i.toDouble(), (rev[i]['bidRate'] as num?)?.toDouble() ?? 0),
    ];
  }

  List<FlSpot> _goldSpots() {
    final items = _goldHistory?['items'];
    if (items is! List || items.isEmpty) return [];
    final rev = items.reversed.toList();
    return [
      for (int i = 0; i < rev.length; i++)
        FlSpot(i.toDouble(), (rev[i]['price'] as num?)?.toDouble() ?? 0),
    ];
  }

  Widget _buildEquityChart(BuildContext context) {
    final c = context.colors;
    final spots = _equitySpots();
    if (spots.isEmpty) {
      return _emptyChart(context, 'Record a trade to see your equity curve');
    }
    final trendUp = spots.last.y >= spots.first.y;
    final color = trendUp ? c.profit : c.loss;
    return _lineChart(spots, color, fill: true);
  }

  Widget _miniChartCard(BuildContext context, String title, List<FlSpot> spots, Color color) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 60,
            child: spots.isEmpty
                ? Center(child: Text('—', style: TextStyle(color: c.textMuted)))
                : _lineChart(spots, color, fill: true),
          ),
        ],
      ),
    );
  }

  Widget _emptyChart(BuildContext context, String msg) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart_rounded, size: 32, color: c.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(msg, style: TextStyle(color: c.textMuted, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _lineChart(List<FlSpot> spots, Color color, {bool fill = false}) {
    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.12;
    if (pad == 0) {
      minY -= 10;
      maxY += 10;
    } else {
      minY -= pad;
      maxY += pad;
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: fill,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top movers ──────────────────────────────────────────────────────
  Widget _buildMovers(BuildContext context, AppLocalizations l10n) {
    final c = context.colors;
    if (_topTickers.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(l10n.noRankData, style: TextStyle(color: c.textMuted, fontSize: 13)),
          ),
        ),
      );
    }
    final items = _topTickers.take(5).toList();
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: c.border.withValues(alpha: 0.6), indent: 52),
            _moverRow(context, items[i], i + 1),
          ],
        ],
      ),
    );
  }

  Widget _moverRow(BuildContext context, dynamic item, int rank) {
    final c = context.colors;
    final name = (item['ticker'] ?? '').toString();
    final pnl = (item['realisedPnl'] as num?) ?? 0;
    final ccy = (item['currency'] as String?) ?? 'KHR';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text('$rank',
                style: TextStyle(color: c.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(name,
                style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          PnlChip(value: pnl, currency: ccy),
        ],
      ),
    );
  }
}

/// Guest / signed-out landing hero, restyled with the design system.
class _GuestHero extends StatelessWidget {
  final AppLocalizations l10n;
  const _GuestHero({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget feature(String emoji, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(body, style: TextStyle(color: c.textMuted, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.15),
              border: Border.all(color: c.primary.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text('🔐 Google Authenticated & Secure',
                style: TextStyle(color: c.primary, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Cambodia\'s premium investment\n& portfolio tracker',
          style: TextStyle(
              color: c.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, height: 1.25),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Log transactions, track real-time asset prices, and analyse matching lots with best-price cost-basis logic.',
          style: TextStyle(color: c.textMuted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.xl),
        feature('📊', 'Real-time prices', 'Public cached feed from the Cambodia Securities Exchange.'),
        feature('📦', 'Best-price lot matching',
            'Sales match your cheapest open buy lots first, maximising realised profit.'),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          gradient: c.primaryGradient,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: const Center(child: Text('🔒', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Sign in to view your dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Use your Google account to record trades and track realised & unrealised profit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
