import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';

/// Trade journal — free-text notes and tags attached to individual trades.
/// Reads note/tags off the existing trades list; writes via the journal PATCH.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;
  List<dynamic> _trades = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final t = await _api.getTrades();
      if (mounted) setState(() { _trades = t; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _toast('Could not load journal: $e');
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

  bool _journaled(dynamic t) {
    final note = (t['note'] ?? '').toString().trim();
    final tags = (t['tags'] ?? '').toString().trim();
    return note.isNotEmpty || tags.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _openTradePicker,
        backgroundColor: c.primary,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text('New note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading ? _skeleton() : _content(c),
      ),
    );
  }

  Widget _skeleton() => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Skeleton.card(height: 110),
          SizedBox(height: AppSpacing.md),
          Skeleton.card(height: 110),
        ],
      );

  Widget _content(AppColors c) {
    final journaled = _trades.where(_journaled).toList();
    if (journaled.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.edit_note_rounded, size: 64, color: c.textMuted),
          const SizedBox(height: AppSpacing.lg),
          Text('No journal notes yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text('Add notes & tags to your trades to remember why you made them. Tap "New note".',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 14, height: 1.4)),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        SectionHeader(title: '${journaled.length} ${journaled.length == 1 ? 'note' : 'notes'}'),
        for (final t in journaled) ...[
          _entryCard(c, t),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _entryCard(AppColors c, dynamic t) {
    final ticker = (t['ticker'] ?? '').toString();
    final market = (t['market'] ?? 'CSX').toString();
    final side = (t['side'] ?? '').toString();
    final isBuy = side == 'BUY';
    final ccy = (t['currency'] as String?) ?? 'KHR';
    final price = (t['price'] as num?) ?? 0;
    final qty = (t['qty'] as num?) ?? 0;
    final note = (t['note'] ?? '').toString().trim();
    final tags = _parseTags((t['tags'] ?? '').toString());
    String date = '';
    final d = DateTime.tryParse((t['orderDate'] ?? '').toString());
    if (d != null) date = DateFormat('d MMM yyyy').format(d);

    return AppCard(
      onTap: () => _openEditor(t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _coin(c, ticker, market),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(ticker,
                            style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 6),
                        Text(side,
                            style: TextStyle(color: isBuy ? c.profit : c.loss, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${_qty(qty)} @ ${Money.format(price, ccy)}${date.isEmpty ? '' : ' · $date'}',
                        style: TextStyle(color: c.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textMuted),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(note, style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.4)),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 6,
              children: [for (final tag in tags) _tagChip(c, tag)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tagChip(AppColors c, String tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Text('#$tag',
            style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  List<String> _parseTags(String raw) => raw
      .split(RegExp(r'[,\s]+'))
      .map((t) => t.replaceAll('#', '').trim())
      .where((t) => t.isNotEmpty)
      .toList();

  String _qty(num q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

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

  // ── Pick a trade to journal ─────────────────────────────────────────
  void _openTradePicker() {
    final c = context.colors;
    if (_trades.isEmpty) {
      _toast('Record a trade first, then journal it.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Pick a trade to journal',
                    style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                itemCount: _trades.length,
                itemBuilder: (ctx, i) {
                  final t = _trades[i];
                  final ticker = (t['ticker'] ?? '').toString();
                  final market = (t['market'] ?? 'CSX').toString();
                  final side = (t['side'] ?? '').toString();
                  final ccy = (t['currency'] as String?) ?? 'KHR';
                  final price = (t['price'] as num?) ?? 0;
                  final has = _journaled(t);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openEditor(t);
                      },
                      child: Row(
                        children: [
                          _coin(c, ticker, market),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$ticker · $side',
                                    style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                                Text('#${t['seq']} · ${Money.format(price, ccy)}',
                                    style: TextStyle(color: c.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (has)
                            Icon(Icons.sticky_note_2_rounded, size: 16, color: c.primary),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Note/tags editor ────────────────────────────────────────────────
  void _openEditor(dynamic trade) {
    final noteCtl = TextEditingController(text: (trade['note'] ?? '').toString());
    final tagsCtl = TextEditingController(text: (trade['tags'] ?? '').toString());
    final ticker = (trade['ticker'] ?? '').toString();
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

          Future<void> save({required bool clear}) async {
            setSheet(() => saving = true);
            try {
              await _api.updateTradeJournal(
                (trade['tradeId'] ?? '').toString(),
                note: clear ? '' : noteCtl.text.trim(),
                tags: clear ? '' : tagsCtl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _toast(clear ? 'Note cleared' : 'Note saved ✓', success: !clear);
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
                Text('Journal · $ticker',
                    style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: noteCtl,
                  maxLines: 4,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Why did you make this trade? What did you learn?',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: tagsCtl,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    hintText: 'e.g. breakout swing earnings',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Space- or comma-separated. Shown as #tags.',
                    style: TextStyle(color: c.textMuted, fontSize: 11)),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    if (_journaled(trade))
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving ? null : () => save(clear: true),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: c.border),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          ),
                          child: Text('Clear', style: TextStyle(color: c.loss)),
                        ),
                      ),
                    if (_journaled(trade)) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: c.primary,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        ),
                        onPressed: saving ? null : () => save(clear: false),
                        child: saving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save note',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
