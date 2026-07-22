import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import '../widgets/app_card.dart';
import '../widgets/performance_chart.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';
import 'market_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onRefresh;

  /// Switches the bottom-nav tab (0 Dashboard · 1 Portfolio · 2 Record ·
  /// 3 History · 4 Account) — used by the quick-action row under the hero.
  final ValueChanged<int>? onNavigate;

  const DashboardScreen({super.key, required this.onRefresh, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// Date-range filter for the performance chart (mirrors the web: 1W…ALL).
enum _ChartRange {
  w1('1W', 7),
  m1('1M', 30),
  m3('3M', 90),
  m6('6M', 180),
  all('ALL', null);

  const _ChartRange(this.label, this.days);
  final String label;
  final int? days;

  /// Human label for the period P/L readout.
  String get plLabel => switch (this) {
        _ChartRange.w1 => 'Past week',
        _ChartRange.m1 => 'Past month',
        _ChartRange.m3 => 'Past 3 months',
        _ChartRange.m6 => 'Past 6 months',
        _ChartRange.all => 'All time',
      };
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

  /// Top watchlist symbols, each with `spots` (sparkline values) added.
  List<Map<String, dynamic>> _watchTop = [];
  Map<String, dynamic>? _chartsData;
  Map<String, dynamic>? _exchangeHistory;
  Map<String, dynamic>? _goldHistory;
  Map<String, dynamic>? _latestExchangeRate;

  String _valuationMode = 'BID';
  final String _selectedMarket = 'ALL';
  final String _baseCurrency = 'KHR';
  _ChartRange _chartRange = _ChartRange.all;

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

      List<Map<String, dynamic>> watchTop = [];
      Map<String, dynamic>? chartsData;
      final byCcy = <String, _Agg>{};
      int positions = 0;

      if (!AuthService.instance.isGuest) {
        final portfolio = await _api.getPortfolio(valuationMode: _valuationMode);
        watchTop = await _loadWatchTop();
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
        _watchTop = watchTop;
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

  /// The first 5 watchlist symbols, each enriched with a `spots` sparkline
  /// (fetched in parallel from each symbol's recent price history; empty for
  /// symbols without snapshot history, e.g. US equities).
  Future<List<Map<String, dynamic>>> _loadWatchTop() async {
    final List items;
    try {
      items = (await _api.getWatchlist()).take(5).toList();
    } catch (_) {
      return [];
    }
    final spots = await Future.wait(items.map((w) async {
      try {
        final h = await _api.getMarketPriceHistory((w['symbol'] ?? '').toString(), days: 30);
        final hist = (h['items'] as List?) ?? const [];
        return [
          for (final e in hist)
            if (e['price'] != null) (e['price'] as num).toDouble(),
        ];
      } catch (_) {
        return <double>[];
      }
    }));
    return [
      for (int i = 0; i < items.length; i++)
        {...(items[i] as Map).cast<String, dynamic>(), 'spots': spots[i]},
    ];
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
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, context.navBarClearance,
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
        AppCard(child: _buildEquityChart(context, primaryCcy)),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Watchlist'),
        _buildWatchTop(context),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: _miniChartCard(
                context, l10n.exchangeRateTrend,
                _exchangeSpots(), context.colors.primary,
                valueLabel: _exchangeLatest(),
                changePct: _spotsPct(_exchangeSpots()),
                onTap: _openExchangeDetail,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _miniChartCard(
                context, l10n.goldPriceTrend,
                _goldSpots(), context.colors.warning,
                valueLabel: _goldLatest(),
                changePct: _spotsPct(_goldSpots()),
                onTap: _openGoldDetail,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double? _spotsPct(List<FlSpot> spots) {
    if (spots.length < 2 || spots.first.y == 0) return null;
    return (spots.last.y - spots.first.y) / spots.first.y * 100;
  }

  void _openGoldDetail() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MarketDetailScreen(
        title: 'Gold · XAU-KH',
        subtitle: 'USD per chi · Bid / Ask',
        formatFull: (v) => Money.format(v, 'USD'),
        formatCompact: (v) => Money.compact(v, 'USD'),
        loader: () async {
          final h = await _api.getMarketPriceHistory('XAU-KH', days: 180);
          return _bidAskFromHistory(h['items'], dateKey: 'date',
              bidKey: 'bidPrice', askKey: 'askPrice', fallbackKey: 'price');
        },
      ),
    ));
  }

  void _openExchangeDetail() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MarketDetailScreen(
        title: 'USD / KHR',
        subtitle: 'Exchange rate · Bid / Ask',
        formatFull: (v) => NumberFormat('#,##0.00').format(v),
        formatCompact: (v) => NumberFormat('#,##0').format(v),
        loader: () async {
          final h = await _api.getExchangeRateHistory('USD', 'KHR', limit: 180);
          return _bidAskFromHistory(h['items'], dateKey: 'effectiveDate',
              bidKey: 'bidRate', askKey: 'askRate');
        },
      ),
    ));
  }

  void _openSymbolDetail(Map<String, dynamic> w) {
    final symbol = (w['symbol'] ?? '').toString();
    final market = (w['market'] ?? 'CSX').toString();
    final ccy = (w['currency'] as String?) ?? 'KHR';
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MarketDetailScreen(
        title: symbol,
        subtitle: '${market == 'GOLD_KH' ? 'Gold' : market} · $ccy',
        formatFull: (v) => Money.format(v, ccy),
        formatCompact: (v) => Money.compact(v, ccy),
        loader: () async {
          final h = await _api.getMarketPriceHistory(symbol, days: 180);
          return _bidAskFromHistory(h['items'], dateKey: 'date',
              bidKey: 'bidPrice', askKey: 'askPrice', fallbackKey: 'price');
        },
      ),
    ));
  }

  /// Builds a Bid + Ask (or single-line) [DetailData] from a history list.
  /// Ask collapses into the Bid line when it's absent or identical, so a
  /// single-price feed shows one clean line instead of two overlapping ones.
  DetailData _bidAskFromHistory(dynamic rawItems,
      {required String dateKey, required String bidKey, required String askKey, String? fallbackKey}) {
    final items = (rawItems as List?) ?? const [];
    final sorted = [...items]
      ..sort((a, b) => (a[dateKey] ?? '').toString().compareTo((b[dateKey] ?? '').toString()));
    final dates = <DateTime>[];
    final bid = <double>[];
    final ask = <double>[];
    var askDiffers = false;
    for (final e in sorted) {
      final d = DateTime.tryParse((e[dateKey] ?? '').toString());
      if (d == null) continue;
      final fb = fallbackKey == null ? null : (e[fallbackKey] as num?)?.toDouble();
      final b = (e[bidKey] as num?)?.toDouble() ?? fb;
      final a = (e[askKey] as num?)?.toDouble() ?? fb ?? b;
      if (b == null) continue;
      dates.add(d);
      bid.add(b);
      ask.add(a ?? b);
      if (a != null && a != b) askDiffers = true;
    }
    return (
      dates: dates,
      series: askDiffers
          ? [ChartSeries('Bid', bid), ChartSeries('Ask', ask, dashed: true)]
          : [ChartSeries('Price', bid)],
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

  /// Aligned equity (market value) + invested (cost basis) series on a shared
  /// date axis, with the per-point dates for tooltips. `invested` is
  /// forward-filled from the (sparser, per-trade-date) investment series onto
  /// the (per-snapshot-day) equity dates.
  ({List<FlSpot> value, List<FlSpot> invested, List<String> dates}) _equitySeries() {
    final equity = _chartsData?['equity'];
    if (equity is! List || equity.isEmpty) {
      return (value: const [], invested: const [], dates: const []);
    }
    final investment = (_chartsData?['investment'] as List?) ?? const [];
    final days = _chartRange.days;
    final cutoff = days == null ? null : DateTime.now().subtract(Duration(days: days));

    final value = <FlSpot>[];
    final invested = <FlSpot>[];
    final dates = <String>[];
    int inv = 0;
    double lastInvested = 0;
    int x = 0;
    for (int i = 0; i < equity.length; i++) {
      final date = (equity[i]['date'] ?? '').toString();
      // Always advance the invested pointer so the forward-fill stays correct
      // even for points filtered out of the selected range.
      while (inv < investment.length &&
          (investment[inv]['date'] ?? '').toString().compareTo(date) <= 0) {
        lastInvested = (investment[inv]['invested'] as num?)?.toDouble() ?? lastInvested;
        inv++;
      }
      if (cutoff != null) {
        final d = DateTime.tryParse(date);
        if (d != null && d.isBefore(cutoff)) continue;
      }
      final val = (equity[i]['value'] as num?)?.toDouble() ?? 0;
      value.add(FlSpot(x.toDouble(), val));
      invested.add(FlSpot(x.toDouble(), lastInvested));
      dates.add(date);
      x++;
    }
    return (value: value, invested: invested, dates: dates);
  }

  String? _exchangeLatest() {
    final s = _exchangeSpots();
    if (s.isEmpty) return null;
    return NumberFormat('#,##0.0').format(s.last.y);
  }

  String? _goldLatest() {
    final s = _goldSpots();
    if (s.isEmpty) return null;
    return Money.format(s.last.y, 'USD');
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

  Widget _buildEquityChart(BuildContext context, String ccy) {
    final c = context.colors;
    final equityRaw = _chartsData?['equity'];
    final hasAny = equityRaw is List && equityRaw.isNotEmpty;
    if (!hasAny) {
      return SizedBox(height: 200, child: _emptyChart(context, 'Record a trade to see your equity curve'));
    }
    final series = _equitySeries();
    final hasRange = series.value.isNotEmpty;

    // Period P/L = change in market value across the selected range.
    final currentValue = hasRange ? series.value.last.y : 0.0;
    final startValue = hasRange ? series.value.first.y : 0.0;
    final change = currentValue - startValue;
    final pct = startValue != 0 ? (change / startValue) * 100 : 0.0;
    final plColor = change >= 0 ? c.profit : c.loss;
    final valueColor = hasRange && change >= 0 ? c.profit : c.loss;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: current value (left) + period P/L value & percentage (right).
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_chartRange.plLabel,
                    style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(hasRange ? Money.format(currentValue, ccy) : '—',
                    style: TextStyle(color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            const Spacer(),
            if (hasRange)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(change >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 15, color: plColor),
                      const SizedBox(width: 2),
                      Text(Money.format(change, ccy, signed: true),
                          style: TextStyle(color: plColor, fontSize: 15, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${change >= 0 ? '+' : '−'}${pct.abs().toStringAsFixed(2)}%',
                      style: TextStyle(color: plColor, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Legend
        Row(
          children: [
            _legendDot(valueColor),
            const SizedBox(width: 5),
            Text('Value', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: AppSpacing.md),
            _legendDot(c.textMuted),
            const SizedBox(width: 5),
            Text('Invested', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _rangeSelector(c),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 170,
          child: hasRange
              ? _equityLineChart(context, series, valueColor, ccy)
              : _emptyChart(context, 'No data in this range'),
        ),
      ],
    );
  }

  Widget _rangeSelector(AppColors c) {
    return Row(
      children: [
        for (final r in _ChartRange.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _chartRange = r),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _chartRange == r ? c.primary : c.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: _chartRange == r ? c.primary : c.border),
                ),
                child: Text(r.label,
                    style: TextStyle(
                      color: _chartRange == r ? c.onPrimary : c.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
          ),
          if (r != _ChartRange.values.last) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _legendDot(Color color) =>
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _equityLineChart(BuildContext context,
      ({List<FlSpot> value, List<FlSpot> invested, List<String> dates}) series, Color valueColor, String ccy) {
    final c = context.colors;
    final all = [...series.value, ...series.invested];
    double minY = all.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = all.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.15;
    minY = (minY - (pad == 0 ? 10 : pad)).clamp(0, double.infinity).toDouble();
    maxY += pad == 0 ? 10 : pad;
    final interval = (maxY - minY) <= 0 ? 1.0 : (maxY - minY) / 3;

    String tooltipDate(int i) {
      if (i < 0 || i >= series.dates.length) return '';
      final d = DateTime.tryParse(series.dates[i]);
      return d == null ? series.dates[i] : DateFormat('d MMM yyyy').format(d);
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (series.value.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (v) => FlLine(color: c.border.withValues(alpha: 0.5), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: interval,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(Money.compact(value, ccy),
                    style: TextStyle(color: c.textMuted, fontSize: 9), textAlign: TextAlign.left),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          getTouchedSpotIndicator: (barData, indexes) => indexes
              .map((i) => TouchedSpotIndicatorData(
                    FlLine(color: c.textMuted.withValues(alpha: 0.4), strokeWidth: 1),
                    FlDotData(show: true, getDotPainter: (s, p, b, ix) =>
                        FlDotCirclePainter(radius: 3.5, color: barData.color ?? valueColor, strokeWidth: 0)),
                  ))
              .toList(),
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => c.surfaceAlt,
            getTooltipItems: (spots) => [
              for (int j = 0; j < spots.length; j++)
                LineTooltipItem(
                  '${spots[j].barIndex == 0 ? 'Value' : 'Invested'}  ${Money.compact(spots[j].y, ccy)}'
                  '${j == 0 ? '\n${tooltipDate(spots[j].spotIndex)}' : ''}',
                  TextStyle(
                    color: spots[j].barIndex == 0 ? valueColor : c.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          // Value (filled)
          LineChartBarData(
            spots: series.value,
            isCurved: true,
            color: valueColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [valueColor.withValues(alpha: 0.26), valueColor.withValues(alpha: 0.0)],
              ),
            ),
          ),
          // Invested (dashed, no fill)
          LineChartBarData(
            spots: series.invested,
            isCurved: true,
            color: c.textMuted,
            barWidth: 1.5,
            isStrokeCapRound: true,
            dashArray: const [5, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _miniChartCard(BuildContext context, String title, List<FlSpot> spots, Color color,
      {String? valueLabel, double? changePct, VoidCallback? onTap}) {
    final c = context.colors;
    final pctColor = changePct == null ? c.textMuted : (changePct >= 0 ? c.profit : c.loss);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: c.textMuted),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(valueLabel ?? '—',
                    style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (changePct != null)
                Text('${changePct >= 0 ? '+' : '−'}${changePct.abs().toStringAsFixed(1)}%',
                    style: TextStyle(color: pctColor, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 48,
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

  // ── Top watchlist ───────────────────────────────────────────────────
  Widget _buildWatchTop(BuildContext context) {
    final c = context.colors;
    if (_watchTop.isEmpty) {
      return AppCard(
        onTap: () => widget.onNavigate?.call(3), // Watchlist tab
        child: Row(
          children: [
            Icon(Icons.star_outline_rounded, size: 20, color: c.textMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text('Add symbols to your watchlist to track them here.',
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.textMuted),
          ],
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (int i = 0; i < _watchTop.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: c.border.withValues(alpha: 0.6), indent: 64),
            _watchRow(context, _watchTop[i]),
          ],
        ],
      ),
    );
  }

  Widget _watchRow(BuildContext context, Map<String, dynamic> w) {
    final c = context.colors;
    final symbol = (w['symbol'] ?? '').toString();
    final market = (w['market'] ?? 'CSX').toString();
    final ccy = (w['currency'] as String?) ?? 'KHR';
    final price = w['price'] as num?;
    final dir = (w['changeDirection'] ?? 'equal').toString();
    final spots = (w['spots'] as List?)?.cast<double>() ?? const [];
    final color = dir == 'up' ? c.profit : (dir == 'down' ? c.loss : c.textMuted);
    final marketColor = switch (market) {
      'US' => const Color(0xFF8B5CF6),
      'GOLD_KH' => const Color(0xFFF59E0B),
      _ => c.primary,
    };
    final initials = symbol.isEmpty
        ? '?'
        : symbol.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').padRight(2).substring(0, 2).toUpperCase();

    return InkWell(
      onTap: () => _openSymbolDetail(w),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [marketColor.withValues(alpha: 0.9), marketColor.withValues(alpha: 0.55)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(initials,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 58,
              child: Text(symbol,
                  style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Sparkline in the middle
            Expanded(
              child: spots.length < 2
                  ? const SizedBox()
                  : Sparkline(values: spots, color: color, height: 34),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price == null ? '—' : Money.format(price, ccy),
                    style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Icon(
                  dir == 'up'
                      ? Icons.arrow_drop_up_rounded
                      : (dir == 'down' ? Icons.arrow_drop_down_rounded : Icons.remove_rounded),
                  color: color,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
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
