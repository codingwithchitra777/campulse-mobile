import 'package:intl/intl.dart';

/// Currency-aware money formatting, mirroring the web app's `MoneyPipe`.
///
/// Rules (do not blend currencies anywhere in the UI):
///   • KHR  → whole numbers, `123,456៛`
///   • USD  → two decimals, `$1,234.56`
/// Use [signed] for P/L so gains read `+…` and losses `-…` with the sign
/// *outside* the currency symbol.
class Money {
  Money._();

  static final _khr = NumberFormat('#,##0');
  static final _usd = NumberFormat('#,##0.00');

  static bool isUsd(String? currency) => (currency ?? 'KHR').toUpperCase() == 'USD';

  /// Formats [value] in [currency]. When [signed] is true, prepends an explicit
  /// `+`/`−` (the magnitude is formatted, the sign is placed before the symbol).
  static String format(num? value, String? currency, {bool signed = false}) {
    final v = value ?? 0;
    final usd = isUsd(currency);
    final magnitude = v.abs();
    final body = usd ? '\$${_usd.format(magnitude)}' : '${_khr.format(magnitude)}៛';

    if (signed) {
      final sign = v < 0 ? '−' : '+';
      return '$sign$body';
    }
    return v < 0 ? '−$body' : body;
  }

  /// Compact form for tight spaces: 12.3K / 1.2M / 3.4B (keeps the symbol).
  static String compact(num? value, String? currency) {
    final v = (value ?? 0).toDouble();
    final usd = isUsd(currency);
    final symbol = usd ? '\$' : '';
    final suffix = usd ? '' : '៛';
    final abs = v.abs();
    final sign = v < 0 ? '−' : '';
    String n;
    if (abs >= 1e9) {
      n = '${(abs / 1e9).toStringAsFixed(1)}B';
    } else if (abs >= 1e6) {
      n = '${(abs / 1e6).toStringAsFixed(1)}M';
    } else if (abs >= 1e3) {
      n = '${(abs / 1e3).toStringAsFixed(1)}K';
    } else {
      n = usd ? abs.toStringAsFixed(2) : abs.toStringAsFixed(0);
    }
    return '$sign$symbol$n$suffix';
  }
}
