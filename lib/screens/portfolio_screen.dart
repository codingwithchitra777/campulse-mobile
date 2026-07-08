import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import 'position_details_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  static const Color emerald = Color(0xFF10B981);
  final ApiService _api = ApiService.instance;
  bool _loading = false;
  List<dynamic> _portfolio = [];

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat('#,###');

    return RefreshIndicator(
      onRefresh: _loadPortfolio,
      child: _portfolio.isEmpty
          ? Center(
              child: Text(
                l10n.noActivePositions,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _portfolio.length,
              itemBuilder: (context, index) {
                final h = _portfolio[index];
                final totalPnl = (h['totalPnl'] as num? ?? 0).toInt();
                final isProfit = totalPnl >= 0;
                final pnlColor = isProfit ? emerald : Colors.redAccent;
                final soldPercent = (h['soldPercent'] as num? ?? 0).toDouble();
                final lastPrice = h['lastPrice'] as num?;
                final avgCostRemaining = h['avgCostRemaining'] as num?;

                return Card(
                  color: const Color(0xFF151B2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF24304F)),
                  ),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          h['ticker'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        ),
                        Text(
                          '${isProfit ? '+' : ''}${numberFormat.format(totalPnl)} riel',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: pnlColor),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.remainingShares(numberFormat.format(h['remainingQty'] ?? 0)),
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              Text(
                                l10n.soldPercentLabel(soldPercent.toStringAsFixed(1)),
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.lastPriceLabel(lastPrice == null ? '-' : numberFormat.format(lastPrice)),
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              Text(
                                l10n.avgCostLabel(avgCostRemaining == null ? '-' : numberFormat.format(avgCostRemaining)),
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PositionDetailsScreen(ticker: h['ticker']),
                        ),
                      ).then((_) => _loadPortfolio());
                    },
                  ),
                );
              },
            ),
    );
  }
}
