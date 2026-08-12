import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import '../widgets/app_card.dart';
import '../widgets/performance_chart.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';
import 'position_details_screen.dart';

enum _Sort { value, pnl, name }

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

  String get plLabel => switch (this) {
        _ChartRange.w1 => 'Past week',
        _ChartRange.m1 => 'Past month',
        _ChartRange.m3 => 'Past 3 months',
        _ChartRange.m6 => 'Past 6 months',
        _ChartRange.all => 'All time',
      };
}

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = false;
  List<dynamic> _portfolio = [];
  List<dynamic> _yearlyPnl = [];
  Map<String, dynamic>? _chartsData;
  String _query = '';
  _Sort _sort = _Sort.value;
  String _valuationMode = 'BID';
  _ChartRange _chartRange = _ChartRange.all;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    setState(() => _loading = true);
    try {
      final portfolio = await _api.getPortfolio(valuationMode: _valuationMode);
      // Attach a price sparkline per holding (parallel; empty for symbols
      // without snapshot history, e.g. US equities).
      final spots = await Future.wait(portfolio.map((h) async {
        try {
          final res = await _api.getMarketPriceHistory((h['ticker'] ?? '').toString(), days: 30);
          final hist = (res['items'] as List?) ?? const [];
          return [
            for (final e in hist)
              if (e['price'] != null) (e['price'] as num).toDouble(),
          ];
        } catch (_) {
          return <double>[];
        }
      }));
      for (int i = 0; i < portfolio.length; i++) {
        (portfolio[i] as Map)['spots'] = spots[i];
      }
      // Realised P/L by year (best-effort — never blocks the holdings view).
      List<dynamic> yearly = [];
      try {
        yearly = await _api.getYearlyPnl();
      } catch (_) {}
      // Equity/invested timeline (best-effort — KHR-centric for now, like the web).
      Map<String, dynamic>? charts;
      try {
        charts = await _api.getChartsTimeline(null, 'KHR', _valuationMode);
      } catch (_) {}
      setState(() {
        _portfolio = portfolio;
        _yearlyPnl = yearly;
        _chartsData = charts;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingPortfolio('$e'))),
        );
      }
    }
  }

  double _value(dynamic h) =>
      ((h['remainingQty'] as num?)?.toDouble() ?? 0) * ((h['lastPrice'] as num?)?.toDouble() ?? 0);

  /// Total value per currency (for allocation math) — never blended.
  Map<String, double> get _valueByCurrency {
    final m = <String, double>{};
    for (final h in _portfolio) {
      final ccy = (h['currency'] as String?) ?? 'KHR';
      m[ccy] = (m[ccy] ?? 0) + _value(h);
    }
    return m;
  }

  List<dynamic> get _visible {
    final q = _query.trim().toUpperCase();
    final list = _portfolio.where((h) {
      if (q.isEmpty) return true;
      return (h['ticker'] ?? '').toString().toUpperCase().contains(q);
    }).toList();
    list.sort((a, b) {
      switch (_sort) {
        case _Sort.value:
          return _value(b).compareTo(_value(a));
        case _Sort.pnl:
          return ((b['totalPnl'] as num?) ?? 0).compareTo((a['totalPnl'] as num?) ?? 0);
        case _Sort.name:
          return (a['ticker'] ?? '').toString().compareTo((b['ticker'] ?? '').toString());
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: _loadPortfolio,
      child: _loading
          ? ListView(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, context.navBarClearance),
              children: const [
                Skeleton.card(height: 130),
                SizedBox(height: AppSpacing.lg),
                Skeleton.card(height: 96),
                SizedBox(height: AppSpacing.md),
                Skeleton.card(height: 96),
                SizedBox(height: AppSpacing.md),
                Skeleton.card(height: 96),
              ],
            )
          : _portfolio.isEmpty
              ? _emptyState(context, l10n)
              : _buildList(context, l10n),
    );
  }

  Widget _buildList(BuildContext context, AppLocalizations l10n) {
    final valueByCcy = _valueByCurrency;
    final summaries = _buildSummaries(valueByCcy);
    final visible = _visible;

    // Split like the web: open positions vs fully-closed ones (remainingQty 0).
    final current = visible.where((h) => ((h['remainingQty'] as num?) ?? 0) > 0).toList();
    final closed = visible.where((h) => ((h['remainingQty'] as num?) ?? 0) <= 0).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, context.navBarClearance),
      children: [
        Align(alignment: Alignment.centerRight, child: _valuationToggle(context)),
        const SizedBox(height: AppSpacing.md),
        ...summaries,
        const SizedBox(height: AppSpacing.sm),
        SectionHeader(title: l10n.portfolioPerformance),
        AppCard(child: _buildEquityChart(context, 'KHR')),
        const SizedBox(height: AppSpacing.lg),
        _searchAndSort(context),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('No match for "$_query"',
                    style: TextStyle(color: context.colors.textMuted)),
              ),
            ),
          )
        else ...[
          SectionHeader(title: 'Current Holdings · ${current.length}'),
          if (current.isEmpty)
            AppCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text('No open positions',
                      style: TextStyle(color: context.colors.textMuted)),
                ),
              ),
            )
          else
            for (final h in current) ...[
              _positionCard(context, h, valueByCcy),
              const SizedBox(height: AppSpacing.md),
            ],
          if (closed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SectionHeader(title: 'Closed Positions · ${closed.length}'),
            for (final h in closed) ...[
              _positionCard(context, h, valueByCcy),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ],
        if (_yearlyPnl.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _yearlyPnlPanel(context),
        ],
      ],
    );
  }

  // ── Realised P/L by year (parity with the web portfolio) ─────────────
  Widget _yearlyPnlPanel(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '📅 Realized P/L by year'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              for (int i = 0; i < _yearlyPnl.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: c.border.withValues(alpha: 0.6)),
                _yearRow(c, _yearlyPnl[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _yearRow(AppColors c, dynamic y) {
    final year = y['year'];
    final ccy = (y['currency'] as String?) ?? 'KHR';
    final pnl = (y['realisedPnl'] as num?) ?? 0;
    final sells = (y['sellCount'] as num?)?.toInt() ?? 0;
    final col = pnl >= 0 ? c.profit : c.loss;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text('$year', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(width: 6),
          Text('· $ccy', style: TextStyle(color: c.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Text('$sells ${sells == 1 ? 'sell' : 'sells'}',
              style: TextStyle(color: c.textMuted, fontSize: 12)),
          const Spacer(),
          Text(Money.format(pnl, ccy, signed: true),
              style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }

  // ── Valuation toggle (BID/ASK) ──────────────────────────────────────
  Widget _valuationToggle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget seg(String label, bool selected, VoidCallback onTap) {
      final c = context.colors;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? c.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? c.onPrimary : c.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(l10n.valuationBid, _valuationMode == 'BID', () {
            if (_valuationMode != 'BID') {
              setState(() => _valuationMode = 'BID');
              _loadPortfolio();
            }
          }),
          seg(l10n.valuationAsk, _valuationMode == 'ASK', () {
            if (_valuationMode != 'ASK') {
              setState(() => _valuationMode = 'ASK');
              _loadPortfolio();
            }
          }),
        ],
      ),
    );
  }

  // ── Equity performance chart ────────────────────────────────────────

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

  Widget _buildEquityChart(BuildContext context, String ccy) {
    final c = context.colors;
    final equityRaw = _chartsData?['equity'];
    final hasAny = equityRaw is List && equityRaw.isNotEmpty;
    if (!hasAny) {
      return SizedBox(height: 200, child: _emptyChart(context, 'Record a trade to see your equity curve'));
    }
    final series = _equitySeries();
    final hasRange = series.value.isNotEmpty;

    final currentValue = hasRange ? series.value.last.y : 0.0;
    final startValue = hasRange ? series.value.first.y : 0.0;
    final change = currentValue - startValue;
    final pct = startValue != 0 ? (change / startValue) * 100 : 0.0;
    final plColor = change >= 0 ? c.profit : c.loss;
    final valueColor = hasRange && change >= 0 ? c.profit : c.loss;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

  // ── Per-currency summary cards ──────────────────────────────────────
  List<Widget> _buildSummaries(Map<String, double> valueByCcy) {
    // Aggregate invested & unrealised per currency.
    final invested = <String, double>{};
    final unrealised = <String, double>{};
    for (final h in _portfolio) {
      final ccy = (h['currency'] as String?) ?? 'KHR';
      final qty = (h['remainingQty'] as num?)?.toDouble() ?? 0;
      final avg = (h['avgCostRemaining'] as num?)?.toDouble() ?? 0;
      invested[ccy] = (invested[ccy] ?? 0) + qty * avg;
      unrealised[ccy] = (unrealised[ccy] ?? 0) + ((h['unrealisedPnl'] as num?)?.toDouble() ?? 0);
    }
    final ccys = valueByCcy.keys.toList()
      ..sort((a, b) => a == 'KHR' ? -1 : (b == 'KHR' ? 1 : b.compareTo(a)));

    return [
      for (final ccy in ccys)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _summaryCard(
            context,
            ccy,
            value: valueByCcy[ccy] ?? 0,
            invested: invested[ccy] ?? 0,
            unrealised: unrealised[ccy] ?? 0,
          ),
        ),
    ];
  }

  Widget _summaryCard(BuildContext context, String ccy,
      {required double value, required double invested, required double unrealised}) {
    final c = context.colors;
    final legend = _allocationLegend(ccy, value);

    return AppCard(
      gradient: c.primaryGradient,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _coin(ccy),
              const SizedBox(width: AppSpacing.sm),
              Text('$ccy PORTFOLIO',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const Spacer(),
              _pill(context, Money.format(unrealised, ccy, signed: true)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(Money.format(value, ccy),
              style: const TextStyle(
                  color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: AppSpacing.lg),
          // Allocation bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: Row(
              children: [
                for (final s in legend)
                  Expanded(
                    flex: (s.fraction * 1000).round().clamp(1, 1000),
                    child: Container(height: 8, color: s.color),
                  ),
              ],
            ),
          ),
          if (legend.length > 1 || (legend.isNotEmpty && legend.first.label.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: 6,
              children: [
                for (final s in legend.where((s) => s.label.isNotEmpty))
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text('${s.label} ${(s.fraction * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _miniStat('Invested', Money.format(invested, ccy)),
              ),
              Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _miniStat('Holdings', '${_holdingsIn(ccy)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _pill(BuildContext context, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      );

  int _holdingsIn(String ccy) =>
      _portfolio.where((h) => ((h['currency'] as String?) ?? 'KHR') == ccy && ((h['remainingQty'] as num?) ?? 0) > 0).length;

  /// Top holdings as coloured segments (with ticker labels) for the allocation
  /// bar + legend. Anything past the palette size is folded into an "Other" tail.
  List<_Segment> _allocationLegend(String ccy, double total) {
    if (total <= 0) return [_Segment(1, Colors.white.withValues(alpha: 0.3), '')];
    final holdings = _portfolio
        .where((h) => ((h['currency'] as String?) ?? 'KHR') == ccy && _value(h) > 0)
        .toList()
      ..sort((a, b) => _value(b).compareTo(_value(a)));
    const maxLabelled = 4;
    final segs = <_Segment>[];
    double otherFraction = 0;
    for (int i = 0; i < holdings.length; i++) {
      final frac = _value(holdings[i]) / total;
      if (i < maxLabelled) {
        segs.add(_Segment(frac, _allocPalette[i % _allocPalette.length],
            (holdings[i]['ticker'] ?? '').toString()));
      } else {
        otherFraction += frac;
      }
    }
    if (otherFraction > 0) {
      segs.add(_Segment(otherFraction, Colors.white.withValues(alpha: 0.35), 'Other'));
    }
    return segs.isEmpty ? [_Segment(1, Colors.white.withValues(alpha: 0.3), '')] : segs;
  }

  /// A coin-style circular badge showing the currency symbol (ByteTown token
  /// look) — glassy white on the gradient card.
  Widget _coin(String ccy) {
    final symbol = ccy == 'USD' ? r'$' : '៛';
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(symbol,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
    );
  }

  // ── Position card ───────────────────────────────────────────────────
  Widget _positionCard(BuildContext context, dynamic h, Map<String, double> valueByCcy) {
    final c = context.colors;
    final ccy = (h['currency'] as String?) ?? 'KHR';
    final market = (h['market'] as String?) ?? 'CSX';
    final totalPnl = (h['totalPnl'] as num?) ?? 0;
    final qty = (h['remainingQty'] as num?) ?? 0;
    final lastPrice = h['lastPrice'] as num?;
    final avgCost = h['avgCostRemaining'] as num?;
    final soldPct = (h['soldPercent'] as num?)?.toDouble() ?? 0;
    final value = _value(h);
    final ccyTotal = valueByCcy[ccy] ?? 0;
    final alloc = ccyTotal > 0 ? value / ccyTotal : 0.0;

    final invested = (avgCost?.toDouble() ?? 0) * qty.toDouble();
    final pnlPct = invested > 0 ? (totalPnl.toDouble() / invested) * 100 : null;
    final pnlColor = totalPnl >= 0 ? c.profit : c.loss;
    final spots = (h['spots'] as List?)?.cast<double>() ?? const [];
    final qtyStr = qty is int ? '$qty' : qty.toStringAsFixed(0);

    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PositionDetailsScreen(
                ticker: h['ticker'], currency: ccy, lastPrice: lastPrice)),
        ).then((_) => _loadPortfolio());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: coin · ticker · market  |  Value + P/L%
          Row(
            children: [
              _tickerCoin(context, (h['ticker'] ?? '').toString(), market),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${h['ticker'] ?? ''}',
                          style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      _marketBadge(context, market),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${(alloc * 100).toStringAsFixed(0)}% of $ccy',
                      style: TextStyle(color: c.textMuted, fontSize: 11)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Money.format(value, ccy),
                      style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(totalPnl >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 13, color: pnlColor),
                      Flexible(
                        child: Text(
                            pnlPct == null
                                ? Money.format(totalPnl, ccy, signed: true)
                                : '${Money.format(totalPnl, ccy, signed: true)} · ${totalPnl >= 0 ? '+' : '−'}${pnlPct.abs().toStringAsFixed(1)}%',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: pnlColor, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (spots.length >= 2) ...[
            const SizedBox(height: AppSpacing.md),
            Sparkline(values: spots, color: pnlColor, height: 44),
          ],
          const SizedBox(height: AppSpacing.md),
          // Stat chips (same surfaceAlt tile look as the dashboard quick-stats)
          Row(
            children: [
              _statChip(c, 'Qty', qtyStr),
              const SizedBox(width: AppSpacing.sm),
              _statChip(c, 'Last', lastPrice == null ? '—' : Money.format(lastPrice, ccy)),
              const SizedBox(width: AppSpacing.sm),
              _statChip(c, 'Avg cost', avgCost == null ? '—' : Money.format(avgCost, ccy)),
              if (soldPct > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                _statChip(c, 'Sold', '${soldPct.toStringAsFixed(0)}%'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(AppColors c, String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: c.surfaceAlt,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: c.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );

  /// Round token avatar for a position — the ticker's first 1-2 letters on a
  /// market-tinted disc (ByteTown coin look).
  Widget _tickerCoin(BuildContext context, String ticker, String market) {
    final color = switch (market) {
      'US' => const Color(0xFF8B5CF6),
      'GOLD_KH' => const Color(0xFFF59E0B),
      _ => context.colors.primary,
    };
    final initials = ticker.isEmpty
        ? '?'
        : ticker.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').padRight(2).substring(0, 2).toUpperCase();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(initials,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
    );
  }

  Widget _marketBadge(BuildContext context, String market) {
    final color = switch (market) {
      'US' => const Color(0xFF8B5CF6),
      'GOLD_KH' => const Color(0xFFF59E0B),
      _ => context.colors.primary,
    };
    final label = switch (market) {
      'GOLD_KH' => 'GOLD',
      _ => market,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }

  // ── Search + sort ───────────────────────────────────────────────────
  Widget _searchAndSort(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: c.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search ticker',
              prefixIcon: Icon(Icons.search_rounded, color: c.textMuted, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: c.surfaceAlt,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: c.border),
          ),
          child: PopupMenuButton<_Sort>(
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            color: c.surface,
            icon: Icon(Icons.sort_rounded, color: c.textSecondary),
            itemBuilder: (_) => [
              _sortItem(_Sort.value, 'Value', c),
              _sortItem(_Sort.pnl, 'Profit / Loss', c),
              _sortItem(_Sort.name, 'Name', c),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<_Sort> _sortItem(_Sort s, String label, AppColors c) => PopupMenuItem(
        value: s,
        child: Row(
          children: [
            Icon(_sort == s ? Icons.check_rounded : Icons.remove, size: 16, color: c.primary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: c.textPrimary)),
          ],
        ),
      );

  // ── Empty state ─────────────────────────────────────────────────────
  Widget _emptyState(BuildContext context, AppLocalizations l10n) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.pie_chart_outline_rounded, size: 64, color: c.textMuted),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.noActivePositions,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Text('Record your first trade with the + button to start tracking your positions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textMuted, fontSize: 14, height: 1.4)),
      ],
    );
  }
}

class _Segment {
  final double fraction;
  final Color color;
  final String label;
  _Segment(this.fraction, this.color, this.label);
}

const _allocPalette = [
  Color(0xFF60A5FA),
  Color(0xFF34D399),
  Color(0xFFFBBF24),
  Color(0xFFA78BFA),
  Color(0xFFF472B6),
  Color(0xFF22D3EE),
  Color(0xFFFB923C),
];
