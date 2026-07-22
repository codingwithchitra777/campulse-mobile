import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/performance_chart.dart';
import '../widgets/skeleton.dart';

/// Result of a detail loader: an x-axis of dates plus 1–2 aligned series
/// (e.g. Bid & Ask). Each series' values line up index-for-index with [dates].
typedef DetailData = ({List<DateTime> dates, List<ChartSeries> series});

/// A generic price/rate detail screen: loads a dated history and renders the
/// shared [PerformanceChart] (range filter, right axis, period change %,
/// tooltip). Reused for gold, the USD/KHR rate, and any watchlist symbol.
class MarketDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<DetailData> Function() loader;
  final String Function(num) formatFull;
  final String Function(num) formatCompact;

  const MarketDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.loader,
    required this.formatFull,
    required this.formatCompact,
  });

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  bool _loading = true;
  List<DateTime> _dates = [];
  List<ChartSeries> _series = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.loader();
      if (!mounted) return;
      setState(() {
        _dates = data.dates;
        _series = data.series;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  bool get _hasData => _series.isNotEmpty && _series.first.values.length >= 2;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(widget.subtitle, style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
          children: [
            if (_loading)
              const Skeleton.card(height: 320)
            else if (_error != null)
              AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('Could not load history: $_error',
                        style: TextStyle(color: c.textMuted), textAlign: TextAlign.center),
                  ),
                ),
              )
            else if (!_hasData)
              AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(Icons.show_chart_rounded, size: 40, color: c.textMuted),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Not enough price history yet',
                            style: TextStyle(color: c.textMuted, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              )
            else
              AppCard(
                child: PerformanceChart(
                  dates: _dates,
                  series: _series,
                  formatFull: widget.formatFull,
                  formatCompact: widget.formatCompact,
                  height: 240,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
