import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton.dart';

/// Descriptive coach: a free, always-available rule-based read of the user's
/// patterns, with an optional paid AI pass (when the server has a key). Both are
/// descriptive, never advisory — the server appends the disclaimer.
class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final ApiService _api = ApiService.instance;
  bool _loading = true;
  bool _generating = false;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await _api.getInsights();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _toast('Could not load insights: $e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: context.colors.surfaceAlt));
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final res = await _api.refreshInsight();
      if (!mounted) return;
      // Merge the fresh AI pass into the current payload.
      setState(() {
        _data = {
          ...?_data,
          'ai': {
            'insight': res['insight'],
            'model': res['model'],
            'generatedAt': res['generatedAt'],
            'stale': false,
          },
        };
        _generating = false;
      });
      _toast(res['regenerated'] == true ? 'AI reading refreshed' : 'AI reading is up to date');
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading ? _skeleton() : _content(c),
      ),
    );
  }

  Widget _skeleton() => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Skeleton.card(height: 140),
          SizedBox(height: AppSpacing.lg),
          Skeleton.card(height: 120),
        ],
      );

  Widget _content(AppColors c) {
    final data = _data ?? {};
    final insight = (data['insight'] ?? '').toString();
    final disclaimer = (data['disclaimer'] ?? '').toString();
    final aiEnabled = data['aiEnabled'] == true;
    final ai = data['ai'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        // Free rule-based reading
        AppCard(
          gradient: c.primaryGradient,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text('YOUR READ',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(insight.isEmpty ? 'Record a few trades and your patterns will show up here.' : insight,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Optional paid AI pass
        SectionHeader(title: 'AI reading'),
        if (!aiEnabled)
          AppCard(
            color: c.surfaceAlt,
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: c.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('The deeper AI reading isn\'t enabled on the server yet — the read above is always free.',
                      style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          )
        else ...[
          if (ai != null) _aiCard(c, ai),
          if (ai == null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Get a deeper, cross-signal reading of your trading from the AI coach.',
                      style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.4)),
                  const SizedBox(height: AppSpacing.md),
                  _generateButton(c, label: 'Generate AI reading'),
                ],
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.xl),

        if (disclaimer.isNotEmpty)
          Text(disclaimer,
              style: TextStyle(color: c.textMuted, fontSize: 11, height: 1.4, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _aiCard(AppColors c, Map<String, dynamic> ai) {
    final text = (ai['insight'] ?? '').toString();
    final model = (ai['model'] ?? '').toString();
    final stale = ai['stale'] == true;
    final generatedAt = DateTime.tryParse((ai['generatedAt'] ?? '').toString());

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, size: 18, color: c.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('AI coach', style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (stale)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.warning.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text('Outdated',
                      style: TextStyle(color: c.warning, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(text, style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.5)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (generatedAt != null)
                Text('${model.isEmpty ? '' : '$model · '}${DateFormat('d MMM, h:mm a').format(generatedAt.toLocal())}',
                    style: TextStyle(color: c.textMuted, fontSize: 11)),
              const Spacer(),
              if (stale) _generateButton(c, label: 'Refresh', compact: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _generateButton(AppColors c, {required String label, bool compact = false}) {
    return SizedBox(
      height: compact ? 36 : 46,
      width: compact ? null : double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          padding: compact ? const EdgeInsets.symmetric(horizontal: AppSpacing.md) : null,
        ),
        onPressed: _generating ? null : _generate,
        icon: _generating
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
        label: Text(_generating ? 'Reading…' : label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
