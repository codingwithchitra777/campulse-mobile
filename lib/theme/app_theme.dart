import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Builds the light and dark [ThemeData] for CamPulse from the [AppColors]
/// tokens. Screens should pull colors from `context.colors` (the extension)
/// and rely on this theme for typography, cards, inputs, and app bars.
class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);
  static ThemeData light() => _build(Brightness.light, AppColors.light);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.onPrimary,
        surface: c.surface,
        error: c.loss,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: c.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: c.border),
        ),
      ),
      dividerColor: c.border,
      iconTheme: IconThemeData(color: c.textSecondary),
      textTheme: _textTheme(base.textTheme, c),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceAlt,
        hintStyle: TextStyle(color: c.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: c.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceAlt,
        contentTextStyle: TextStyle(color: c.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
    );
  }

  static TextTheme _textTheme(TextTheme base, AppColors c) {
    return base
        .copyWith(
          headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.35),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(
          bodyColor: c.textPrimary,
          displayColor: c.textPrimary,
        );
  }
}
