import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// The welcome / sign-in surface shown to guests. A fanned stack of gradient
/// "portfolio" cards heads a bold welcome, with a high-contrast primary CTA
/// (Google sign-in) and a secondary demo entry — the ByteTown fintech look.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signInWithGoogle();
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAsGuestDemo() async {
    await AuthService.instance.loginAsDemo('u001', 'Sabay (Demo)');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, context.navBarClearance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            _cardStack(c),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Welcome to\nSmarter Investing',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 34,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Meet CamPulse — track your CSX, US & gold trades and see your real profit, all in one place.',
              style: TextStyle(color: c.textMuted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(_error!, style: TextStyle(color: c.loss, fontSize: 13), textAlign: TextAlign.center),
              ),
            // Primary CTA — high-contrast pill (dark on light, light on dark).
            _pillButton(
              label: 'Continue with Google',
              background: c.textPrimary,
              foreground: c.background,
              loading: _loading,
              onTap: _signInWithGoogle,
            ),
            const SizedBox(height: AppSpacing.md),
            // Secondary — surface pill with border.
            _pillButton(
              label: 'Try the demo',
              background: c.surface,
              foreground: c.textPrimary,
              border: c.border,
              onTap: _loading ? null : _continueAsGuestDemo,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text('🔐 Secured with your Google account',
                  style: TextStyle(color: c.textMuted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Fanned card stack hero ──────────────────────────────────────────
  Widget _cardStack(AppColors c) {
    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Back-left card (peach/pink accent), rotated out.
          Positioned(
            top: 8,
            child: Transform.rotate(
              angle: -0.12,
              child: _blankCard(gradient: c.accentGradient, width: 250, height: 155, glow: const Color(0xFFF472B6)),
            ),
          ),
          // Back-right card (violet), rotated the other way.
          Positioned(
            top: 4,
            child: Transform.rotate(
              angle: 0.10,
              child: _blankCard(
                gradient: LinearGradient(
                  colors: [c.primaryDark, c.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                width: 250,
                height: 155,
                glow: c.primaryDark,
              ),
            ),
          ),
          // Front card — the "portfolio" showcase.
          Positioned(top: 30, child: _frontCard(c)),
        ],
      ),
    );
  }

  Widget _blankCard({required Gradient gradient, required double width, required double height, required Color glow}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.30), blurRadius: 26, offset: const Offset(0, 12))],
      ),
    );
  }

  Widget _frontCard(AppColors c) {
    return Container(
      width: 300,
      height: 176,
      decoration: BoxDecoration(
        gradient: c.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.42), blurRadius: 30, offset: const Offset(0, 16))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Stack(
          children: [
            // Gloss highlight.
            Positioned(
              top: -40, right: -30,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Portfolio',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      _whitePill('Preview'),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('KHR · CSX',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, letterSpacing: 0.5)),
                  const Spacer(),
                  const Text('៛ 78,420,000',
                      style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Text('CamPulse',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_upward_rounded, size: 13, color: Colors.white),
                            SizedBox(width: 2),
                            Text('12.4%', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whitePill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _pillButton({
    required String label,
    required Color background,
    required Color foreground,
    Color? border,
    bool loading = false,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 56,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          onTap: loading ? null : onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: border != null ? Border.all(color: border) : null,
            ),
            child: loading
                ? SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: foreground))
                : Text(label,
                    style: TextStyle(color: foreground, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
