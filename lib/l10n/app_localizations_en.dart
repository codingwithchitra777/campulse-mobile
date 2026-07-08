// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Trading Journal';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navPortfolio => 'Portfolio';

  @override
  String get navRecord => 'Record';

  @override
  String get navLedger => 'Ledger';

  @override
  String get titleDashboard => 'Dashboard';

  @override
  String get titlePortfolio => 'Portfolio';

  @override
  String get titleAddTrade => 'Add Trade';

  @override
  String get titleTradeLedger => 'Trade Ledger';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKhmer => 'ខ្មែរ';

  @override
  String get realisedPnl => 'Realised P/L';

  @override
  String get unrealisedPnl => 'Unrealised P/L';

  @override
  String get totalPnl => 'Total P/L';

  @override
  String get csxStockPrices => '📈 CSX Stock Prices';

  @override
  String get noPricesAvailable => 'No prices available';

  @override
  String get topTickers => '🏆 Top Tickers';

  @override
  String get topOrders => '🥇 Top Orders';

  @override
  String get noRankData => 'No rank data';

  @override
  String errorLoadingDashboard(String error) {
    return 'Error loading dashboard: $error';
  }

  @override
  String priceLabel(String price) {
    return 'Price: $price riel';
  }

  @override
  String get noActivePositions =>
      'No active positions.\nTry recording a BUY trade!';

  @override
  String remainingShares(String qty) {
    return 'Remaining: $qty shares';
  }

  @override
  String soldPercentLabel(String percent) {
    return 'Sold: $percent%';
  }

  @override
  String errorLoadingPortfolio(String error) {
    return 'Error loading portfolio: $error';
  }

  @override
  String get recordNewTrade => '➕ Record New Trade';

  @override
  String get tickerSymbolLabel => 'Ticker Symbol';

  @override
  String get tickerSymbolHint => 'e.g. ABC';

  @override
  String get tickerRequired => 'Ticker required';

  @override
  String get sideBuy => 'BUY';

  @override
  String get sideSell => 'SELL';

  @override
  String get pricePerShareRielLabel => 'Price per Share (riel)';

  @override
  String get pricePerShareHint => 'e.g. 7300';

  @override
  String get priceRequired => 'Price required';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String get quantitySharesLabel => 'Quantity (shares)';

  @override
  String get quantityHint => 'e.g. 100';

  @override
  String get quantityRequired => 'Quantity required';

  @override
  String get invalidQuantity => 'Invalid quantity';

  @override
  String confirmSide(String side) {
    return 'Confirm $side';
  }

  @override
  String get validating => 'Validating...';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get tradeConfirmedTitle => 'Trade Confirmed!';

  @override
  String recordedSummary(String qty, String ticker, String price) {
    return 'Recorded $qty shares of $ticker @ $price riel.';
  }

  @override
  String warningPrefix(String message) {
    return 'Warning: $message';
  }

  @override
  String get lifoMatchedLots => '📦 LIFO Matched Lots:';

  @override
  String matchedLotLine(String qty, String price) {
    return 'Matched $qty shares from Buy lot @ $price riel.';
  }

  @override
  String realisedProfitLossLabel(String value) {
    return 'Realised Profit/Loss: $value riel';
  }

  @override
  String get validationErrorTitle => '⚠️ Validation Error';

  @override
  String get confirmTransactionTitle => '🔔 Confirm Transaction';

  @override
  String validationFailedPrefix(String message) {
    return 'Validation Failed: $message';
  }

  @override
  String get adjustParametersHint => 'Please adjust your trade parameters.';

  @override
  String get returnToEdit => '✕ Return to Edit';

  @override
  String get stockTickerLabel => 'STOCK TICKER';

  @override
  String get actionLabel => 'ACTION';

  @override
  String get quantityRowLabel => 'QUANTITY';

  @override
  String quantityValue(String qty) {
    return '$qty shares';
  }

  @override
  String get pricePerShareValueLabel => 'PRICE PER SHARE';

  @override
  String get estimatedTotalLabel => 'ESTIMATED TOTAL';

  @override
  String get simulatedPnlLabel => 'Simulated P/L (Net of Fees)';

  @override
  String get sellLossWarningTitle => '⚠️ Warning: Sell at a Loss!';

  @override
  String sellLossWarningBody(String amount) {
    return 'Executing this transaction will result in a realized loss of $amount riel on a LIFO matching basis.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get yesSubmitTrade => 'Yes, Submit Trade';

  @override
  String get noTradesRecorded => 'No trades recorded yet.';

  @override
  String get pricePerShareColumn => 'Price per Share';

  @override
  String get quantityColumn => 'Quantity';

  @override
  String get commissionColumn => 'Commission';

  @override
  String errorLoadingHistory(String error) {
    return 'Error loading history: $error';
  }

  @override
  String detailsTitle(String ticker) {
    return '$ticker Details';
  }

  @override
  String get failedToLoadDetails => 'Failed to load details';

  @override
  String get totalBought => 'Total Bought';

  @override
  String get totalSold => 'Total Sold';

  @override
  String get remaining => 'Remaining';

  @override
  String get realisedPnlLabel => 'Realised P/L';

  @override
  String get buyOrdersTitle => '📈 Buy Orders (LIFO Queue)';

  @override
  String get sellOrdersTitle => 'Sell Orders';

  @override
  String get noBuyOrders => 'No buy orders.';

  @override
  String get noSellOrders => 'No sell orders.';

  @override
  String openSeqLabel(String seq) {
    return 'OPEN #$seq';
  }

  @override
  String soldSeqLabel(String seq) {
    return 'SOLD #$seq';
  }

  @override
  String qtyAtPrice(String qty, String price) {
    return '$qty@$price';
  }

  @override
  String matchedRow(String seq, String qty, String price) {
    return '↳ Matched #$seq: $qty@$price';
  }

  @override
  String get buyLotsAllocation => '📥 Buy Lots (LIFO Allocation)';

  @override
  String seqLabel(String seq) {
    return 'Seq #$seq';
  }

  @override
  String get lotOpen => 'Open';

  @override
  String get lotSold => 'Sold';

  @override
  String get remainingQtyLabel => 'Remaining Qty';

  @override
  String qtyOverQty(String open, String original) {
    return '$open / $original shares';
  }

  @override
  String get noOpenLots => 'No open lots remaining.';

  @override
  String errorLoadingPosition(String error) {
    return 'Error loading position details: $error';
  }

  @override
  String get authRequiredTitle => 'Authentication Required';

  @override
  String get authRequiredDesc =>
      'To view your active positions, record new transactions, or access your trade ledger history, please sign in using Google.';

  @override
  String get authFeatureLifo =>
      'LIFO Cost Basis Matching: Automatic tax-lot allocation of shares.';

  @override
  String get authFeaturePosition =>
      'Position Breakdown: Average remaining cost basis per share.';

  @override
  String get authFeatureSync =>
      'Real-time Synchronization: Shared backend with Telegram Bot.';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get continueAsGuestDemo =>
      'Or, continue as Guest using Demo Account (Sabay)';

  @override
  String get guestLabel => 'Guest';

  @override
  String get logout => 'Logout';

  @override
  String lastPriceLabel(String price) {
    return 'Last: $price';
  }

  @override
  String avgCostLabel(String price) {
    return 'Avg Cost: $price';
  }

  @override
  String get personalizedAnalyticsLocked => 'Personalized Analytics';

  @override
  String get personalizedAnalyticsLockedDesc =>
      'Sign in with your Google account to record trades, track your realised and unrealised profits, and see matching lots.';
}
