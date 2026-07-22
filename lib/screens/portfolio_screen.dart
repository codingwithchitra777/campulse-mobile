import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import '../widgets/app_card.dart';
import '../widgets/pnl_chip.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';
import 'position_details_screen.dart';

enum _Sort { value, pnl, name }

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = false;
  List<dynamic> _portfolio = [];
  String _query = '';
  _Sort _sort = _Sort.value;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    setState(() => _loading = true);
    try {
      final portfolio = await _api.getPortfolio();
      setState(() {
        _portfolio = portfolio;
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
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 110),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 110),
      children: [
        ...summaries,
        const SizedBox(height: AppSpacing.lg),
        _searchAndSort(context),
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: '${l10n.titlePortfolio} · ${visible.length}'),
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
        else
          for (final h in visible) ...[
            _positionCard(context, h, valueByCcy),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
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

    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PositionDetailsScreen(ticker: h['ticker'])),
        ).then((_) => _loadPortfolio());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _tickerCoin(context, (h['ticker'] ?? '').toString(), market),
              const SizedBox(width: AppSpacing.md),
              Text('${h['ticker'] ?? ''}',
                  style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(width: AppSpacing.sm),
              _marketBadge(context, market),
              const Spacer(),
              PnlChip(value: totalPnl, currency: ccy),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cell(context, 'Value', Money.format(value, ccy)),
              _cell(context, 'Qty', '${qty is int ? qty : qty.toStringAsFixed(0)}'),
              _cell(context, 'Last', lastPrice == null ? '—' : Money.format(lastPrice, ccy)),
              _cell(context, 'Avg cost', avgCost == null ? '—' : Money.format(avgCost, ccy),
                  alignEnd: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Allocation of this position within its currency
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: LinearProgressIndicator(
                    value: alloc.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: c.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation(c.primary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${(alloc * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          if (soldPct > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('${soldPct.toStringAsFixed(0)}% sold',
                style: TextStyle(color: c.textMuted, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, String label, String value, {bool alignEnd = false}) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: c.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

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
