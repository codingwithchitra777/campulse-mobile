/// Market metadata mirroring the backend `services/markets.py`. Each market maps
/// to a single currency; the record form uses this to pick the currency, the
/// decimal precision, and the input hints per market.
enum Market { csx, us, gold }

extension MarketX on Market {
  /// Backend market code sent in the trade payload.
  String get code => switch (this) {
        Market.csx => 'CSX',
        Market.us => 'US',
        Market.gold => 'GOLD_KH',
      };

  String get currency => switch (this) {
        Market.csx => 'KHR',
        Market.us => 'USD',
        Market.gold => 'USD',
      };

  String get label => switch (this) {
        Market.csx => 'CSX',
        Market.us => 'US',
        Market.gold => 'Gold',
      };

  /// Decimal places for the price input (KHR whole, USD two).
  int get priceDecimals => currency == 'USD' ? 2 : 0;

  /// Gold trades a single fixed instrument (per chi).
  String? get fixedSymbol => this == Market.gold ? 'XAU-KH' : null;

  static Market fromCode(String? code) => switch (code) {
        'US' => Market.us,
        'GOLD_KH' => Market.gold,
        _ => Market.csx,
      };
}
