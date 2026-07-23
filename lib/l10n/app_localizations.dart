import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CamPulse'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navDashboard;

  /// No description provided for @navPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get navPortfolio;

  /// No description provided for @navRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get navRecord;

  /// No description provided for @navLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get navLedger;

  /// No description provided for @titleDashboard.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get titleDashboard;

  /// No description provided for @titlePortfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get titlePortfolio;

  /// No description provided for @titleAddTrade.
  ///
  /// In en, this message translates to:
  /// **'Add Trade'**
  String get titleAddTrade;

  /// No description provided for @titleTradeLedger.
  ///
  /// In en, this message translates to:
  /// **'Trade Ledger'**
  String get titleTradeLedger;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageKhmer.
  ///
  /// In en, this message translates to:
  /// **'ខ្មែរ'**
  String get languageKhmer;

  /// No description provided for @realisedPnl.
  ///
  /// In en, this message translates to:
  /// **'Realised P/L'**
  String get realisedPnl;

  /// No description provided for @unrealisedPnl.
  ///
  /// In en, this message translates to:
  /// **'Unrealised P/L'**
  String get unrealisedPnl;

  /// No description provided for @totalPnl.
  ///
  /// In en, this message translates to:
  /// **'Total P/L'**
  String get totalPnl;

  /// No description provided for @csxStockPrices.
  ///
  /// In en, this message translates to:
  /// **'📈 CSX Stock Prices'**
  String get csxStockPrices;

  /// No description provided for @noPricesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No prices available'**
  String get noPricesAvailable;

  /// No description provided for @topTickers.
  ///
  /// In en, this message translates to:
  /// **'🏆 Top Tickers'**
  String get topTickers;

  /// No description provided for @topOrders.
  ///
  /// In en, this message translates to:
  /// **'🥇 Top Orders'**
  String get topOrders;

  /// No description provided for @noRankData.
  ///
  /// In en, this message translates to:
  /// **'No rank data'**
  String get noRankData;

  /// No description provided for @portfolioValue.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Value'**
  String get portfolioValue;

  /// No description provided for @todaysGain.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Gain'**
  String get todaysGain;

  /// No description provided for @totalReturn.
  ///
  /// In en, this message translates to:
  /// **'Total Return'**
  String get totalReturn;

  /// No description provided for @portfolioPerformance.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Performance'**
  String get portfolioPerformance;

  /// No description provided for @exchangeRateTrend.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate Trend'**
  String get exchangeRateTrend;

  /// No description provided for @goldPriceTrend.
  ///
  /// In en, this message translates to:
  /// **'Gold Price Trend'**
  String get goldPriceTrend;

  /// No description provided for @marketMovers.
  ///
  /// In en, this message translates to:
  /// **'Market Movers'**
  String get marketMovers;

  /// No description provided for @recentTrades.
  ///
  /// In en, this message translates to:
  /// **'Recent Trades'**
  String get recentTrades;

  /// No description provided for @valuationBid.
  ///
  /// In en, this message translates to:
  /// **'Bid'**
  String get valuationBid;

  /// No description provided for @valuationAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get valuationAsk;

  /// No description provided for @allMarkets.
  ///
  /// In en, this message translates to:
  /// **'All Markets'**
  String get allMarkets;

  /// No description provided for @csxMarket.
  ///
  /// In en, this message translates to:
  /// **'CSX'**
  String get csxMarket;

  /// No description provided for @goldMarket.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get goldMarket;

  /// No description provided for @usaMarket.
  ///
  /// In en, this message translates to:
  /// **'USA'**
  String get usaMarket;

  /// No description provided for @errorLoadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Error loading dashboard: {error}'**
  String errorLoadingDashboard(String error);

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price: {price} riel'**
  String priceLabel(String price);

  /// No description provided for @noActivePositions.
  ///
  /// In en, this message translates to:
  /// **'No active positions.\nTry recording a BUY trade!'**
  String get noActivePositions;

  /// No description provided for @remainingShares.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {qty} shares'**
  String remainingShares(String qty);

  /// No description provided for @soldPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Sold: {percent}%'**
  String soldPercentLabel(String percent);

  /// No description provided for @errorLoadingPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Error loading portfolio: {error}'**
  String errorLoadingPortfolio(String error);

  /// No description provided for @recordNewTrade.
  ///
  /// In en, this message translates to:
  /// **'➕ Record New Trade'**
  String get recordNewTrade;

  /// No description provided for @tickerSymbolLabel.
  ///
  /// In en, this message translates to:
  /// **'Ticker Symbol'**
  String get tickerSymbolLabel;

  /// No description provided for @tickerSymbolHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ABC'**
  String get tickerSymbolHint;

  /// No description provided for @tickerRequired.
  ///
  /// In en, this message translates to:
  /// **'Ticker required'**
  String get tickerRequired;

  /// No description provided for @sideBuy.
  ///
  /// In en, this message translates to:
  /// **'BUY'**
  String get sideBuy;

  /// No description provided for @sideSell.
  ///
  /// In en, this message translates to:
  /// **'SELL'**
  String get sideSell;

  /// No description provided for @pricePerShareRielLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per Share (riel)'**
  String get pricePerShareRielLabel;

  /// No description provided for @pricePerShareHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 7300'**
  String get pricePerShareHint;

  /// No description provided for @priceRequired.
  ///
  /// In en, this message translates to:
  /// **'Price required'**
  String get priceRequired;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// No description provided for @quantitySharesLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity (shares)'**
  String get quantitySharesLabel;

  /// No description provided for @quantityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 100'**
  String get quantityHint;

  /// No description provided for @quantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Quantity required'**
  String get quantityRequired;

  /// No description provided for @invalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity'**
  String get invalidQuantity;

  /// No description provided for @confirmSide.
  ///
  /// In en, this message translates to:
  /// **'Confirm {side}'**
  String confirmSide(String side);

  /// No description provided for @validating.
  ///
  /// In en, this message translates to:
  /// **'Validating...'**
  String get validating;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorPrefix(String message);

  /// No description provided for @tradeConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Trade Confirmed!'**
  String get tradeConfirmedTitle;

  /// No description provided for @recordedSummary.
  ///
  /// In en, this message translates to:
  /// **'Recorded {qty} shares of {ticker} @ {price} riel.'**
  String recordedSummary(String qty, String ticker, String price);

  /// No description provided for @warningPrefix.
  ///
  /// In en, this message translates to:
  /// **'Warning: {message}'**
  String warningPrefix(String message);

  /// No description provided for @lifoMatchedLots.
  ///
  /// In en, this message translates to:
  /// **'📦 Matched Lots:'**
  String get lifoMatchedLots;

  /// No description provided for @matchedLotLine.
  ///
  /// In en, this message translates to:
  /// **'Matched {qty} shares from Buy lot @ {price} riel.'**
  String matchedLotLine(String qty, String price);

  /// No description provided for @realisedProfitLossLabel.
  ///
  /// In en, this message translates to:
  /// **'Realised Profit/Loss: {value} riel'**
  String realisedProfitLossLabel(String value);

  /// No description provided for @validationErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Validation Error'**
  String get validationErrorTitle;

  /// No description provided for @confirmTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'🔔 Confirm Transaction'**
  String get confirmTransactionTitle;

  /// No description provided for @validationFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Validation Failed: {message}'**
  String validationFailedPrefix(String message);

  /// No description provided for @adjustParametersHint.
  ///
  /// In en, this message translates to:
  /// **'Please adjust your trade parameters.'**
  String get adjustParametersHint;

  /// No description provided for @returnToEdit.
  ///
  /// In en, this message translates to:
  /// **'✕ Return to Edit'**
  String get returnToEdit;

  /// No description provided for @stockTickerLabel.
  ///
  /// In en, this message translates to:
  /// **'STOCK TICKER'**
  String get stockTickerLabel;

  /// No description provided for @actionLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTION'**
  String get actionLabel;

  /// No description provided for @quantityRowLabel.
  ///
  /// In en, this message translates to:
  /// **'QUANTITY'**
  String get quantityRowLabel;

  /// No description provided for @quantityValue.
  ///
  /// In en, this message translates to:
  /// **'{qty} shares'**
  String quantityValue(String qty);

  /// No description provided for @pricePerShareValueLabel.
  ///
  /// In en, this message translates to:
  /// **'PRICE PER SHARE'**
  String get pricePerShareValueLabel;

  /// No description provided for @estimatedTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'ESTIMATED TOTAL'**
  String get estimatedTotalLabel;

  /// No description provided for @simulatedPnlLabel.
  ///
  /// In en, this message translates to:
  /// **'Simulated P/L (Net of Fees)'**
  String get simulatedPnlLabel;

  /// No description provided for @sellLossWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Warning: Sell at a Loss!'**
  String get sellLossWarningTitle;

  /// No description provided for @sellLossWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Executing this transaction will result in a realized loss of {amount} riel on a best-price (cheapest-lot-first) matching basis.'**
  String sellLossWarningBody(String amount);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @yesSubmitTrade.
  ///
  /// In en, this message translates to:
  /// **'Yes, Submit Trade'**
  String get yesSubmitTrade;

  /// No description provided for @noTradesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No trades recorded yet.'**
  String get noTradesRecorded;

  /// No description provided for @pricePerShareColumn.
  ///
  /// In en, this message translates to:
  /// **'Price per Share'**
  String get pricePerShareColumn;

  /// No description provided for @quantityColumn.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityColumn;

  /// No description provided for @commissionColumn.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get commissionColumn;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading history: {error}'**
  String errorLoadingHistory(String error);

  /// No description provided for @detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'{ticker} Details'**
  String detailsTitle(String ticker);

  /// No description provided for @failedToLoadDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load details'**
  String get failedToLoadDetails;

  /// No description provided for @totalBought.
  ///
  /// In en, this message translates to:
  /// **'Total Bought'**
  String get totalBought;

  /// No description provided for @totalSold.
  ///
  /// In en, this message translates to:
  /// **'Total Sold'**
  String get totalSold;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @realisedPnlLabel.
  ///
  /// In en, this message translates to:
  /// **'Realised P/L'**
  String get realisedPnlLabel;

  /// No description provided for @buyOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'📈 Buy Orders'**
  String get buyOrdersTitle;

  /// No description provided for @sellOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell Orders'**
  String get sellOrdersTitle;

  /// No description provided for @noBuyOrders.
  ///
  /// In en, this message translates to:
  /// **'No buy orders.'**
  String get noBuyOrders;

  /// No description provided for @noSellOrders.
  ///
  /// In en, this message translates to:
  /// **'No sell orders.'**
  String get noSellOrders;

  /// No description provided for @openSeqLabel.
  ///
  /// In en, this message translates to:
  /// **'OPEN #{seq}'**
  String openSeqLabel(String seq);

  /// No description provided for @soldSeqLabel.
  ///
  /// In en, this message translates to:
  /// **'SOLD #{seq}'**
  String soldSeqLabel(String seq);

  /// No description provided for @qtyAtPrice.
  ///
  /// In en, this message translates to:
  /// **'{qty}@{price}'**
  String qtyAtPrice(String qty, String price);

  /// No description provided for @matchedRow.
  ///
  /// In en, this message translates to:
  /// **'↳ Matched #{seq}: {qty}@{price}'**
  String matchedRow(String seq, String qty, String price);

  /// No description provided for @buyLotsAllocation.
  ///
  /// In en, this message translates to:
  /// **'📥 Buy Lots (Best-price Allocation)'**
  String get buyLotsAllocation;

  /// No description provided for @seqLabel.
  ///
  /// In en, this message translates to:
  /// **'Seq #{seq}'**
  String seqLabel(String seq);

  /// No description provided for @lotOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get lotOpen;

  /// No description provided for @lotSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get lotSold;

  /// No description provided for @remainingQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining Qty'**
  String get remainingQtyLabel;

  /// No description provided for @qtyOverQty.
  ///
  /// In en, this message translates to:
  /// **'{open} / {original} shares'**
  String qtyOverQty(String open, String original);

  /// No description provided for @noOpenLots.
  ///
  /// In en, this message translates to:
  /// **'No open lots remaining.'**
  String get noOpenLots;

  /// No description provided for @errorLoadingPosition.
  ///
  /// In en, this message translates to:
  /// **'Error loading position details: {error}'**
  String errorLoadingPosition(String error);

  /// No description provided for @authRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authRequiredTitle;

  /// No description provided for @authRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'To view your active positions, record new transactions, or access your trade ledger history, please sign in using Google.'**
  String get authRequiredDesc;

  /// No description provided for @authFeatureLifo.
  ///
  /// In en, this message translates to:
  /// **'Best-price lot matching: sales consume your cheapest open buy lots first.'**
  String get authFeatureLifo;

  /// No description provided for @authFeaturePosition.
  ///
  /// In en, this message translates to:
  /// **'Position Breakdown: Average remaining cost basis per share.'**
  String get authFeaturePosition;

  /// No description provided for @authFeatureSync.
  ///
  /// In en, this message translates to:
  /// **'Real-time Synchronization: Shared backend with Telegram Bot.'**
  String get authFeatureSync;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @continueAsGuestDemo.
  ///
  /// In en, this message translates to:
  /// **'Or, continue as Guest using Demo Account (Sabay)'**
  String get continueAsGuestDemo;

  /// No description provided for @guestLabel.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestLabel;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @lastPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Last: {price}'**
  String lastPriceLabel(String price);

  /// No description provided for @avgCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Cost: {price}'**
  String avgCostLabel(String price);

  /// No description provided for @personalizedAnalyticsLocked.
  ///
  /// In en, this message translates to:
  /// **'Personalized Analytics'**
  String get personalizedAnalyticsLocked;

  /// No description provided for @personalizedAnalyticsLockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Google account to record trades, track your realised and unrealised profits, and see matching lots.'**
  String get personalizedAnalyticsLockedDesc;

  /// No description provided for @navLoanCalc.
  ///
  /// In en, this message translates to:
  /// **'Loan Calculator'**
  String get navLoanCalc;

  /// No description provided for @loanTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan Calculator'**
  String get loanTitle;

  /// No description provided for @loanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan a loan and see the full repayment schedule before you sign.'**
  String get loanSubtitle;

  /// No description provided for @loanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan amount'**
  String get loanAmount;

  /// No description provided for @loanCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get loanCurrency;

  /// No description provided for @loanRate.
  ///
  /// In en, this message translates to:
  /// **'Interest rate'**
  String get loanRate;

  /// No description provided for @loanPerMonth.
  ///
  /// In en, this message translates to:
  /// **'% per month'**
  String get loanPerMonth;

  /// No description provided for @loanPerYear.
  ///
  /// In en, this message translates to:
  /// **'% per year'**
  String get loanPerYear;

  /// No description provided for @loanTerm.
  ///
  /// In en, this message translates to:
  /// **'Term (months)'**
  String get loanTerm;

  /// No description provided for @loanMethod.
  ///
  /// In en, this message translates to:
  /// **'Interest method'**
  String get loanMethod;

  /// No description provided for @loanMethodDeclining.
  ///
  /// In en, this message translates to:
  /// **'Declining balance'**
  String get loanMethodDeclining;

  /// No description provided for @loanMethodFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat rate'**
  String get loanMethodFlat;

  /// No description provided for @loanMethodDecliningDesc.
  ///
  /// In en, this message translates to:
  /// **'Interest is charged on what you still owe (EMI) — the true cost of the loan.'**
  String get loanMethodDecliningDesc;

  /// No description provided for @loanMethodFlatDesc.
  ///
  /// In en, this message translates to:
  /// **'Interest is charged on the original amount every month — how most Cambodian banks and MFIs quote.'**
  String get loanMethodFlatDesc;

  /// No description provided for @loanStartDate.
  ///
  /// In en, this message translates to:
  /// **'Loan start date'**
  String get loanStartDate;

  /// No description provided for @loanCalc.
  ///
  /// In en, this message translates to:
  /// **'Generate schedule'**
  String get loanCalc;

  /// No description provided for @loanSummary.
  ///
  /// In en, this message translates to:
  /// **'Loan Summary'**
  String get loanSummary;

  /// No description provided for @loanMonthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY PAYMENT'**
  String get loanMonthlyPayment;

  /// No description provided for @loanTotalInterest.
  ///
  /// In en, this message translates to:
  /// **'TOTAL INTEREST'**
  String get loanTotalInterest;

  /// No description provided for @loanTotalRepay.
  ///
  /// In en, this message translates to:
  /// **'TOTAL REPAYMENT'**
  String get loanTotalRepay;

  /// No description provided for @loanCmpFlatSelected.
  ///
  /// In en, this message translates to:
  /// **'On declining balance, the same loan would cost {other} in interest — {diff} less than this flat quote.'**
  String loanCmpFlatSelected(String other, String diff);

  /// No description provided for @loanCmpDecliningSelected.
  ///
  /// In en, this message translates to:
  /// **'Quoted as a flat rate, the same numbers would cost {other} in interest — {diff} more.'**
  String loanCmpDecliningSelected(String other, String diff);

  /// No description provided for @loanSchedule.
  ///
  /// In en, this message translates to:
  /// **'Repayment Schedule'**
  String get loanSchedule;

  /// No description provided for @loanColNo.
  ///
  /// In en, this message translates to:
  /// **'#'**
  String get loanColNo;

  /// No description provided for @loanColDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get loanColDate;

  /// No description provided for @loanColPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get loanColPayment;

  /// No description provided for @loanColPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get loanColPrincipal;

  /// No description provided for @loanColInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get loanColInterest;

  /// No description provided for @loanColBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get loanColBalance;

  /// No description provided for @loanExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get loanExportCsv;

  /// No description provided for @loanDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Estimates only — actual lender schedules, fees and rounding may differ.'**
  String get loanDisclaimer;

  /// No description provided for @loanErrInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount, rate and term.'**
  String get loanErrInvalid;

  /// No description provided for @loanErrTerm.
  ///
  /// In en, this message translates to:
  /// **'Term is limited to 480 months.'**
  String get loanErrTerm;

  /// No description provided for @loanEmpty.
  ///
  /// In en, this message translates to:
  /// **'Fill in the loan details and generate the schedule.'**
  String get loanEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
