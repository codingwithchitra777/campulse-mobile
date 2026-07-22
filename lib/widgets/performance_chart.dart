import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// A tiny, axis-less line — used inline in list rows / cards.
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final bool filled;
  final double height;

  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.filled = true,
    this.height = 34,
  });

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('—', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
        ),
      );
    }
    final spots = [for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])];
    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.15;
    if (pad == 0) {
      minY -= 1;
      maxY += 1;
    } else {
      minY -= pad;
      maxY += pad;
    }
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: filled,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.24), color.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selectable time windows for the performance chart.
enum ChartRange {
  w1('1W', 7),
  m1('1M', 30),
  m3('3M', 90),
  m6('6M', 180),
  all('ALL', null);

  const ChartRange(this.label, this.days);
  final String label;
  final int? days;

  String get periodLabel => switch (this) {
        ChartRange.w1 => 'Past week',
        ChartRange.m1 => 'Past month',
        ChartRange.m3 => 'Past 3 months',
        ChartRange.m6 => 'Past 6 months',
        ChartRange.all => 'All time',
      };
}

/// One line of the performance chart. [values] is aligned index-for-index to the
/// chart's shared [dates] list.
class ChartSeries {
  final String label;
  final List<double> values;
  final bool dashed;
  const ChartSeries(this.label, this.values, {this.dashed = false});
}

/// The full, rich performance chart shared by the portfolio, gold, exchange
/// rate, and per-symbol detail views: a range filter (1W…ALL), a right-side
/// price axis, a period change (value + %) header, a legend, a touch tooltip,
/// and 1–2 curved lines. All values are formatted through the injected
/// [formatFull]/[formatCompact] so it works for currencies and plain rates.
class PerformanceChart extends StatefulWidget {
  final List<DateTime> dates;
  final List<ChartSeries> series;
  final String Function(num) formatFull;
  final String Function(num) formatCompact;

  /// Colour the primary line green/red by whether it rose over the window.
  final bool colorByTrend;
  final Color? fixedColor;
  final double height;

  const PerformanceChart({
    super.key,
    required this.dates,
    required this.series,
    required this.formatFull,
    required this.formatCompact,
    this.colorByTrend = true,
    this.fixedColor,
    this.height = 190,
  });

  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<PerformanceChart> {
  ChartRange _range = ChartRange.all;

  /// Indices of [widget.dates] that fall within the selected range.
  List<int> get _rangeIndices {
    final n = widget.dates.length;
    if (n == 0) return const [];
    final days = _range.days;
    if (days == null) return [for (int i = 0; i < n; i++) i];
    final cutoff = widget.dates.last.subtract(Duration(days: days));
    final idx = [for (int i = 0; i < n; i++) if (!widget.dates[i].isBefore(cutoff)) i];
    // Always keep at least two points so a line is drawable.
    if (idx.length < 2 && n >= 2) return [n - 2, n - 1];
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final idx = _rangeIndices;
    final primary = widget.series.first;
    final primVals = [for (final i in idx) primary.values[i]];
    final hasData = primVals.length >= 2;

    final current = hasData ? primVals.last : 0.0;
    final start = hasData ? primVals.first : 0.0;
    final change = current - start;
    final pct = start != 0 ? (change / start) * 100 : 0.0;
    final plColor = change >= 0 ? c.profit : c.loss;
    final lineColor = widget.fixedColor ?? (widget.colorByTrend ? (change >= 0 ? c.profit : c.loss) : c.primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: period label + current value | change value + %
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_range.periodLabel,
                    style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(hasData ? widget.formatFull(current) : '—',
                    style: TextStyle(color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            const Spacer(),
            if (hasData)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(change >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 15, color: plColor),
                      const SizedBox(width: 2),
                      Text('${change >= 0 ? '+' : '−'}${widget.formatFull(change.abs())}',
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
        if (widget.series.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (int i = 0; i < widget.series.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                        color: i == 0 ? lineColor : c.textMuted, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(widget.series[i].label,
                    style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _rangeSelector(c),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: widget.height,
          child: hasData ? _chart(c, idx, lineColor) : _empty(c),
        ),
      ],
    );
  }

  Widget _empty(AppColors c) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_rounded, size: 32, color: c.textMuted),
            const SizedBox(height: AppSpacing.sm),
            Text('No data in this range', style: TextStyle(color: c.textMuted, fontSize: 13)),
          ],
        ),
      );

  Widget _rangeSelector(AppColors c) {
    return Row(
      children: [
        for (final r in ChartRange.values) ...[
          if (r != ChartRange.values.first) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _range = r),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _range == r ? c.primary : c.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(color: _range == r ? c.primary : c.border),
                ),
                child: Text(r.label,
                    style: TextStyle(
                        color: _range == r ? c.onPrimary : c.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _chart(AppColors c, List<int> idx, Color lineColor) {
    final dates = [for (final i in idx) widget.dates[i]];
    final bars = <LineChartBarData>[];
    double minY = double.infinity, maxY = -double.infinity;
    for (int s = 0; s < widget.series.length; s++) {
      final vals = [for (final i in idx) widget.series[s].values[i]];
      for (final v in vals) {
        if (v < minY) minY = v;
        if (v > maxY) maxY = v;
      }
      final isPrimary = s == 0;
      bars.add(LineChartBarData(
        spots: [for (int i = 0; i < vals.length; i++) FlSpot(i.toDouble(), vals[i])],
        isCurved: true,
        color: isPrimary ? lineColor : c.textMuted,
        barWidth: isPrimary ? 2.5 : 1.5,
        isStrokeCapRound: true,
        dashArray: widget.series[s].dashed ? const [5, 4] : null,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: isPrimary,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lineColor.withValues(alpha: 0.24), lineColor.withValues(alpha: 0.0)],
          ),
        ),
      ));
    }
    final pad = (maxY - minY) * 0.15;
    minY = (minY - (pad == 0 ? 1 : pad));
    maxY += pad == 0 ? 1 : pad;
    final interval = (maxY - minY) <= 0 ? 1.0 : (maxY - minY) / 3;

    String tipDate(int i) =>
        (i >= 0 && i < dates.length) ? DateFormat('d MMM yyyy').format(dates[i]) : '';

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (dates.length - 1).toDouble(),
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
                child: Text(widget.formatCompact(value),
                    style: TextStyle(color: c.textMuted, fontSize: 9), textAlign: TextAlign.left),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => c.surfaceAlt,
            getTooltipItems: (spots) => [
              for (int j = 0; j < spots.length; j++)
                LineTooltipItem(
                  '${widget.series[spots[j].barIndex].label}  ${widget.formatFull(spots[j].y)}'
                  '${j == 0 ? '\n${tipDate(spots[j].spotIndex)}' : ''}',
                  TextStyle(
                    color: spots[j].barIndex == 0 ? lineColor : c.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: bars,
      ),
    );
  }
}
