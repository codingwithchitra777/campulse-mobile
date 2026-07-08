import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class PositionDetailsScreen extends StatefulWidget {
  final String ticker;
  const PositionDetailsScreen({super.key, required this.ticker});

  @override
  State<PositionDetailsScreen> createState() => _PositionDetailsScreenState();
}

class _PositionDetailsScreenState extends State<PositionDetailsScreen> {
  static const Color emerald = Color(0xFF10B981);
  final ApiService _api = ApiService.instance;
  bool _loading = false;
  Map<String, dynamic>? _details;

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
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.detailsTitle(widget.ticker)),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _details == null
              ? Center(child: Text(l10n.failedToLoadDetails, style: const TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Row
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151B2C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF24304F)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem(l10n.totalBought, numberFormat.format(_details!['totalBoughtQty'] ?? 0)),
                            _buildSummaryItem(l10n.totalSold, numberFormat.format(_details!['totalSoldQty'] ?? 0)),
                            _buildSummaryItem(l10n.remaining, numberFormat.format(_details!['remainingQty'] ?? 0)),
                            _buildSummaryItem(
                              l10n.realisedPnlLabel,
                              '${(_details!['realisedPnl'] ?? 0) >= 0 ? '+' : ''}${numberFormat.format(_details!['realisedPnl'] ?? 0)}',
                              valueColor: (_details!['realisedPnl'] ?? 0) >= 0 ? emerald : Colors.redAccent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Buy Orders
                      Text(
                        l10n.buyOrdersTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: emerald),
                      ),
                      const SizedBox(height: 12),
                      _buildOrdersCard(
                        children: (_details!['buys'] as List).isEmpty
                            ? [_buildEmptyRow(l10n.noBuyOrders)]
                            : (_details!['buys'] as List)
                                .map((buy) => _buildBuyOrderRow(buy, numberFormat, l10n))
                                .toList(),
                      ),
                      const SizedBox(height: 24),

                      // Sell Orders
                      Text(
                        l10n.sellOrdersTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                      const SizedBox(height: 12),
                      _buildOrdersCard(
                        children: (_details!['sells'] as List).isEmpty
                            ? [_buildEmptyRow(l10n.noSellOrders)]
                            : (_details!['sells'] as List)
                                .map((sell) => _buildSellOrderRow(sell, numberFormat, l10n))
                                .toList(),
                      ),
                      const SizedBox(height: 24),

                      // Buy Lots List
                      Text(
                        l10n.buyLotsAllocation,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (_details!['remainingLots'] as List).length,
                        itemBuilder: (context, index) {
                          final lot = _details!['remainingLots'][index];
                          final qtyOpen = (lot['qtyOpen'] as num? ?? 0).toInt();
                          final qtyOriginal = (lot['qtyOriginal'] as num? ?? qtyOpen).toInt();
                          final price = (lot['price'] as num? ?? 0).toInt();
                          
                          // Parse date string
                          String dateStr = '';
                          try {
                            final parsedDate = DateTime.parse(lot['orderDate']);
                            dateStr = DateFormat.yMMMd().format(parsedDate);
                          } catch (_) {
                            dateStr = lot['orderDate'].toString();
                          }

                          return Card(
                            color: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFF24304F)),
                            ),
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          l10n.seqLabel('${lot['seq']}'),
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.fiber_manual_record,
                                            color: qtyOpen > 0 ? emerald : Colors.white24,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            qtyOpen > 0 ? l10n.lotOpen : l10n.lotSold,
                                            style: TextStyle(
                                              color: qtyOpen > 0 ? emerald : Colors.grey,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                           Text(l10n.remainingQtyLabel, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                           const SizedBox(height: 2),
                                           Text(l10n.qtyOverQty(numberFormat.format(qtyOpen), numberFormat.format(qtyOriginal)), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(l10n.pricePerShareColumn, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                          const SizedBox(height: 2),
                                          Text('${numberFormat.format(price)} riel', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Color(0xFF24304F), height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if ((_details!['remainingLots'] as List).isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: Text(l10n.noOpenLots, style: const TextStyle(color: Colors.grey))),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor ?? Colors.white),
        ),
      ],
    );
  }

  Widget _buildOrdersCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF24304F)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildEmptyRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13))),
    );
  }

  Widget _buildBuyOrderRow(dynamic buy, NumberFormat numberFormat, AppLocalizations l10n) {
    final seq = '${buy['seq']}';
    final qtyOpen = (buy['qtyOpen'] as num? ?? 0).toInt();
    final qtyOriginal = (buy['qtyOriginal'] as num? ?? 0).toInt();
    final price = (buy['price'] as num? ?? 0).toInt();
    final isOpen = qtyOpen > 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF24304F), width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.fiber_manual_record, color: isOpen ? emerald : Colors.white24, size: 8),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: Text(
              isOpen ? l10n.openSeqLabel(seq) : l10n.soldSeqLabel(seq),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isOpen ? Colors.white : Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              l10n.qtyAtPrice(numberFormat.format(qtyOriginal), numberFormat.format(price)),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              numberFormat.format(qtyOpen),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isOpen ? emerald : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellOrderRow(dynamic sell, NumberFormat numberFormat, AppLocalizations l10n) {
    final seq = '${sell['seq']}';
    final qty = (sell['qty'] as num? ?? 0).toInt();
    final price = (sell['price'] as num? ?? 0).toInt();
    final pnl = (sell['pnl'] as num? ?? 0).toInt();
    final matched = (sell['matched'] as List?) ?? const [];
    final isProfit = pnl >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF24304F), width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('#$seq', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  l10n.qtyAtPrice(numberFormat.format(qty), numberFormat.format(price)),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${isProfit ? '+' : ''}${numberFormat.format(pnl)}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isProfit ? emerald : Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          if (matched.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: matched.map((m) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Text(
                      l10n.matchedRow('${m['buySeq']}', numberFormat.format((m['qty'] as num? ?? 0).toInt()), numberFormat.format((m['price'] as num? ?? 0).toInt())),
                      style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
