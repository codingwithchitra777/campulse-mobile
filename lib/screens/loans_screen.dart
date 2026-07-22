import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';

/// Personal debt ledger — money lent to / borrowed from a named person, kept
/// entirely separate from trading. Currencies are never blended.
class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

enum _Filter { all, lent, borrowed }

class _LoansScreenState extends State<LoansScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;
  List<dynamic> _loans = [];
  List<dynamic> _summary = [];
  bool _deliverable = true;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final loans = await _api.getLoans();
      final summary = await _api.getLoansSummary();
      setState(() {
        _loans = loans['items'] as List? ?? [];
        _deliverable = loans['deliverable'] != false;
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _toast('Could not load loans: $e');
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

  List<dynamic> get _visible {
    return _loans.where((l) {
      if (_filter == _Filter.lent) return l['direction'] == 'lent';
      if (_filter == _Filter.borrowed) return l['direction'] == 'borrowed';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Loans')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddLoan,
        backgroundColor: c.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New loan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? _skeleton()
            : _loans.isEmpty
                ? _empty(c)
                : _content(c),
      ),
    );
  }

  Widget _skeleton() => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Skeleton.card(height: 96),
          SizedBox(height: AppSpacing.md),
          Skeleton.card(height: 110),
          SizedBox(height: AppSpacing.md),
          Skeleton.card(height: 110),
        ],
      );

  Widget _empty(AppColors c) => ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.handshake_rounded, size: 64, color: c.textMuted),
          const SizedBox(height: AppSpacing.lg),
          Text('No loans tracked yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text('Track money you\'ve lent out or borrowed. Tap "New loan" to start.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 14, height: 1.4)),
        ],
      );

  Widget _content(AppColors c) {
    final visible = _visible;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        if (_summary.isNotEmpty) ...[
          _summaryCard(c),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (!_deliverable) ...[
          _linkNudge(c),
          const SizedBox(height: AppSpacing.lg),
        ],
        _filterChips(c),
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: '${visible.length} ${visible.length == 1 ? 'loan' : 'loans'}'),
        if (visible.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('No loans in this filter', style: TextStyle(color: c.textMuted)),
              ),
            ),
          )
        else
          for (final l in visible) ...[
            _loanCard(c, l),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }

  Widget _summaryCard(AppColors c) {
    // Split summary rows into lent (owed to you) vs borrowed (you owe).
    final lent = _summary.where((s) => s['direction'] == 'lent').toList();
    final borrowed = _summary.where((s) => s['direction'] == 'borrowed').toList();

    Widget side(String label, List<dynamic> rows, IconData icon) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.85)),
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              if (rows.isEmpty)
                const Text('—', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))
              else
                for (final r in rows)
                  Text(Money.format((r['outstanding'] as num?) ?? 0, r['currency'] as String?),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        );

    return AppCard(
      gradient: c.primaryGradient,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          side('Owed to you', lent, Icons.call_received_rounded),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: AppSpacing.md),
          side('You owe', borrowed, Icons.call_made_rounded),
        ],
      ),
    );
  }

  Widget _linkNudge(AppColors c) => AppCard(
        color: c.surfaceAlt,
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: c.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text('Link Telegram to get forwardable repayment receipts.',
                  style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.3)),
            ),
          ],
        ),
      );

  Widget _filterChips(AppColors c) {
    Widget chip(_Filter f, String label) {
      final selected = _filter == f;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: GestureDetector(
          onTap: () => setState(() => _filter = f),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected ? c.primary : c.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: selected ? c.primary : c.border),
            ),
            child: Text(label,
                style: TextStyle(
                    color: selected ? c.onPrimary : c.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    return Row(children: [chip(_Filter.all, 'All'), chip(_Filter.lent, 'Lent'), chip(_Filter.borrowed, 'Borrowed')]);
  }

  Widget _loanCard(AppColors c, dynamic l) {
    final direction = (l['direction'] ?? 'lent').toString();
    final isLent = direction == 'lent';
    final ccy = (l['currency'] as String?) ?? 'KHR';
    final counterparty = (l['counterparty'] ?? '').toString();
    final outstanding = (l['outstanding'] as num?) ?? 0;
    final principal = (l['principal'] as num?) ?? 0;
    final status = (l['status'] ?? 'open').toString();
    final dirColor = isLent ? c.profit : c.loss;

    String due = '';
    final d = DateTime.tryParse((l['dueDate'] ?? '').toString());
    if (d != null) due = DateFormat('d MMM yyyy').format(d);
    final overdue = d != null && status != 'settled' && d.isBefore(DateTime.now());

    return AppCard(
      onTap: () => _openLoanDetail(l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _personCoin(c, counterparty, dirColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(counterparty,
                        style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(isLent ? 'Lent · they owe you' : 'Borrowed · you owe',
                        style: TextStyle(color: dirColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _statusPill(c, status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cell(c, 'Outstanding', Money.format(outstanding, ccy), color: dirColor),
              _cell(c, 'Principal', Money.format(principal, ccy)),
              _cell(c, 'Due', due.isEmpty ? '—' : due,
                  color: overdue ? c.loss : null, alignEnd: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(AppColors c, String label, String value, {Color? color, bool alignEnd = false}) => Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color ?? c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _personCoin(AppColors c, String name, Color color) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase();
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

  Widget _statusPill(AppColors c, String status) {
    final (color, label) = switch (status) {
      'settled' => (c.profit, 'Settled'),
      'partial' => (c.primary, 'Partial'),
      _ => (c.warning, 'Open'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  // ── Add loan sheet ──────────────────────────────────────────────────
  void _openAddLoan() {
    final counterparty = TextEditingController();
    final principal = TextEditingController();
    final note = TextEditingController();
    String direction = 'lent';
    String currency = 'KHR';
    DateTime? dueDate;
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final c = ctx.colors;
          final usd = currency == 'USD';

          Widget segToggle(String value, String label, String group, void Function(String) onPick, Color sel) {
            final selected = group == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => setSheet(() => onPick(value)),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? sel.withValues(alpha: 0.16) : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: selected ? sel : Colors.transparent),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: selected ? sel : c.textMuted, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            );
          }

          Future<void> submit() async {
            final name = counterparty.text.trim();
            final amt = num.tryParse(principal.text.trim()) ?? 0;
            if (name.isEmpty) return _toast('Enter who the loan is with');
            if (amt <= 0) return _toast('Enter a valid principal');
            setSheet(() => saving = true);
            try {
              await _api.createLoan(
                direction: direction,
                counterparty: name,
                principal: amt,
                currency: currency,
                dueDate: dueDate,
                note: note.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _toast('Loan added ✓', success: true);
              _load();
            } catch (e) {
              setSheet(() => saving = false);
              _toast(e.toString().replaceFirst('Exception: ', ''));
            }
          }

          return Padding(
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
                Text('New loan', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  decoration: BoxDecoration(
                    color: c.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(children: [
                    segToggle('lent', 'Lent out', direction, (v) => direction = v, c.profit),
                    segToggle('borrowed', 'Borrowed', direction, (v) => direction = v, c.loss),
                  ]),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: counterparty,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'With (person)', hintText: 'e.g. Dara'),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: principal,
                        keyboardType: TextInputType.numberWithOptions(decimal: usd),
                        inputFormatters: [
                          usd
                              ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                              : FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Principal',
                          prefixText: usd ? '\$ ' : null,
                          suffixText: usd ? null : '៛',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(children: [
                          segToggle('KHR', 'KHR', currency, (v) => currency = v, c.primary),
                          segToggle('USD', 'USD', currency, (v) => currency = v, c.primary),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate ?? now.add(const Duration(days: 30)),
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) setSheet(() => dueDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Due date (optional)'),
                          child: Row(children: [
                            Icon(Icons.event_rounded, size: 16, color: c.textMuted),
                            const SizedBox(width: 6),
                            Text(dueDate == null ? 'None' : DateFormat('d MMM yyyy').format(dueDate!),
                                style: TextStyle(color: c.textPrimary, fontSize: 14)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: c.primary),
                    onPressed: saving ? null : submit,
                    child: saving
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Add loan',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Loan detail (repayments) ────────────────────────────────────────
  void _openLoanDetail(dynamic loan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _LoanDetailSheet(
        loan: loan,
        api: _api,
        onChanged: _load,
      ),
    );
  }
}

/// Bottom sheet showing a loan's repayments and an inline "record repayment"
/// action. Kept stateful so it refreshes its own list after a repayment.
class _LoanDetailSheet extends StatefulWidget {
  final dynamic loan;
  final ApiService api;
  final VoidCallback onChanged;
  const _LoanDetailSheet({required this.loan, required this.api, required this.onChanged});

  @override
  State<_LoanDetailSheet> createState() => _LoanDetailSheetState();
}

class _LoanDetailSheetState extends State<_LoanDetailSheet> {
  late Map<String, dynamic> _loan;
  List<dynamic> _repayments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loan = Map<String, dynamic>.from(widget.loan as Map);
    _loadRepayments();
  }

  Future<void> _loadRepayments() async {
    try {
      final r = await widget.api.getRepayments(_loan['loanId'].toString());
      if (mounted) setState(() { _repayments = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _ccy => (_loan['currency'] as String?) ?? 'KHR';

  Future<void> _recordRepayment() async {
    final amountCtl = TextEditingController();
    final usd = _ccy == 'USD';
    final outstanding = (_loan['outstanding'] as num?) ?? 0;

    final result = await showDialog<num>(
      context: context,
      builder: (dctx) {
        final c = dctx.colors;
        return AlertDialog(
          backgroundColor: c.surface,
          title: Text('Record repayment', style: TextStyle(color: c.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Outstanding: ${Money.format(outstanding, _ccy)}',
                  style: TextStyle(color: c.textMuted, fontSize: 13)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: amountCtl,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(decimal: usd),
                inputFormatters: [
                  usd
                      ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      : FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: usd ? '\$ ' : null,
                  suffixText: usd ? null : '៛',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dctx), child: Text('Cancel', style: TextStyle(color: c.textMuted))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.primary),
              onPressed: () {
                final v = num.tryParse(amountCtl.text.trim()) ?? 0;
                if (v > 0) Navigator.pop(dctx, v);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    try {
      final res = await widget.api.addRepayment(_loan['loanId'].toString(), amount: result);
      final receiptSent = res['receiptSent'] == true;
      if (res['loan'] is Map) setState(() => _loan = Map<String, dynamic>.from(res['loan'] as Map));
      await _loadRepayments();
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(receiptSent ? 'Repayment saved · receipt sent to Telegram' : 'Repayment saved ✓'),
          backgroundColor: context.colors.profit,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isLent = _loan['direction'] == 'lent';
    final dirColor = isLent ? c.profit : c.loss;
    final outstanding = (_loan['outstanding'] as num?) ?? 0;
    final settled = _loan['status'] == 'settled';

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
          Row(
            children: [
              Text((_loan['counterparty'] ?? '').toString(),
                  style: TextStyle(color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(Money.format(outstanding, _ccy),
                  style: TextStyle(color: dirColor, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          Text('${isLent ? 'They owe you' : 'You owe'} · outstanding',
              style: TextStyle(color: c.textMuted, fontSize: 12)),
          const Divider(height: AppSpacing.xl),
          Text('Repayments', style: TextStyle(color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_repayments.isEmpty)
            Text('No repayments yet.', style: TextStyle(color: c.textMuted, fontSize: 13))
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final r in _repayments)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16, color: c.profit),
                          const SizedBox(width: AppSpacing.sm),
                          Text(_fmtDate(r['paidDate']), style: TextStyle(color: c.textSecondary, fontSize: 13)),
                          const Spacer(),
                          Text(Money.format((r['amount'] as num?) ?? 0, _ccy),
                              style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: settled ? c.surfaceAlt : c.primary),
              onPressed: settled ? null : _recordRepayment,
              icon: Icon(Icons.payments_rounded, color: settled ? c.textMuted : Colors.white, size: 20),
              label: Text(settled ? 'Fully settled' : 'Record repayment',
                  style: TextStyle(
                      color: settled ? c.textMuted : Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(dynamic v) {
    final d = DateTime.tryParse((v ?? '').toString());
    return d == null ? (v ?? '').toString() : DateFormat('d MMM yyyy').format(d);
  }
}
