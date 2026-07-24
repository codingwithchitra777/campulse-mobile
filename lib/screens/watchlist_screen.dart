import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/markets.dart';
import '../utils/money.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';

/// The user's tracked symbols with live quotes (routed per market). Add via a
/// market-aware sheet (CSX quick-pick, US typeahead, fixed gold); remove inline.
class WatchlistScreen extends StatefulWidget {
  /// When true, renders as a bottom-nav tab body (no Scaffold/AppBar/FAB — the
  /// host MainLayout supplies those). The pushed/full-screen variant keeps its
  /// own chrome.
  final bool embedded;
  const WatchlistScreen({super.key, this.embedded = false});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _api.getWatchlist();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _toast('Could not load watchlist: $e');
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
    final symbol = (item['symbol'] ?? '').toString();
    final market = (item['market'] ?? 'CSX').toString();
    setState(() => _items.remove(item));
    try {
      await _api.removeFromWatchlist(symbol, market: market);
      _toast('Removed $symbol', success: true);
    } catch (e) {
      _toast('Could not remove: $e');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final body = RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? _skeleton()
          : _items.isEmpty
              ? _empty(c)
              : _list(c),
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: c.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add symbol', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: body,
    );
  }

  /// A full-width "Add symbol" button — used in embedded (tab) mode where there
  /// is no floating action button.
  Widget _addButton(AppColors c) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: SizedBox(
          height: 46,
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: c.primary),
            onPressed: _openAdd,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            label: const Text('Add symbol',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      );

  Widget _skeleton() => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Skeleton.card(height: 72),
          SizedBox(height: AppSpacing.md),
          Skeleton.card(height: 72),
          SizedBox(height: AppSpacing.md),
          Skeleton.card(height: 72),
        ],
      );

  Widget _empty(AppColors c) => ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.star_outline_rounded, size: 64, color: c.textMuted),
          const SizedBox(height: AppSpacing.lg),
          Text('Your watchlist is empty',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text('Track symbols you don\'t own yet. Tap "Add symbol" to start.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 14, height: 1.4)),
          if (widget.embedded) ...[
            const SizedBox(height: AppSpacing.xl),
            _addButton(c),
          ],
        ],
      );

  Widget _list(AppColors c) {
    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, context.navBarClearance),
      children: [
        if (widget.embedded) _addButton(c),
        SectionHeader(title: '${_items.length} ${_items.length == 1 ? 'symbol' : 'symbols'}'),
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
    final price = it['price'] as num?;
    final change = (it['change'] as num?) ?? 0;
    final dir = (it['changeDirection'] ?? 'equal').toString();
    final color = dir == 'up' ? c.profit : (dir == 'down' ? c.loss : c.textMuted);
    final prev = (price?.toDouble() ?? 0) - change.toDouble();
    final pct = prev != 0 ? (change / prev) * 100 : 0.0;

    return Dismissible(
      key: ValueKey('$market:$symbol'),
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
                Text(ccy, style: TextStyle(color: c.textMuted, fontSize: 11)),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price == null ? '—' : Money.format(price, ccy),
                    style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      dir == 'up'
                          ? Icons.arrow_drop_up_rounded
                          : (dir == 'down' ? Icons.arrow_drop_down_rounded : Icons.remove_rounded),
                      color: color,
                      size: 18,
                    ),
                    Text('${Money.format(change.abs(), ccy)} (${pct >= 0 ? '+' : '−'}${pct.abs().toStringAsFixed(1)}%)',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
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

  // ── Add symbol sheet ────────────────────────────────────────────────
  void _openAdd() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _AddSymbolSheet(
        api: _api,
        existing: _items.map((e) => '${e['market']}:${e['symbol']}').toSet(),
        onAdded: () {
          Navigator.pop(ctx);
          _load();
        },
        onError: _toast,
      ),
    );
  }
}

/// Market-aware add sheet: CSX quick-pick chips, US typeahead search, fixed gold.
class _AddSymbolSheet extends StatefulWidget {
  final ApiService api;
  final Set<String> existing;
  final VoidCallback onAdded;
  final void Function(String, {bool success}) onError;
  const _AddSymbolSheet(
      {required this.api, required this.existing, required this.onAdded, required this.onError});

  @override
  State<_AddSymbolSheet> createState() => _AddSymbolSheetState();
}

class _AddSymbolSheetState extends State<_AddSymbolSheet> {
  Market _market = Market.csx;
  final _symbolCtl = TextEditingController();
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

  Future<void> _add(String symbol) async {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return widget.onError('Enter a symbol');
    if (widget.existing.contains('${_market.code}:$sym')) {
      return widget.onError('$sym is already on your watchlist');
    }
    setState(() => _saving = true);
    try {
      await widget.api.addToWatchlist(sym, market: _market.code, currency: _market.currency);
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

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
          AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom),
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
          Text('Add to watchlist',
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
          // US results
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
                      onTap: _saving ? null : () => _add((r['symbol'] ?? '').toString()),
                    ),
                ],
              ),
            ),
          ],
          // CSX quick-pick chips
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
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.primary),
              onPressed: _saving ? null : () => _add(_symbolCtl.text),
              child: _saving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add to watchlist',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
