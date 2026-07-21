import 'package:flutter/material.dart';

/// Semantic color tokens for CamPulse, exposed as a [ThemeExtension] so every
/// widget reads colors by *meaning* (surface, profit, textMuted…) instead of
/// hardcoding hex. Two instances are provided — [dark] and [light] — and the
/// active one is resolved via `Theme.of(context).extension<AppColors>()!`.
///
/// Palette is a Tailwind slate + blue + emerald family, matching the web app.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background; // app scaffold
  final Color surface; // cards, sheets, app bar
  final Color surfaceAlt; // chips, inputs, nested surfaces
  final Color border; // hairlines around surfaces
  final Color primary; // brand blue (actions, selected)
  final Color primaryDark; // gradient end / pressed
  final Color onPrimary; // text/icon on primary
  final Color profit; // positive P/L (emerald)
  final Color loss; // negative P/L (red)
  final Color textPrimary; // headings, values
  final Color textSecondary; // body
  final Color textMuted; // captions, labels
  final Color warning; // caution banners
  final Color navBar; // floating bottom-nav fill (pre-opacity)
  final Color shadow; // soft card shadow (ByteTown-style diffuse elevation)

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.profit,
    required this.loss,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.warning,
    required this.navBar,
    required this.shadow,
  });

  /// Indigo→violet hero gradient (ByteTown "credit card" look) used by the
  /// balance/profile hero cards and the primary FAB.
  LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Warm peach→pink accent gradient for secondary hero surfaces.
  LinearGradient get accentGradient => const LinearGradient(
        colors: [Color(0xFFFB9C7C), Color(0xFFF472B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Soft diffuse shadow for elevated cards (subtle in dark, airy in light).
  List<BoxShadow> get softShadow => [
        BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 8)),
      ];

  /// Green for gains, red for losses. Pass the signed value.
  Color pnl(num value) => value >= 0 ? profit : loss;

  static const dark = AppColors(
    background: Color(0xFF0B0B16),
    surface: Color(0xFF16172A),
    surfaceAlt: Color(0xFF20223A),
    border: Color(0xFF2A2C48),
    primary: Color(0xFF7C6CF6),
    primaryDark: Color(0xFF9333EA),
    onPrimary: Colors.white,
    profit: Color(0xFF22C55E),
    loss: Color(0xFFF4527A),
    textPrimary: Color(0xFFF3F3FB),
    textSecondary: Color(0xFFC7C8E0),
    textMuted: Color(0xFF8B8DAE),
    warning: Color(0xFFF59E0B),
    navBar: Color(0xFF141524),
    shadow: Color(0x66000000),
  );

  static const light = AppColors(
    background: Color(0xFFECEBFB), // soft lavender
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF3F2FD),
    border: Color(0xFFE7E5F7),
    primary: Color(0xFF6C5CE7), // indigo-violet
    primaryDark: Color(0xFF8B5CF6),
    onPrimary: Colors.white,
    profit: Color(0xFF12B76A),
    loss: Color(0xFFF04438),
    textPrimary: Color(0xFF1A1B2E),
    textSecondary: Color(0xFF4A4B66),
    textMuted: Color(0xFF8A8CA6),
    warning: Color(0xFFB45309),
    navBar: Color(0xFFFFFFFF),
    shadow: Color(0x1A6C5CE7), // soft violet-tinted shadow
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? primary,
    Color? primaryDark,
    Color? onPrimary,
    Color? profit,
    Color? loss,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? warning,
    Color? navBar,
    Color? shadow,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      onPrimary: onPrimary ?? this.onPrimary,
      profit: profit ?? this.profit,
      loss: loss ?? this.loss,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      warning: warning ?? this.warning,
      navBar: navBar ?? this.navBar,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      profit: Color.lerp(profit, other.profit, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Spacing / radius scale — one source of truth so every screen breathes the
/// same way. Use `AppSpacing.md` etc. instead of magic numbers.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Rounder, softer shapes (ByteTown fintech look).
  static const double radiusSm = 14;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusPill = 999;
}

/// Sugar: `context.colors.profit` from anywhere with a BuildContext.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
