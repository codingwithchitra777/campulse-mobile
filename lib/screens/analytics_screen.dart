import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import '../widgets/app_card.dart';
import '../widgets/pnl_chip.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';

/// Descriptive analytics computed entirely from the existing portfolio + trades
/// endpoints (no dedicated backend). Everything is grouped per currency so KHR
/// and USD figures are never blended.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

/// Per-currency rollup of realised/unrealised P/L and position win/loss counts.
class _CcyStats {
  double realised = 0;
  double unrealised = 0;
  double invested = 0;
  int winners = 0;
  int losers = 0;
  Map<String, dynamic>? best;
  Map<String, dynamic>? worst;
  double get total => realised + unrealised;
  int get closedOrOpen => winners + losers;
  double get winRate => closedOrOpen == 0 ? 0 : winners / closedOrOpen;
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;

  final Map<String, _CcyStats> _byCcy = {};
  int _totalTrades = 0;
  int _buys = 0;
  int _sells = 0;
  final Map<String, double> _commissionByCcy = {};
  final Map<String, int> _tradesByMarket = {};
  final Map<String, int> _tickerCounts = {};
  DateTime? _firstTrade;
  DateTime? _lastTrade;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final portfolio = await _api.getPortfolio();
      final trades = await _api.getTrades();

      final byCcy = <String, _CcyStats>{};
      for (final h in portfolio) {
        final ccy = (h['currency'] as String?) ?? 'KHR';
        final s = byCcy.putIfAbsent(ccy, () => _CcyStats());
        final realised = (h['realisedPnl'] as num?)?.toDouble() ?? 0;
        final unrealised = (h['unrealisedPnl'] as num?)?.toDouble() ?? 0;
        final totalPnl = (h['totalPnl'] as num?)?.toDouble() ?? 0;
        final qty = (h['remainingQty'] as num?)?.toDouble() ?? 0;
        final avg = (h['avgCostRemaining'] as num?)?.toDouble() ?? 0;
        s.realised += realised;
        s.unrealised += unrealised;
        s.invested += qty * avg;
        if (totalPnl > 0) s.winners += 1;
        if (totalPnl < 0) s.losers += 1;
        if (s.best == null || totalPnl > ((s.best!['totalPnl'] as num?) ?? 0)) s.best = h;
        if (s.worst == null || totalPnl < ((s.worst!['totalPnl'] as num?) ?? 0)) s.worst = h;
      }

      int buys = 0, sells = 0;
      final commission = <String, double>{};
      final byMarket = <String, int>{};
      final tickerCounts = <String, int>{};
      DateTime? first, last;
      for (final t in trades) {
        final side = (t['side'] ?? '').toString();
        if (side == 'BUY') buys++;
        if (side == 'SELL') sells++;
        final ccy = (t['currency'] as String?) ?? 'KHR';
        commission[ccy] = (commission[ccy] ?? 0) + ((t['commission'] as num?)?.toDouble() ?? 0);
        final market = (t['market'] as String?) ?? 'CSX';
        byMarket[market] = (byMarket[market] ?? 0) + 1;
        final ticker = (t['ticker'] ?? '').toString();
        if (ticker.isNotEmpty) tickerCounts[ticker] = (tickerCounts[ticker] ?? 0) + 1;
        final d = DateTime.tryParse((t['orderDate'] ?? '').toString());
        if (d != null) {
          if (first == null || d.isBefore(first)) first = d;
          if (last == null || d.isAfter(last)) last = d;
        }
      }

      setState(() {
        _byCcy
          ..clear()
          ..addAll(_sorted(byCcy));
        _totalTrades = trades.length;
        _buys = buys;
        _sells = sells;
        _commissionByCcy
          ..clear()
          ..addAll(commission);
        _tradesByMarket
          ..clear()
          ..addAll(byMarket);
        _tickerCounts
          ..clear()
          ..addAll(tickerCounts);
        _firstTrade = first;
        _lastTrade = last;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load analytics: $e')),
        );
      }
    }
  }

  Map<String, _CcyStats> _sorted(Map<String, _CcyStats> m) {
    final entries = m.entries.toList()
      ..sort((a, b) {
        if (a.key == 'KHR') return -1;
        if (b.key == 'KHR') return 1;
        return b.value.total.abs().compareTo(a.value.total.abs());
      });
    return {for (final e in entries) e.key: e.value};
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? _skeleton()
            : (_totalTrades == 0 && _byCcy.isEmpty)
                ? _empty(c)
                : _content(c),
      ),
    );
  }

  Widget _skeleton() => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Skeleton.card(height: 150),
          SizedBox(height: AppSpacing.lg),
          Skeleton.card(height: 120),
          SizedBox(height: AppSpacing.lg),
          Skeleton.card(height: 160),
        ],
      );

  Widget _empty(AppColors c) => ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.query_stats_rounded, size: 64, color: c.textMuted),
          const SizedBox(height: AppSpacing.lg),
          Text('No data to analyse yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text('Record a few trades and your performance stats will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 14, height: 1.4)),
        ],
      );

  Widget _content(AppColors c) {
    final topTicker = _tickerCounts.entries.isEmpty
        ? null
        : (_tickerCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        // Per-currency P/L hero cards
        for (final e in _byCcy.entries) ...[
          _pnlCard(c, e.key, e.value),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),

        // Performance (win rate + best/worst) per currency
        const SectionHeader(title: 'Performance'),
        for (final e in _byCcy.entries) ...[
          _performanceCard(c, e.key, e.value),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),

        // Activity
        const SectionHeader(title: 'Activity'),
        _activityCard(c, topTicker),
      ],
    );
  }

  Widget _pnlCard(AppColors c, String ccy, _CcyStats s) {
    return AppCard(
      gradient: c.primaryGradient,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$ccy TOTAL P/L',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          Text(Money.format(s.total, ccy, signed: true),
              style: const TextStyle(
                  color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _heroStat('Realised', Money.format(s.realised, ccy, signed: true))),
              Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _heroStat('Unrealised', Money.format(s.unrealised, ccy, signed: true))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _performanceCard(AppColors c, String ccy, _CcyStats s) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$ccy positions',
                  style: TextStyle(color: c.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(s.winRate * 100).toStringAsFixed(0)}% win rate',
                  style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Win/loss bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: Row(
              children: [
                Expanded(
                  flex: (s.winners * 100).clamp(0, 100000) + (s.closedOrOpen == 0 ? 1 : 0),
                  child: Container(height: 8, color: c.profit),
                ),
                Expanded(
                  flex: (s.losers * 100).clamp(0, 100000),
                  child: Container(height: 8, color: c.loss),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('${s.winners} up · ${s.losers} down',
              style: TextStyle(color: c.textMuted, fontSize: 11)),
          const SizedBox(height: AppSpacing.md),
          if (s.best != null) _bestWorstRow(c, 'Top', s.best!, ccy),
          if (s.worst != null && s.worst != s.best) ...[
            const SizedBox(height: AppSpacing.sm),
            _bestWorstRow(c, 'Weakest', s.worst!, ccy),
          ],
        ],
      ),
    );
  }

  Widget _bestWorstRow(AppColors c, String label, Map<String, dynamic> h, String ccy) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: c.surfaceAlt,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(label,
              style: TextStyle(color: c.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text((h['ticker'] ?? '').toString(),
            style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
        const Spacer(),
        PnlChip(value: (h['totalPnl'] as num?) ?? 0, currency: ccy),
      ],
    );
  }

  Widget _activityCard(AppColors c, MapEntry<String, int>? topTicker) {
    final totalBs = (_buys + _sells).clamp(1, 1 << 30);
    String range = '—';
    if (_firstTrade != null && _lastTrade != null) {
      final fmt = DateFormat('d MMM yyyy');
      range = _firstTrade == _lastTrade
          ? fmt.format(_firstTrade!)
          : '${fmt.format(_firstTrade!)} – ${fmt.format(_lastTrade!)}';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _bigStat(c, '$_totalTrades', 'Trades'),
              _bigStat(c, '$_buys', 'Buys', color: c.profit),
              _bigStat(c, '$_sells', 'Sells', color: c.loss),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Buy vs sell bar
          Text('Buy / sell split',
              style: TextStyle(color: c.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: Row(
              children: [
                Expanded(
                  flex: (_buys * 1000 ~/ totalBs).clamp(0, 1000) + (_buys == 0 && _sells == 0 ? 1 : 0),
                  child: Container(height: 8, color: c.profit),
                ),
                Expanded(
                  flex: (_sells * 1000 ~/ totalBs).clamp(0, 1000),
                  child: Container(height: 8, color: c.loss),
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.xl),
          _kv(c, 'Active period', range),
          const SizedBox(height: AppSpacing.sm),
          if (topTicker != null)
            _kv(c, 'Most traded', '${topTicker.key} · ${topTicker.value}×'),
          if (_tradesByMarket.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _kv(c, 'By market',
                (_tradesByMarket.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
                    .map((e) => '${e.key == 'GOLD_KH' ? 'Gold' : e.key} ${e.value}')
                    .join(' · ')),
          ],
          for (final e in _commissionByCcy.entries)
            if (e.value > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _kv(c, 'Fees paid (${e.key})', Money.format(e.value, e.key)),
            ],
        ],
      ),
    );
  }

  Widget _bigStat(AppColors c, String value, String label, {Color? color}) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color ?? c.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: c.textMuted, fontSize: 11)),
          ],
        ),
      );

  Widget _kv(AppColors c, String key, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(key, style: TextStyle(color: c.textMuted, fontSize: 13)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      );
}
