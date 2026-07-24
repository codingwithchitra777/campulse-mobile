import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import '../widgets/app_card.dart';
import '../widgets/skeleton.dart';

class PositionDetailsScreen extends StatefulWidget {
  final String ticker;
  final String currency;
  final num? lastPrice;

  const PositionDetailsScreen({
    super.key,
    required this.ticker,
    this.currency = 'KHR',
    this.lastPrice,
  });

  @override
  State<PositionDetailsScreen> createState() => _PositionDetailsScreenState();
}

class _PositionDetailsScreenState extends State<PositionDetailsScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = false;
  Map<String, dynamic>? _details;

  String get _ccy => widget.currency;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _loading = true);
    try {
      final details = await _api.getPosition(widget.ticker);
      setState(() {
        _details = details;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingPosition('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.detailsTitle(widget.ticker))),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: const [
                Skeleton.card(height: 96),
                SizedBox(height: AppSpacing.lg),
                Skeleton.card(height: 120),
                SizedBox(height: AppSpacing.lg),
                Skeleton.card(height: 120),
              ],
            )
          : _details == null
              ? Center(child: Text(l10n.failedToLoadDetails, style: TextStyle(color: c.textMuted)))
              : _content(context, l10n, c),
    );
  }

  Widget _content(BuildContext context, AppLocalizations l10n, AppColors c) {
    final nf = NumberFormat('#,###');
    final realised = (_details!['realisedPnl'] as num?) ?? 0;
    final buys = (_details!['buys'] as List?) ?? const [];
    final sells = (_details!['sells'] as List?) ?? const [];
    final lots = (_details!['remainingLots'] as List?) ?? const [];

    // Open-position (unrealised) P/L from the remaining lots vs current price.
    num openQty = 0, costBasis = 0;
    for (final lot in lots) {
      final q = (lot['qtyOpen'] as num? ?? 0);
      final p = (lot['price'] as num? ?? 0);
      openQty += q;
      costBasis += p * q;
    }
    final last = widget.lastPrice;
    final currentValue = last != null ? last * openQty : null;
    final unreal = currentValue != null ? currentValue - costBasis : null;
    final unrealPct = (unreal != null && costBasis > 0) ? (unreal / costBasis) * 100 : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        if (openQty > 0) ...[
          _openPnlHero(c, currentValue, unreal, unrealPct, costBasis),
          const SizedBox(height: AppSpacing.lg),
        ],
        // Summary
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summary(c, l10n.totalBought, nf.format(_details!['totalBoughtQty'] ?? 0)),
              _summary(c, l10n.totalSold, nf.format(_details!['totalSoldQty'] ?? 0)),
              _summary(c, l10n.remaining, nf.format(_details!['remainingQty'] ?? 0)),
              _summary(c, l10n.realisedPnlLabel, Money.format(realised, _ccy, signed: true),
                  color: c.pnl(realised)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Buy orders
        _sectionTitle(c, l10n.buyOrdersTitle, c.profit),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: buys.isEmpty
              ? _empty(c, l10n.noBuyOrders)
              : Column(children: [for (final b in buys) _buyOrderRow(c, l10n, nf, b)]),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Sell orders
        _sectionTitle(c, l10n.sellOrdersTitle, c.loss),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: sells.isEmpty
              ? _empty(c, l10n.noSellOrders)
              : Column(children: [for (final s in sells) _sellOrderRow(c, l10n, nf, s)]),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Remaining buy lots
        _sectionTitle(c, l10n.buyLotsAllocation, c.textPrimary),
        const SizedBox(height: AppSpacing.sm),
        if (lots.isEmpty)
          AppCard(child: Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(l10n.noOpenLots, style: TextStyle(color: c.textMuted)),
          )))
        else
          for (final lot in lots) ...[
            _lotCard(c, l10n, nf, lot),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }

  Widget _openPnlHero(AppColors c, num? currentValue, num? unreal, double? unrealPct, num costBasis) {
    final color = (unreal ?? 0) >= 0 ? c.profit : c.loss;
    return AppCard(
      gradient: c.primaryGradient,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OPEN POSITION',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          Text(currentValue == null ? '—' : Money.format(currentValue, _ccy),
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          if (unreal != null && unrealPct != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(unreal >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 15, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('${Money.format(unreal, _ccy, signed: true)}  '
                      '(${unreal >= 0 ? '+' : '−'}${unrealPct.abs().toStringAsFixed(2)}%)',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            )
          else
            Text('Cost ${Money.format(costBasis, _ccy)}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
          const SizedBox(height: 6),
          Text('unrealised · cost ${Money.format(costBasis, _ccy)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _summary(AppColors c, String label, String value, {Color? color}) => Column(
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 10, color: c.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color ?? c.textPrimary)),
        ],
      );

  Widget _sectionTitle(AppColors c, String text, Color color) =>
      Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color));

  Widget _empty(AppColors c, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: Text(text, style: TextStyle(color: c.textMuted, fontSize: 13))),
      );

  Widget _buyOrderRow(AppColors c, AppLocalizations l10n, NumberFormat nf, dynamic buy) {
    final seq = '${buy['seq']}';
    final qtyOpen = (buy['qtyOpen'] as num? ?? 0).toInt();
    final qtyOriginal = (buy['qtyOriginal'] as num? ?? 0).toInt();
    final price = (buy['price'] as num? ?? 0);
    final isOpen = qtyOpen > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border.withValues(alpha: 0.6)))),
      child: Row(
        children: [
          Icon(Icons.fiber_manual_record, color: isOpen ? c.profit : c.textMuted, size: 8),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: Text(isOpen ? l10n.openSeqLabel(seq) : l10n.soldSeqLabel(seq),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isOpen ? c.textPrimary : c.textMuted)),
          ),
          Expanded(
            flex: 3,
            child: Text(l10n.qtyAtPrice(nf.format(qtyOriginal), Money.format(price, _ccy)),
                style: TextStyle(fontSize: 12, color: c.textMuted)),
          ),
          Expanded(
            flex: 2,
            child: Text(nf.format(qtyOpen),
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isOpen ? c.profit : c.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _sellOrderRow(AppColors c, AppLocalizations l10n, NumberFormat nf, dynamic sell) {
    final seq = '${sell['seq']}';
    final qty = (sell['qty'] as num? ?? 0).toInt();
    final price = (sell['price'] as num? ?? 0);
    final pnl = (sell['pnl'] as num? ?? 0);
    final matched = (sell['matched'] as List?) ?? const [];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border.withValues(alpha: 0.6)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(flex: 2, child: Text('#$seq', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textPrimary))),
              Expanded(
                flex: 3,
                child: Text(l10n.qtyAtPrice(nf.format(qty), Money.format(price, _ccy)),
                    style: TextStyle(fontSize: 12, color: c.textMuted)),
              ),
              Expanded(
                flex: 2,
                child: Text(Money.format(pnl, _ccy, signed: true),
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.pnl(pnl))),
              ),
            ],
          ),
          if (matched.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final m in matched)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                      child: Text(
                          l10n.matchedRow('${m['buySeq']}', nf.format((m['qty'] as num? ?? 0).toInt()),
                              Money.format((m['price'] as num? ?? 0), _ccy)),
                          style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: c.textMuted)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _lotCard(AppColors c, AppLocalizations l10n, NumberFormat nf, dynamic lot) {
    final qtyOpen = (lot['qtyOpen'] as num? ?? 0).toInt();
    final qtyOriginal = (lot['qtyOriginal'] as num? ?? qtyOpen).toInt();
    final price = (lot['price'] as num? ?? 0);
    final isOpen = qtyOpen > 0;

    // Per-lot change vs the current price (passed from the portfolio card).
    final last = widget.lastPrice;
    num? change;
    double? changePct;
    if (last != null && price > 0) {
      change = (last - price) * qtyOpen;
      changePct = (last - price) / price * 100;
    }
    final changeColor = (change ?? 0) >= 0 ? c.profit : c.loss;

    String dateStr = '';
    try {
      dateStr = DateFormat.yMMMd().format(DateTime.parse(lot['orderDate']));
    } catch (_) {
      dateStr = (lot['orderDate'] ?? '').toString();
    }

    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(l10n.seqLabel('${lot['seq']}'),
                    style: TextStyle(color: c.primary, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              Row(
                children: [
                  Icon(Icons.fiber_manual_record, color: isOpen ? c.profit : c.textMuted, size: 12),
                  const SizedBox(width: 4),
                  Text(isOpen ? l10n.lotOpen : l10n.lotSold,
                      style: TextStyle(color: isOpen ? c.profit : c.textMuted, fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.remainingQtyLabel, style: TextStyle(color: c.textMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(l10n.qtyOverQty(nf.format(qtyOpen), nf.format(qtyOriginal)),
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l10n.pricePerShareColumn, style: TextStyle(color: c.textMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(Money.format(price, _ccy),
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
                ],
              ),
            ],
          ),
          if (change != null && changePct != null) ...[
            Divider(color: c.border.withValues(alpha: 0.6), height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Change (vs ${Money.format(last!, _ccy)})',
                    style: TextStyle(color: c.textMuted, fontSize: 12)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(change >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 14, color: changeColor),
                    const SizedBox(width: 2),
                    Text(Money.format(change, _ccy, signed: true),
                        style: TextStyle(color: changeColor, fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text('${change >= 0 ? '+' : '−'}${changePct.abs().toStringAsFixed(1)}%',
                          style: TextStyle(color: changeColor, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: c.textMuted),
              const SizedBox(width: 6),
              Text(dateStr, style: TextStyle(color: c.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
