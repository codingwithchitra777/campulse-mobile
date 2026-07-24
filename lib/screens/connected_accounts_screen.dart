import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';

/// Link a Telegram account to this (Google) account so alerts, loan receipts,
/// and the bot all reach the user. A one-time code is minted here and redeemed
/// by the bot's `/start <code>` deep link.
class ConnectedAccountsScreen extends StatefulWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  State<ConnectedAccountsScreen> createState() => _ConnectedAccountsScreenState();
}

class _ConnectedAccountsScreenState extends State<ConnectedAccountsScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;
  bool _linking = false;
  List<dynamic> _links = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final links = await _api.getLinks();
      if (mounted) setState(() { _links = links; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _toast('Could not load linked accounts: $e');
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

  Future<void> _connect() async {
    setState(() => _linking = true);
    try {
      final res = await _api.createLinkCode();
      if (!mounted) return;
      setState(() => _linking = false);
      _showLinkSheet(
        code: (res['code'] ?? '').toString(),
        deepLink: (res['deepLink'] ?? '').toString(),
        botUsername: (res['botUsername'] ?? '').toString(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _linking = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _disconnect(dynamic link) async {
    final c = context.colors;
    final name = (link['userName'] ?? 'this account').toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Disconnect Telegram', style: TextStyle(color: c.textPrimary)),
        content: Text('Disconnect $name? Alerts and receipts will stop reaching this Telegram.',
            style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: c.textMuted))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.loss),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.removeLink((link['aliasUserId'] ?? '').toString());
      _toast('Disconnected', success: true);
      _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Connected accounts')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading ? _skeleton() : _content(c),
      ),
    );
  }

  Widget _skeleton() => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Skeleton.card(height: 120),
          SizedBox(height: AppSpacing.lg),
          Skeleton.card(height: 80),
        ],
      );

  Widget _content(AppColors c) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        // Explainer / connect hero
        AppCard(
          gradient: c.primaryGradient,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text('Telegram',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Link your Telegram to get price alerts, loan receipts, and use the @CamPulse bot on the same portfolio.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.5)),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 46,
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: c.primary,
                  ),
                  onPressed: _linking ? null : _connect,
                  icon: _linking
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.primary))
                      : const Icon(Icons.link_rounded, size: 20),
                  label: Text(_linking ? 'Preparing…' : 'Connect Telegram',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        SectionHeader(title: 'Linked accounts'),
        if (_links.isEmpty)
          AppCard(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: c.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('No Telegram linked yet. Connect one above.',
                      style: TextStyle(color: c.textSecondary, fontSize: 13)),
                ),
              ],
            ),
          )
        else
          for (final l in _links) ...[
            _linkCard(c, l),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }

  Widget _linkCard(AppColors c, dynamic l) {
    final name = (l['userName'] ?? 'Telegram user').toString();
    final chatId = (l['chatId'] ?? '').toString();
    String linked = '';
    final d = DateTime.tryParse((l['linkedAt'] ?? '').toString());
    if (d != null) linked = 'Linked ${DateFormat('d MMM yyyy').format(d.toLocal())}';

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primary.withValues(alpha: 0.14),
            ),
            child: Icon(Icons.send_rounded, color: c.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text([if (chatId.isNotEmpty) 'chat $chatId', if (linked.isNotEmpty) linked].join(' · '),
                    style: TextStyle(color: c.textMuted, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.link_off_rounded, color: c.loss),
            tooltip: 'Disconnect',
            onPressed: () => _disconnect(l),
          ),
        ],
      ),
    );
  }

  // ── Link sheet: open Telegram or copy the code ──────────────────────
  void _showLinkSheet({required String code, required String deepLink, required String botUsername}) {
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
            AppSpacing.lg + MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom),
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
            Text('Connect Telegram',
                style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            Text('Tap below to open Telegram and press Start — you\'ll be linked automatically. The code expires soon.',
                style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: AppSpacing.lg),
            // Code display + copy
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(code,
                        style: TextStyle(
                            color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy_rounded, color: c.primary, size: 20),
                    tooltip: 'Copy code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      _toast('Code copied', success: true);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: c.primary),
                onPressed: () => _openDeepLink(ctx, deepLink),
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
                label: const Text('Open Telegram',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _load();
                },
                child: Text('I\'ve linked it — refresh', style: TextStyle(color: c.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDeepLink(BuildContext sheetCtx, String deepLink) async {
    final uri = Uri.tryParse(deepLink);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      _toast('Could not open Telegram. Copy the code and use /start in @CamPulse.');
    }
  }
}
