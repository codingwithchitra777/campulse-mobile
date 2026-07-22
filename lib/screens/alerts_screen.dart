import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/markets.dart';
import '../utils/money.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';

/// Price alerts — the backend polls quotes and pings the user's linked Telegram
/// when a symbol crosses the target. Add per market; delete inline.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;
  List<dynamic> _items = [];
  bool _deliverable = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getAlerts();
      if (mounted) {
        setState(() {
          _items = res['items'] as List? ?? [];
          _deliverable = res['deliverable'] != false;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _toast('Could not load alerts: $e');
    }
  }

  void _toast(String msg, {bool success = false}) {
    if (!mounted) return;
    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? c.profit : c.surfaceAlt,
    ));
  }

  Future<void> _remove(dynamic item) async {
    setState(() => _items.remove(item));
    try {
      await _api.deleteAlert((item['alertId'] ?? '').toString());
      _toast('Alert removed', success: true);
    } catch (e) {
      _toast('Could not remove: $e');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Price Alerts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: c.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? _skeleton()
            : _items.isEmpty
                ? _empty(c)
                : _list(c),
      ),
    );
  }

  Widget _skeleton() => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Skeleton.card(height: 74),
          SizedBox(height: AppSpacing.md),
          Skeleton.card(height: 74),
          SizedBox(height: AppSpacing.md),
          Skeleton.card(height: 74),
        ],
      );

  Widget _empty(AppColors c) => ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.notifications_none_rounded, size: 64, color: c.textMuted),
          const SizedBox(height: AppSpacing.lg),
          Text('No price alerts yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text('Get pinged on Telegram when a symbol hits your target. Tap "New alert".',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 14, height: 1.4)),
        ],
      );

  Widget _list(AppColors c) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        if (!_deliverable) ...[
          AppCard(
            color: c.surfaceAlt,
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: c.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Link Telegram in Connected accounts to actually receive these alerts.',
                      style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.3)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        SectionHeader(title: '${_items.length} ${_items.length == 1 ? 'alert' : 'alerts'}'),
        for (final it in _items) ...[
          _row(c, it),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _row(AppColors c, dynamic it) {
    final symbol = (it['symbol'] ?? '').toString();
    final market = (it['market'] ?? 'CSX').toString();
    final ccy = (it['currency'] as String?) ?? 'KHR';
    final target = (it['targetPrice'] as num?) ?? 0;
    final above = (it['direction'] ?? 'above') == 'above';
    final triggered = it['triggeredAt'] != null;
    final active = it['active'] != false;

    return Dismissible(
      key: ValueKey(it['alertId']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: c.loss.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Icon(Icons.delete_outline_rounded, color: c.loss),
      ),
      onDismissed: (_) => _remove(it),
      child: AppCard(
        child: Row(
          children: [
            _coin(c, symbol, market),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(symbol,
                        style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    _marketBadge(c, market),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(above ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 14, color: above ? c.profit : c.loss),
                    const SizedBox(width: 4),
                    Text('${above ? 'Rises to' : 'Falls to'} ${Money.format(target, ccy)}',
                        style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const Spacer(),
            _statePill(c, triggered: triggered, active: active),
          ],
        ),
      ),
    );
  }

  Widget _statePill(AppColors c, {required bool triggered, required bool active}) {
    final (color, label) = triggered
        ? (c.profit, 'Triggered')
        : (active ? (c.primary, 'Armed') : (c.textMuted, 'Off'));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _coin(AppColors c, String symbol, String market) {
    final color = switch (market) {
      'US' => const Color(0xFF8B5CF6),
      'GOLD_KH' => const Color(0xFFF59E0B),
      _ => c.primary,
    };
    final initials = symbol.isEmpty
        ? '?'
        : symbol.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').padRight(2).substring(0, 2).toUpperCase();
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
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Text(initials,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
    );
  }

  Widget _marketBadge(AppColors c, String market) {
    final color = switch (market) {
      'US' => const Color(0xFF8B5CF6),
      'GOLD_KH' => const Color(0xFFF59E0B),
      _ => c.primary,
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

  // ── Add alert sheet ─────────────────────────────────────────────────
  void _openAdd() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _AddAlertSheet(
        api: _api,
        onAdded: () {
          Navigator.pop(ctx);
          _load();
        },
        onError: _toast,
      ),
    );
  }
}

/// Market-aware add sheet: CSX quick-pick, US typeahead, fixed gold, plus a
/// target price and an above/below trigger direction.
class _AddAlertSheet extends StatefulWidget {
  final ApiService api;
  final VoidCallback onAdded;
  final void Function(String, {bool success}) onError;
  const _AddAlertSheet({required this.api, required this.onAdded, required this.onError});

  @override
  State<_AddAlertSheet> createState() => _AddAlertSheetState();
}

class _AddAlertSheetState extends State<_AddAlertSheet> {
  Market _market = Market.csx;
  final _symbolCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  String _direction = 'above';
  List<Map<String, dynamic>> _csxPrices = [];
  List<dynamic> _usResults = [];
  Timer? _debounce;
  bool _searching = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCsx();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _symbolCtl.dispose();
    _priceCtl.dispose();
    super.dispose();
  }

  Future<void> _loadCsx() async {
    try {
      final p = await widget.api.getPrices();
      if (mounted) setState(() => _csxPrices = p.cast<Map<String, dynamic>>());
    } catch (_) {/* non-fatal */}
  }

  void _selectMarket(Market m) {
    setState(() {
      _market = m;
      _usResults = [];
      _symbolCtl.text = m.fixedSymbol ?? '';
    });
  }

  void _onUsChanged(String v) {
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() => _usResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      final r = await widget.api.searchSymbols(v.trim());
      if (mounted) setState(() { _usResults = r.take(6).toList(); _searching = false; });
    });
  }

  Future<void> _submit() async {
    final sym = _symbolCtl.text.trim().toUpperCase();
    final target = num.tryParse(_priceCtl.text.trim()) ?? 0;
    if (sym.isEmpty) return widget.onError('Enter a symbol');
    if (target <= 0) return widget.onError('Enter a valid target price');
    setState(() => _saving = true);
    try {
      await widget.api.createAlert(sym,
          market: _market.code, currency: _market.currency, targetPrice: target, direction: _direction);
      widget.onAdded();
    } catch (e) {
      setState(() => _saving = false);
      widget.onError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isUs = _market == Market.us;
    final isGold = _market == Market.gold;
    final usd = _market.currency == 'USD';

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('New price alert',
              style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.lg),
          // Market picker
          Container(
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                for (final m in Market.values)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectMarket(m),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _market == m ? c.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(m.label,
                            style: TextStyle(
                                color: _market == m ? c.onPrimary : c.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isGold)
            AppCard(
              color: c.surfaceAlt,
              child: Row(
                children: [
                  Icon(Icons.diamond_outlined, color: c.warning),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('XAU-KH · Gold (USD per chi)',
                        style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )
          else
            TextField(
              controller: _symbolCtl,
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) {
                if (isUs) _onUsChanged(v);
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: isUs ? 'US symbol' : 'CSX ticker',
                hintText: isUs ? 'e.g. AAPL' : 'e.g. PWSA',
                prefixIcon: Icon(isUs ? Icons.search_rounded : Icons.tag_rounded, color: c.textMuted),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
              ),
            ),
          if (isUs && _usResults.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (final r in _usResults)
                    ListTile(
                      dense: true,
                      title: Text('${r['symbol'] ?? ''}',
                          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700)),
                      subtitle: Text('${r['description'] ?? ''}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.textMuted, fontSize: 12)),
                      onTap: () => setState(() {
                        _symbolCtl.text = (r['symbol'] ?? '').toString();
                        _usResults = [];
                      }),
                    ),
                ],
              ),
            ),
          ],
          if (_market == Market.csx && _csxPrices.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final p in _csxPrices)
                  GestureDetector(
                    onTap: () => setState(() => _symbolCtl.text = (p['ticker'] ?? '').toString()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(color: c.border),
                      ),
                      child: Text('${p['ticker']}',
                          style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Direction + target price
          Container(
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                _dirSeg('above', 'Rises to', Icons.trending_up_rounded, c.profit, c),
                _dirSeg('below', 'Falls to', Icons.trending_down_rounded, c.loss, c),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _priceCtl,
            keyboardType: TextInputType.numberWithOptions(decimal: usd),
            inputFormatters: [
              usd
                  ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  : FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Target price',
              prefixText: usd ? '\$ ' : null,
              suffixText: usd ? null : '៛',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.primary),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create alert',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dirSeg(String value, String label, IconData icon, Color sel, AppColors c) {
    final selected = _direction == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _direction = value),
        child: Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? sel.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: selected ? sel : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? sel : c.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: selected ? sel : c.textMuted, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
