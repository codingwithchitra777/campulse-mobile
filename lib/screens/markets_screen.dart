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

/// Public market overview — no sign-in required. Shows gold + USD/KHR rate
/// plus a live CSX ticker list sourced from `/api/prices` (already a public,
/// unauthenticated feed — previously only used internally for symbol
/// pickers). Portfolio-specific content (balance, equity chart, positions)
/// lives on the Portfolio tab instead; this screen is the app's public
/// front door, matching what a guest can already see on the web landing page.
class MarketsScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const MarketsScreen({super.key, this.onNavigate});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = false;

  Map<String, dynamic>? _exchangeHistory;
  Map<String, dynamic>? _goldHistory;

  /// Top 5 by |change|, each enriched with a `spots` sparkline.
  List<Map<String, dynamic>> _movers = [];

  /// Everything else, alphabetical, no sparkline (keeps the request count low).
  List<Map<String, dynamic>> _rest = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getExchangeRateHistory('USD', 'KHR'),
        _api.getMarketPriceHistory('XAU-KH'),
        _api.getPrices(),
      ]);
      final prices = (results[2] as List).cast<Map<String, dynamic>>();
      final sorted = [...prices]
        ..sort((a, b) => ((b['change'] as num?) ?? 0)
            .abs()
            .compareTo(((a['change'] as num?) ?? 0).abs()));
      final top = sorted.take(5).toList();
      final topTickers = top.map((e) => (e['ticker'] ?? '').toString()).toSet();
      final rest = sorted.where((e) => !topTickers.contains((e['ticker'] ?? '').toString())).toList()
        ..sort((a, b) => (a['ticker'] ?? '').toString().compareTo((b['ticker'] ?? '').toString()));

      final spots = await Future.wait(top.map((t) async {
        try {
          final h = await _api.getMarketPriceHistory((t['ticker'] ?? '').toString(), days: 30);
          final hist = (h['items'] as List?) ?? const [];
          return [
            for (final e in hist)
              if (e['price'] != null) (e['price'] as num).toDouble(),
          ];
        } catch (_) {
          return <double>[];
        }
      }));
      for (var i = 0; i < top.length; i++) {
        top[i] = {...top[i], 'spots': spots[i]};
      }

      setState(() {
        _exchangeHistory = results[0] as Map<String, dynamic>;
        _goldHistory = results[1] as Map<String, dynamic>;
        _movers = top;
        _rest = rest;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading markets: $e')));
      }
    }
  }

  /// Cambodia (UTC+7) trading-hours heuristic, mirrors campulse-web's
  /// `App.updateMarketStatus()`: weekday 08:00-15:00 = open.
  ({bool open, String text}) get _marketStatus {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final isWorkingHours = now.hour >= 8 && now.hour < 15;
    if (isWeekend) return (open: false, text: 'CSX closed · weekend');
    if (!isWorkingHours) return (open: false, text: 'CSX closed');
    return (open: true, text: 'CSX open');
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, context.navBarClearance,
        ),
        child: _loading ? _buildSkeleton(context) : _buildContent(context),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Row(
          children: [
            Expanded(child: Skeleton.card(height: 76)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Skeleton.card(height: 76)),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        Skeleton.card(height: 260),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final status = _marketStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status.open ? c.profit : c.textMuted,
              ),
            ),
            const SizedBox(width: 6),
            Text(status.text,
                style: TextStyle(
                    color: status.open ? c.profit : c.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _miniChartCard(
                context, 'Gold · XAU-KH', _goldSpots(), c.warning,
                valueLabel: _goldLatest(),
                changePct: _spotsPct(_goldSpots()),
                onTap: _openGoldDetail,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _miniChartCard(
                context, 'USD / KHR', _exchangeSpots(), c.primary,
                valueLabel: _exchangeLatest(),
                changePct: _spotsPct(_exchangeSpots()),
                onTap: _openExchangeDetail,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: l10n.marketMovers),
        _buildMovers(context),
        if (_rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'All CSX stocks'),
          _buildRest(context),
        ],
        if (AuthService.instance.isGuest) ...[
          const SizedBox(height: AppSpacing.xl),
          _guestBanner(context),
        ],
      ],
    );
  }

  Widget _guestBanner(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: () => widget.onNavigate?.call(1),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text('Sign in to track your own portfolio',
                style: TextStyle(color: c.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Icon(Icons.arrow_forward_rounded, size: 18, color: c.primary),
        ],
      ),
    );
  }

  // ── CSX movers (with sparkline) ─────────────────────────────────────
  Widget _buildMovers(BuildContext context) {
    final c = context.colors;
    if (_movers.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text('No price data yet', style: TextStyle(color: c.textMuted)),
          ),
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (int i = 0; i < _movers.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: c.border.withValues(alpha: 0.6), indent: 64),
            _moverRow(context, _movers[i]),
          ],
        ],
      ),
    );
  }

  Widget _moverRow(BuildContext context, Map<String, dynamic> w) {
    final c = context.colors;
    final ticker = (w['ticker'] ?? '').toString();
    final price = w['price'] as num?;
    final change = (w['change'] as num?) ?? 0;
    final dir = (w['change_direction'] ?? 'equal').toString();
    final spots = (w['spots'] as List?)?.cast<double>() ?? const [];
    final color = dir == 'up' ? c.profit : (dir == 'down' ? c.loss : c.textMuted);
    final prev = (price?.toDouble() ?? 0) - change.toDouble();
    final pct = prev != 0 ? (change / prev) * 100 : 0.0;
    final initials = ticker.isEmpty
        ? '?'
        : ticker.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').padRight(2).substring(0, 2).toUpperCase();

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
                  colors: [c.primary.withValues(alpha: 0.9), c.primary.withValues(alpha: 0.55)],
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
              child: Text(ticker,
                  style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: spots.length < 2
                  ? const SizedBox()
                  : Sparkline(values: spots, color: color, height: 34),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price == null ? '—' : Money.format(price, 'KHR'),
                    style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      dir == 'up'
                          ? Icons.arrow_drop_up_rounded
                          : (dir == 'down' ? Icons.arrow_drop_down_rounded : Icons.remove_rounded),
                      color: color,
                      size: 16,
                    ),
                    Text('${pct >= 0 ? '+' : '−'}${pct.abs().toStringAsFixed(1)}%',
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Full CSX list (compact, no sparkline) ───────────────────────────
  Widget _buildRest(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (int i = 0; i < _rest.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.border.withValues(alpha: 0.6)),
            _restRow(context, _rest[i]),
          ],
        ],
      ),
    );
  }

  Widget _restRow(BuildContext context, Map<String, dynamic> w) {
    final c = context.colors;
    final ticker = (w['ticker'] ?? '').toString();
    final price = w['price'] as num?;
    final change = (w['change'] as num?) ?? 0;
    final dir = (w['change_direction'] ?? 'equal').toString();
    final color = dir == 'up' ? c.profit : (dir == 'down' ? c.loss : c.textMuted);
    final prev = (price?.toDouble() ?? 0) - change.toDouble();
    final pct = prev != 0 ? (change / prev) * 100 : 0.0;

    return InkWell(
      onTap: () => _openSymbolDetail(w),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(ticker,
                  style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            Text(price == null ? '—' : Money.format(price, 'KHR'),
                style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 56,
              child: Text('${pct >= 0 ? '+' : '−'}${pct.abs().toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _openSymbolDetail(Map<String, dynamic> w) {
    final ticker = (w['ticker'] ?? '').toString();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MarketDetailScreen(
        title: ticker,
        subtitle: 'CSX · KHR',
        formatFull: (v) => Money.format(v, 'KHR'),
        formatCompact: (v) => Money.compact(v, 'KHR'),
        loader: () async {
          final h = await _api.getMarketPriceHistory(ticker, days: 180);
          return _bidAskFromHistory(h['items'], dateKey: 'date',
              bidKey: 'bidPrice', askKey: 'askPrice', fallbackKey: 'price');
        },
      ),
    ));
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

  double? _spotsPct(List<FlSpot> spots) {
    if (spots.length < 2 || spots.first.y == 0) return null;
    return (spots.last.y - spots.first.y) / spots.first.y * 100;
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
    // Gold price-history comes back oldest→newest already (unlike the exchange
    // feed), so do NOT reverse. Show the Bid, falling back to the stored mid
    // price when bid is absent.
    return [
      for (int i = 0; i < items.length; i++)
        FlSpot(i.toDouble(),
            ((items[i]['bidPrice'] ?? items[i]['price']) as num?)?.toDouble() ?? 0),
    ];
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
}
