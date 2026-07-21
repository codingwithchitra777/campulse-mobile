import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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
  
  List<dynamic> _topTickers = [];
  
  Map<String, dynamic>? _chartsData;
  Map<String, dynamic>? _exchangeHistory;
  Map<String, dynamic>? _goldHistory;
  Map<String, dynamic>? _latestExchangeRate;

  String _valuationMode = 'BID';
  String _selectedMarket = 'ALL';
  String _baseCurrency = 'KHR';

  double _portfolioValue = 0;
  double _totalReturn = 0;
  
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    try {
      final latestExchange = await _api.getLatestExchangeRate('USD', 'KHR');
      final exchangeHistory = await _api.getExchangeRateHistory('USD', 'KHR');
      final goldHistory = await _api.getMarketPriceHistory('XAU-KH');
      
      List<dynamic> portfolio = [];
      List<dynamic> topTickers = [];
      Map<String, dynamic>? chartsData;
      
      double pValue = 0;
      double tReturn = 0;

      if (!AuthService.instance.isGuest) {
        portfolio = await _api.getPortfolio(valuationMode: _valuationMode);
        topTickers = await _api.getTopTickers();
        
        chartsData = await _api.getChartsTimeline(
          _selectedMarket == 'ALL' ? null : _selectedMarket,
          _baseCurrency,
          _valuationMode,
        );

        for (var holding in portfolio) {
          final qty = (holding['remainingQuantity'] as num?)?.toDouble() ?? 0;
          final price = (holding['currentPrice'] as num?)?.toDouble() ?? 0;
          final unrealised = (holding['unrealisedPnl'] as num?)?.toDouble() ?? 0;
          final realised = (holding['realisedPnl'] as num?)?.toDouble() ?? 0;
          
          pValue += (qty * price);
          tReturn += (realised + unrealised);
        }
      }

      setState(() {
        _latestExchangeRate = latestExchange;
        _exchangeHistory = exchangeHistory;
        _goldHistory = goldHistory;
        
        _topTickers = topTickers;
        _chartsData = chartsData;
        _portfolioValue = pValue;
        _totalReturn = tReturn;
        
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
            _buildExchangeRateHeader(l10n),
            const SizedBox(height: 16),
            
            if (!AuthService.instance.isGuest) ...[
              _buildValuationToggle(l10n),
              const SizedBox(height: 16),
              _buildPortfolioSummary(l10n, numberFormat, theme),
              const SizedBox(height: 24),
              _buildChartSection(l10n.portfolioPerformance, _buildPortfolioChart()),
            ] else
              _buildLockedPrompt(l10n),
              
            const SizedBox(height: 24),
            _buildChartSection(l10n.exchangeRateTrend, _buildExchangeRateChart()),
            const SizedBox(height: 24),
            _buildChartSection(l10n.goldPriceTrend, _buildGoldChart()),
            const SizedBox(height: 24),
            
            if (!AuthService.instance.isGuest) ...[
              Text(
                l10n.marketMovers,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildMarketMovers(l10n, numberFormat),
            ],
            const SizedBox(height: 80), // Padding for scrolling
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeRateHeader(AppLocalizations l10n) {
    String rateText = '---';
    if (_latestExchangeRate != null && _latestExchangeRate!['rate'] != null) {
      final r = _latestExchangeRate!['rate'];
      rateText = '${r['bidRate']} / ${r['askRate']}';
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('USD/KHR : $rateText', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
      ],
    );
  }

  Widget _buildValuationToggle(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ToggleButtons(
          isSelected: [_valuationMode == 'BID', _valuationMode == 'ASK'],
          onPressed: (index) {
            setState(() {
              _valuationMode = index == 0 ? 'BID' : 'ASK';
            });
            _loadAllData();
          },
          borderRadius: BorderRadius.circular(8),
          constraints: const BoxConstraints(minHeight: 32, minWidth: 60),
          children: [
            Text(l10n.valuationBid),
            Text(l10n.valuationAsk),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioSummary(AppLocalizations l10n, NumberFormat nf, ThemeData theme) {
    final isProfit = _totalReturn >= 0;
    final color = isProfit ? emerald : Colors.redAccent;
    
    return Row(
      children: [
        Expanded(
          child: Card(
            color: const Color(0xFF151B2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF24304F)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.portfolioValue.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('${nf.format(_portfolioValue)} $_baseCurrency', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            color: const Color(0xFF151B2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF24304F)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.totalReturn.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('${isProfit ? '+' : ''}${nf.format(_totalReturn)} $_baseCurrency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(String title, Widget chartWidget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFF151B2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF24304F)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 200,
              child: chartWidget,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioChart() {
    if (_chartsData == null || _chartsData!['labels'] == null || (_chartsData!['labels'] as List).isEmpty) {
      return const Center(child: Text('No chart data', style: TextStyle(color: Colors.grey)));
    }
    
    final equity = _chartsData!['equity'] as List;
    
    if (equity.isEmpty) return const Center(child: Text('No equity data'));

    List<FlSpot> spots = [];
    for (int i = 0; i < equity.length; i++) {
      spots.add(FlSpot(i.toDouble(), (equity[i] as num).toDouble()));
    }

    return _buildLineChart(spots, emerald);
  }

  Widget _buildExchangeRateChart() {
    if (_exchangeHistory == null || _exchangeHistory!['items'] == null) {
      return const Center(child: Text('No data'));
    }
    final items = _exchangeHistory!['items'] as List;
    if (items.isEmpty) return const Center(child: Text('No data'));
    
    List<FlSpot> spots = [];
    // Items are usually newest first from API, so reverse them for chart
    final reversed = items.reversed.toList();
    for (int i = 0; i < reversed.length; i++) {
      final rate = (reversed[i]['bidRate'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), rate));
    }

    return _buildLineChart(spots, Colors.blue);
  }

  Widget _buildGoldChart() {
    if (_goldHistory == null || _goldHistory!['items'] == null) {
      return const Center(child: Text('No data'));
    }
    final items = _goldHistory!['items'] as List;
    if (items.isEmpty) return const Center(child: Text('No data'));
    
    List<FlSpot> spots = [];
    final reversed = items.reversed.toList();
    for (int i = 0; i < reversed.length; i++) {
      final price = (reversed[i]['price'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), price));
    }

    return _buildLineChart(spots, Colors.amber);
  }

  Widget _buildLineChart(List<FlSpot> spots, Color lineColor) {
    if (spots.isEmpty) return const SizedBox.shrink();
    
    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    
    // Add padding to Y axis
    final padding = (maxY - minY) * 0.1;
    if (padding == 0) {
      minY -= 10;
      maxY += 10;
    } else {
      minY -= padding;
      maxY += padding;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withAlpha(26), // 10% opacity
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketMovers(AppLocalizations l10n, NumberFormat nf) {
    return Card(
      color: const Color(0xFF151B2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF24304F)),
      ),
      child: _topTickers.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(l10n.noRankData, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topTickers.length > 5 ? 5 : _topTickers.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFF24304F), height: 1),
              itemBuilder: (context, index) {
                final item = _topTickers[index];
                final name = item['ticker'] ?? '';
                final pnl = item['realisedPnl'] ?? 0;
                return ListTile(
                  title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: Text(
                    '+${nf.format(pnl)}',
                    style: const TextStyle(color: emerald, fontWeight: FontWeight.bold),
                  ),
                );
              },
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
}
