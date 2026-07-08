import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onRefresh;
  const DashboardScreen({super.key, required this.onRefresh});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color emerald = Color(0xFF10B981);
  final ApiService _api = ApiService.instance;
  bool _loading = false;
  List<dynamic> _prices = [];
  List<dynamic> _topTickers = [];
  List<dynamic> _topOrders = [];

  int _realisedPnl = 0;
  int _unrealisedPnl = 0;
  int _totalPnl = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    try {
      final prices = await _api.getPrices();

      List<dynamic> topTickers = [];
      List<dynamic> topOrders = [];
      int realised = 0;
      int unrealised = 0;

      if (!AuthService.instance.isGuest) {
        final portfolio = await _api.getPortfolio();
        topTickers = await _api.getTopTickers();
        topOrders = await _api.getTopOrders();
        for (var holding in portfolio) {
          realised += (holding['realisedPnl'] as num? ?? 0).toInt();
          unrealised += (holding['unrealisedPnl'] as num? ?? 0).toInt();
        }
      }

      setState(() {
        _prices = prices;
        _topTickers = topTickers;
        _topOrders = topOrders;
        _realisedPnl = realised;
        _unrealisedPnl = unrealised;
        _totalPnl = realised + unrealised;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat('#,###');
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // P/L Summary Widgets (personal data — requires sign-in)
            if (!AuthService.instance.isGuest) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildPLCard(
                      title: l10n.realisedPnl,
                      value: _realisedPnl,
                      theme: theme,
                      numberFormat: numberFormat,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPLCard(
                      title: l10n.unrealisedPnl,
                      value: _unrealisedPnl,
                      theme: theme,
                      numberFormat: numberFormat,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPLCard(
                title: l10n.totalPnl,
                value: _totalPnl,
                theme: theme,
                numberFormat: numberFormat,
                isLarge: true,
              ),
            ] else
              _buildLockedPrompt(l10n),
            const SizedBox(height: 24),

            // Live Stock Prices Section
            Text(
              l10n.csxStockPrices,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              color: const Color(0xFF151B2C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF24304F)),
              ),
              child: _prices.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(child: Text(l10n.noPricesAvailable)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _prices.length,
                      separatorBuilder: (context, index) => const Divider(color: Color(0xFF24304F)),
                      itemBuilder: (context, index) {
                        final p = _prices[index];
                        final isUp = p['change_direction'] == 'up';
                        final isDown = p['change_direction'] == 'down';
                        final color = isUp
                            ? emerald
                            : isDown
                                ? Colors.redAccent
                                : Colors.grey;
                        return ListTile(
                          title: Text(
                            p['ticker'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          subtitle: Text(
                            l10n.priceLabel(numberFormat.format(p['price'] ?? 0)),
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUp
                                      ? Icons.arrow_upward
                                      : isDown
                                          ? Icons.arrow_downward
                                          : Icons.arrow_forward,
                                  color: color,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${p['change'] ?? 0}',
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),

            // Top Rankings Grid (personal data — requires sign-in)
            if (!AuthService.instance.isGuest)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Tickers
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.topTickers,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildRankingsCard(_topTickers, isTickers: true, noRankData: l10n.noRankData, numberFormat: numberFormat),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Top Orders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.topOrders,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildRankingsCard(_topOrders, isTickers: false, noRankData: l10n.noRankData, numberFormat: numberFormat),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedPrompt(AppLocalizations l10n) {
    return Card(
      color: const Color(0xFF151B2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF24304F)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('🔒', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              l10n.personalizedAnalyticsLocked,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.personalizedAnalyticsLockedDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPLCard({
    required String title,
    required int value,
    required ThemeData theme,
    required NumberFormat numberFormat,
    bool isLarge = false,
  }) {
    final isProfit = value >= 0;
    final color = isProfit ? emerald : Colors.redAccent;
    return Card(
      color: const Color(0xFF151B2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF24304F)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLarge ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '${isProfit ? '+' : ''}${numberFormat.format(value)} riel',
              style: TextStyle(
                fontSize: isLarge ? 24 : 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingsCard(
    List<dynamic> list, {
    required bool isTickers,
    required String noRankData,
    required NumberFormat numberFormat,
  }) {
    return Card(
      color: const Color(0xFF151B2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF24304F)),
      ),
      child: list.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(noRankData, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  final name = isTickers
                      ? (item['ticker'] ?? '')
                      : '${item['ticker']} (Lot #${item['seq']})';
                  final pnl = item['realisedPnl'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '#${index + 1} $name',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${numberFormat.format(pnl)}',
                          style: const TextStyle(fontSize: 13, color: emerald, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
