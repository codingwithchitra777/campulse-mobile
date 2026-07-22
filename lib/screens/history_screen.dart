import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _Filter { all, buy, sell }

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = false;
  List<dynamic> _trades = [];
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _loadTrades();
  }

  Future<void> _loadTrades() async {
    setState(() => _loading = true);
    try {
      final trades = await _api.getTrades();
      setState(() {
        _trades = trades;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingHistory('$e'))),
        );
      }
    }
  }

  List<dynamic> get _visible {
    final q = _query.trim().toUpperCase();
    return _trades.where((t) {
      final side = (t['side'] ?? '').toString();
      if (_filter == _Filter.buy && side != 'BUY') return false;
      if (_filter == _Filter.sell && side != 'SELL') return false;
      if (q.isNotEmpty && !(t['ticker'] ?? '').toString().toUpperCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: _loadTrades,
      child: _loading
          ? ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, context.navBarClearance),
              children: const [
                Skeleton(width: 180, height: 40),
                SizedBox(height: AppSpacing.lg),
                Skeleton.card(height: 92),
                SizedBox(height: AppSpacing.md),
                Skeleton.card(height: 92),
                SizedBox(height: AppSpacing.md),
                Skeleton.card(height: 92),
              ],
            )
          : _trades.isEmpty
              ? _emptyState(context, l10n)
              : _buildList(context, l10n),
    );
  }

  Widget _buildList(BuildContext context, AppLocalizations l10n) {
    final visible = _visible;
    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, context.navBarClearance),
      children: [
        _searchField(context),
        const SizedBox(height: AppSpacing.md),
        _filterChips(context, l10n),
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: '${visible.length} ${visible.length == 1 ? 'trade' : 'trades'}'),
        if (visible.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('No matching trades',
                    style: TextStyle(color: context.colors.textMuted)),
              ),
            ),
          )
        else
          for (final t in visible) ...[
            _tradeRow(context, t, l10n),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }

  Widget _tradeRow(BuildContext context, dynamic t, AppLocalizations l10n) {
    final c = context.colors;
    final isBuy = t['side'] == 'BUY';
    final sideColor = isBuy ? c.profit : c.loss;
    final ccy = (t['currency'] as String?) ?? 'KHR';
    final market = (t['market'] as String?) ?? 'CSX';
    final price = (t['price'] as num?) ?? 0;
    final qty = (t['qty'] as num?) ?? 0;
    final commission = (t['commission'] as num?) ?? 0;
    final total = price * qty;
    final isBonus = t['corpActionId'] != null;

    String dateStr = '';
    try {
      dateStr = DateFormat('d MMM yyyy · h:mm a').format(DateTime.parse(t['orderDate']));
    } catch (_) {
      dateStr = (t['orderDate'] ?? '').toString();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Ticker coin avatar with a buy/sell direction badge in the corner.
              _tradeCoin(context, (t['ticker'] ?? '').toString(), market, isBuy, sideColor),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${t['ticker'] ?? ''}',
                          style: TextStyle(
                              color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      _marketBadge(context, market),
                      if (isBonus) ...[
                        const SizedBox(width: 4),
                        _bonusBadge(context),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('#${t['seq']} · ${isBuy ? l10n.sideBuy : l10n.sideSell}',
                      style: TextStyle(color: sideColor, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Money.format(total, ccy),
                      style: TextStyle(
                          color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text('${_qty(qty)} @ ${Money.format(price, ccy)}',
                      style: TextStyle(color: c.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 1, color: c.border.withValues(alpha: 0.6)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 13, color: c.textMuted),
              const SizedBox(width: 5),
              Text(dateStr, style: TextStyle(color: c.textMuted, fontSize: 12)),
              const Spacer(),
              if (commission > 0)
                Text('fee ${Money.format(commission, ccy)}',
                    style: TextStyle(color: c.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _qty(num q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  /// Ticker coin (market-tinted gradient disc with initials) plus a small
  /// buy/sell arrow badge in the bottom-right corner — matches the portfolio
  /// coin look while preserving the trade direction cue.
  Widget _tradeCoin(BuildContext context, String ticker, String market, bool isBuy, Color sideColor) {
    final color = switch (market) {
      'US' => const Color(0xFF8B5CF6),
      'GOLD_KH' => const Color(0xFFF59E0B),
      _ => context.colors.primary,
    };
    final initials = ticker.isEmpty
        ? '?'
        : ticker.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').padRight(2).substring(0, 2).toUpperCase();
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Text(initials,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sideColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.surface, width: 2),
              ),
              child: Icon(
                isBuy ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marketBadge(BuildContext context, String market) {
    final color = switch (market) {
      'US' => const Color(0xFF8B5CF6),
      'GOLD_KH' => const Color(0xFFF59E0B),
      _ => context.colors.primary,
    };
    final label = market == 'GOLD_KH' ? 'GOLD' : market;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }

  Widget _bonusBadge(BuildContext context) {
    final color = context.colors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text('🎁 BONUS',
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  Widget _searchField(BuildContext context) {
    final c = context.colors;
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search ticker',
        prefixIcon: Icon(Icons.search_rounded, color: c.textMuted, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
    );
  }

  Widget _filterChips(BuildContext context, AppLocalizations l10n) {
    Widget chip(_Filter f, String label) {
      final c = context.colors;
      final selected = _filter == f;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: GestureDetector(
          onTap: () => setState(() => _filter = f),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected ? c.primary : c.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: selected ? c.primary : c.border),
            ),
            child: Text(label,
                style: TextStyle(
                    color: selected ? c.onPrimary : c.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(_Filter.all, 'All'),
        chip(_Filter.buy, l10n.sideBuy),
        chip(_Filter.sell, l10n.sideSell),
      ],
    );
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.receipt_long_outlined, size: 64, color: c.textMuted),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.noTradesRecorded,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Text('Your recorded buys and sells will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textMuted, fontSize: 14, height: 1.4)),
      ],
    );
  }
}
