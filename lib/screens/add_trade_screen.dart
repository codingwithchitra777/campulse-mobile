import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/markets.dart';
import '../utils/money.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';

class AddTradeScreen extends StatefulWidget {
  final VoidCallback onTradeAdded;
  const AddTradeScreen({super.key, required this.onTradeAdded});

  @override
  State<AddTradeScreen> createState() => _AddTradeScreenState();
}

class _AddTradeScreenState extends State<AddTradeScreen> {
  final ApiService _api = ApiService.instance;

  final _tickerController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _commissionController = TextEditingController();

  Market _market = Market.csx;
  String _side = 'BUY';
  bool _commissionManual = false;
  DateTime? _orderDate; // null = now

  // CSX quick-pick tickers
  List<Map<String, dynamic>> _csxPrices = [];
  // US symbol search
  List<dynamic> _usResults = [];
  Timer? _searchDebounce;
  bool _searching = false;

  bool _submitting = false;
  String? _quoteHint;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_recalcCommission);
    _qtyController.addListener(_recalcCommission);
    _loadCsxPrices();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tickerController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _loadCsxPrices() async {
    try {
      final prices = await _api.getPrices();
      if (mounted) {
        setState(() => _csxPrices = prices.cast<Map<String, dynamic>>());
      }
    } catch (_) {/* non-fatal */}
  }

  String get _currency => _market.currency;

  double get _priceVal => double.tryParse(_priceController.text.trim()) ?? 0;
  int get _qtyVal => int.tryParse(_qtyController.text.trim()) ?? 0;
  double get _commissionVal => double.tryParse(_commissionController.text.trim()) ?? 0;
  double get _total => _priceVal * _qtyVal;

  void _recalcCommission() {
    if (!_commissionManual) {
      final c = _priceVal * _qtyVal * 0.0047;
      _commissionController.text =
          _market.priceDecimals == 0 ? c.round().toString() : c.toStringAsFixed(2);
    }
    setState(() {});
  }

  void _selectMarket(Market m) {
    setState(() {
      _market = m;
      _usResults = [];
      _quoteHint = null;
      _tickerController.text = m.fixedSymbol ?? '';
      _priceController.clear();
      _qtyController.clear();
      _commissionController.text = '0';
    });
    if (m == Market.gold) _fetchQuote('XAU-KH');
  }

  Future<void> _fetchQuote(String symbol) async {
    if (symbol.isEmpty) return;
    final q = await _api.getMarketQuote(symbol, _market.code);
    if (!mounted) return;
    if (q != null && q['price'] != null) {
      final price = (q['price'] as num).toDouble();
      setState(() {
        _quoteHint = 'Live: ${Money.format(price, _currency)}';
        if (_priceController.text.trim().isEmpty) {
          _priceController.text =
              _market.priceDecimals == 0 ? price.round().toString() : price.toStringAsFixed(2);
        }
      });
    } else {
      setState(() => _quoteHint = null);
    }
  }

  void _onUsSearchChanged(String v) {
    _searchDebounce?.cancel();
    if (v.trim().length < 2) {
      setState(() => _usResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      final results = await _api.searchSymbols(v.trim());
      if (mounted) {
        setState(() {
          _usResults = results.take(6).toList();
          _searching = false;
        });
      }
    });
  }

  // ── Submit flow ─────────────────────────────────────────────────────
  Future<void> _review() async {
    final ticker = _tickerController.text.trim().toUpperCase();
    if (ticker.isEmpty) return _toast('Enter a ticker / symbol');
    if (_priceVal <= 0) return _toast('Enter a valid price');
    if (_qtyVal <= 0) return _toast('Enter a valid quantity');

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final res = await _api.initTrade(
        ticker, _side, _priceVal, _qtyVal,
        commission: _commissionVal,
        market: _market.code,
        currency: _currency,
        orderDate: _orderDate,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      _openConfirmSheet(res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirm() async {
    final ticker = _tickerController.text.trim().toUpperCase();
    Navigator.of(context).pop(); // close sheet
    setState(() => _submitting = true);
    try {
      final res = await _api.confirmTrade(
        ticker, _side, _priceVal, _qtyVal,
        commission: _commissionVal,
        market: _market.code,
        currency: _currency,
        orderDate: _orderDate,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      final realised = (res['realisedPnl'] as num?) ?? 0;
      _toast(
        _side == 'SELL' && realised != 0
            ? 'Trade recorded · P/L ${Money.format(realised, _currency, signed: true)}'
            : '$_side recorded ✓',
        success: true,
      );
      _resetForm();
      widget.onTradeAdded();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _resetForm() {
    _tickerController.text = _market.fixedSymbol ?? '';
    _priceController.clear();
    _qtyController.clear();
    _commissionController.text = '0';
    _commissionManual = false;
    _orderDate = null;
    _usResults = [];
    setState(() {});
  }

  void _toast(String msg, {bool success = false}) {
    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? c.profit : c.surfaceAlt,
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final isBuy = _side == 'BUY';

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, context.navBarClearance),
      children: [
        const SectionHeader(title: 'Record a trade'),
        _marketPicker(context),
        const SizedBox(height: AppSpacing.lg),
        _sideToggle(context),
        const SizedBox(height: AppSpacing.lg),
        _symbolSection(context),
        const SizedBox(height: AppSpacing.lg),
        _priceQtySection(context, l10n),
        const SizedBox(height: AppSpacing.lg),
        _commissionAndDate(context),
        const SizedBox(height: AppSpacing.lg),
        _summaryCard(context),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isBuy ? c.profit : c.loss,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            ),
            onPressed: _submitting ? null : _review,
            child: _submitting
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Review $_side',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _marketPicker(BuildContext context) {
    final c = context.colors;
    Widget seg(Market m) {
      final selected = _market == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => _selectMarket(m),
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? c.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(m.label,
                    style: TextStyle(
                        color: selected ? c.onPrimary : c.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(m.currency,
                    style: TextStyle(
                        color: selected ? c.onPrimary.withValues(alpha: 0.8) : c.textMuted,
                        fontSize: 10)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: c.border),
      ),
      child: Row(children: [seg(Market.csx), seg(Market.us), seg(Market.gold)]),
    );
  }

  Widget _sideToggle(BuildContext context) {
    final c = context.colors;
    Widget seg(String side, Color color, IconData icon) {
      final selected = _side == side;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _side = side),
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: selected ? color : Colors.transparent),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? color : c.textMuted),
                const SizedBox(width: 6),
                Text(side,
                    style: TextStyle(
                        color: selected ? color : c.textMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: c.border),
      ),
      child: Row(children: [
        seg('BUY', c.profit, Icons.south_west_rounded),
        seg('SELL', c.loss, Icons.north_east_rounded),
      ]),
    );
  }

  Widget _symbolSection(BuildContext context) {
    final c = context.colors;
    if (_market == Market.gold) {
      return AppCard(
        child: Row(
          children: [
            Icon(Icons.diamond_outlined, color: c.warning),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('XAU-KH',
                      style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('Gold · priced per chi (USD)',
                      style: TextStyle(color: c.textMuted, fontSize: 12)),
                ],
              ),
            ),
            if (_quoteHint != null)
              Text(_quoteHint!, style: TextStyle(color: c.profit, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final isUs = _market == Market.us;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _tickerController,
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) {
            if (isUs) _onUsSearchChanged(v);
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
                : (_tickerController.text.trim().isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.bolt_rounded, color: c.primary),
                        tooltip: 'Fetch live price',
                        onPressed: () => _fetchQuote(_tickerController.text.trim().toUpperCase()),
                      )
                    : null),
          ),
        ),
        if (_quoteHint != null && !isUs) ...[
          const SizedBox(height: 6),
          Text(_quoteHint!, style: TextStyle(color: c.profit, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
        // US search results
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
                    onTap: () {
                      _tickerController.text = (r['symbol'] ?? '').toString();
                      setState(() => _usResults = []);
                      _fetchQuote(_tickerController.text);
                    },
                  ),
              ],
            ),
          ),
        ],
        // CSX quick-pick chips
        if (!isUs && _csxPrices.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final p in _csxPrices)
                GestureDetector(
                  onTap: () {
                    _tickerController.text = (p['ticker'] ?? '').toString();
                    final price = (p['price'] as num?)?.toDouble();
                    if (price != null && _priceController.text.trim().isEmpty) {
                      _priceController.text = price.round().toString();
                    }
                    setState(() => _quoteHint = price != null ? 'Live: ${Money.format(price, 'KHR')}' : null);
                  },
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
      ],
    );
  }

  Widget _priceQtySection(BuildContext context, AppLocalizations l10n) {
    final usd = _currency == 'USD';
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _priceController,
            keyboardType: TextInputType.numberWithOptions(decimal: usd),
            inputFormatters: [
              usd
                  ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  : FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Price ($_currency)',
              prefixText: usd ? '\$ ' : null,
              suffixText: usd ? null : '៛',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
        ),
      ],
    );
  }

  Widget _commissionAndDate(BuildContext context) {
    final c = context.colors;
    final usd = _currency == 'USD';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _commissionController,
            keyboardType: TextInputType.numberWithOptions(decimal: usd),
            inputFormatters: [
              usd
                  ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  : FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (_) => _commissionManual = true,
            decoration: InputDecoration(
              labelText: 'Commission',
              helperText: _commissionManual ? 'manual' : 'auto 0.47%',
              helperStyle: TextStyle(color: c.textMuted, fontSize: 11),
              prefixText: usd ? '\$ ' : null,
              suffixText: usd ? null : '៛',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Trade date'),
              child: Row(
                children: [
                  Icon(Icons.event_rounded, size: 16, color: c.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _orderDate == null ? 'Today' : DateFormat('d MMM yyyy').format(_orderDate!),
                      style: TextStyle(color: c.textPrimary, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _orderDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked != null) setState(() => _orderDate = picked);
  }

  /// Market-tinted gradient coin with the ticker's initials — the same token
  /// look used across portfolio/history, so the trade preview feels unified.
  Widget _tickerCoin(BuildContext context, {double size = 40}) {
    final color = switch (_market) {
      Market.us => const Color(0xFF8B5CF6),
      Market.gold => const Color(0xFFF59E0B),
      Market.csx => context.colors.primary,
    };
    final ticker = _tickerController.text.trim();
    final initials = ticker.isEmpty
        ? '?'
        : ticker.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').padRight(2).substring(0, 2).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(initials,
          style: TextStyle(color: Colors.white, fontSize: size * 0.33, fontWeight: FontWeight.w800)),
    );
  }

  Widget _summaryCard(BuildContext context) {
    final c = context.colors;
    final isBuy = _side == 'BUY';
    final ticker = _tickerController.text.trim().toUpperCase();
    return AppCard(
      color: c.surfaceAlt,
      child: Column(
        children: [
          Row(
            children: [
              _tickerCoin(context),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticker.isEmpty ? 'New trade' : ticker,
                        style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('$_side · ${_market.label}',
                        style: TextStyle(
                            color: isBuy ? c.profit : c.loss, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          _summaryRow(context, 'Subtotal', Money.format(_total, _currency)),
          const SizedBox(height: 6),
          _summaryRow(context, 'Commission', Money.format(_commissionVal, _currency)),
          const Divider(height: AppSpacing.lg),
          _summaryRow(
            context,
            _side == 'BUY' ? 'Total cost' : 'Net proceeds',
            Money.format(_side == 'BUY' ? _total + _commissionVal : _total - _commissionVal, _currency),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value, {bool bold = false}) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: bold ? c.textPrimary : c.textMuted, fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        Text(value,
            style: TextStyle(color: c.textPrimary, fontSize: bold ? 17 : 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
      ],
    );
  }

  // ── Confirm bottom sheet ────────────────────────────────────────────
  void _openConfirmSheet(Map<String, dynamic> initRes) {
    final c = context.colors;
    final isBuy = _side == 'BUY';
    final validationError = initRes['validationError'] as String?;
    final simulatedPnl = (initRes['simulatedPnl'] as num?) ?? 0;
    final isLoss = initRes['isLoss'] == true;
    final valid = initRes['valid'] != false && validationError == null;
    final ticker = _tickerController.text.trim().toUpperCase();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
            AppSpacing.lg + MediaQuery.of(ctx).viewInsets.bottom),
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
            Row(
              children: [
                _tickerCoin(context, size: 44),
                const SizedBox(width: AppSpacing.md),
                Text(ticker, style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isBuy ? c.profit : c.loss).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text('$_side · ${_market.label}',
                      style: TextStyle(color: isBuy ? c.profit : c.loss, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _summaryRow(context, 'Quantity', '$_qtyVal'),
            const SizedBox(height: 6),
            _summaryRow(context, 'Price', Money.format(_priceVal, _currency)),
            const SizedBox(height: 6),
            _summaryRow(context, 'Commission', Money.format(_commissionVal, _currency)),
            const SizedBox(height: 6),
            _summaryRow(context, 'Trade date',
                _orderDate == null ? 'Today' : DateFormat('d MMM yyyy').format(_orderDate!)),
            const Divider(height: AppSpacing.xl),
            _summaryRow(
              context,
              isBuy ? 'Total cost' : 'Net proceeds',
              Money.format(isBuy ? _total + _commissionVal : _total - _commissionVal, _currency),
              bold: true,
            ),
            // SELL simulation / validation
            if (!isBuy && valid) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: (isLoss ? c.loss : c.profit).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(isLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                        color: isLoss ? c.loss : c.profit),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Estimated P/L', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                    const Spacer(),
                    Text(Money.format(simulatedPnl, _currency, signed: true),
                        style: TextStyle(
                            color: isLoss ? c.loss : c.profit, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
            ],
            if (validationError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: c.loss.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: c.loss, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(validationError, style: TextStyle(color: c.loss, fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isBuy ? c.profit : c.loss,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    onPressed: valid ? _confirm : null,
                    child: Text('Confirm $_side',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
