import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color emerald = Color(0xFF10B981);
  final ApiService _api = ApiService.instance;
  bool _loading = false;
  List<dynamic> _trades = [];

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat('#,###');

    return RefreshIndicator(
      onRefresh: _loadTrades,
      child: _trades.isEmpty
          ? Center(
              child: Text(
                l10n.noTradesRecorded,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _trades.length,
              itemBuilder: (context, index) {
                final t = _trades[index];
                final isBuy = t['side'] == 'BUY';
                final color = isBuy ? emerald : Colors.redAccent;
                
                // Parse date
                String dateStr = '';
                try {
                  final parsedDate = DateTime.parse(t['orderDate']);
                  dateStr = DateFormat.yMMMd().add_jm().format(parsedDate);
                } catch (_) {
                  dateStr = t['orderDate'].toString();
                }

                return Card(
                  color: const Color(0xFF151B2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF24304F)),
                  ),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '#${t['seq']}',
                                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  t['ticker'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Text(
                                isBuy ? l10n.sideBuy : l10n.sideSell,
                                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
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
                                Text(l10n.pricePerShareColumn, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text('${numberFormat.format(t['price'] ?? 0)} riel', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(l10n.quantityColumn, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(l10n.quantityValue(numberFormat.format(t['qty'] ?? 0)), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(l10n.commissionColumn, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text('${numberFormat.format(t['commission'] ?? 0)} riel', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF24304F), height: 24),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 12, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
