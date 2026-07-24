// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appTitle => 'CamboPulse';

  @override
  String get navDashboard => 'ទំព័រដើម';

  @override
  String get navPortfolio => 'ផលប័ត្រ';

  @override
  String get navRecord => 'កត់ត្រា';

  @override
  String get navLedger => 'បញ្ជី';

  @override
  String get titleDashboard => 'ទំព័រដើម';

  @override
  String get titlePortfolio => 'ផលប័ត្រ';

  @override
  String get titleAddTrade => 'កត់ត្រាការជួញដូរ';

  @override
  String get titleTradeLedger => 'បញ្ជីការជួញដូរ';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKhmer => 'ខ្មែរ';

  @override
  String get realisedPnl => 'ចំណេញ/ខាតបានធ្វើ';

  @override
  String get unrealisedPnl => 'ចំណេញ/ខាតមិនទាន់ធ្វើ';

  @override
  String get totalPnl => 'ចំណេញ/ខាតសរុប';

  @override
  String get csxStockPrices => '📈 តម្លៃភាគហ៊ុន CSX';

  @override
  String get noPricesAvailable => 'មិនមានទិន្នន័យតម្លៃ';

  @override
  String get topTickers => '🏆 ភាគហ៊ុនកំពូល';

  @override
  String get topOrders => '🥇 ការជួញដូរកំពូល';

  @override
  String get noRankData => 'គ្មានទិន្នន័យចំណាត់ថ្នាក់';

  @override
  String get portfolioValue => 'តម្លៃផលប័ត្រ';

  @override
  String get todaysGain => 'ប្រាក់ចំណេញថ្ងៃនេះ';

  @override
  String get totalReturn => 'ប្រាក់ចំណេញសរុប';

  @override
  String get portfolioPerformance => 'ដំណើរការផលប័ត្រ';

  @override
  String get exchangeRateTrend => 'និន្នាការអត្រាប្តូរប្រាក់';

  @override
  String get goldPriceTrend => 'និន្នាការតម្លៃមាស';

  @override
  String get marketMovers => 'ភាគហ៊ុនដែលមានចលនាខ្លាំង';

  @override
  String get recentTrades => 'ការជួញដូរថ្មីៗ';

  @override
  String get valuationBid => 'ទិញចូល (Bid)';

  @override
  String get valuationAsk => 'លក់ចេញ (Ask)';

  @override
  String get allMarkets => 'ទីផ្សារទាំងអស់';

  @override
  String get csxMarket => 'CSX';

  @override
  String get goldMarket => 'មាស';

  @override
  String get usaMarket => 'អាមេរិក';

  @override
  String errorLoadingDashboard(String error) {
    return 'កំហុសក្នុងការផ្ទុកទិន្នន័យ៖ $error';
  }

  @override
  String priceLabel(String price) {
    return 'តម្លៃ៖ $price រៀល';
  }

  @override
  String get noActivePositions =>
      'មិនមានចំណុះបច្ចុប្បន្នទេ។\nសាកល្បងកត់ត្រាការទិញមួយ!';

  @override
  String remainingShares(String qty) {
    return 'នៅសល់៖ $qty ភាគហ៊ុន';
  }

  @override
  String soldPercentLabel(String percent) {
    return 'បានលក់៖ $percent%';
  }

  @override
  String errorLoadingPortfolio(String error) {
    return 'កំហុសក្នុងការផ្ទុកផលប័ត្រ៖ $error';
  }

  @override
  String get recordNewTrade => '➕ កត់ត្រាការជួញដូរថ្មី';

  @override
  String get tickerSymbolLabel => 'និមិត្តសញ្ញាភាគហ៊ុន';

  @override
  String get tickerSymbolHint => 'ឧ. ABC';

  @override
  String get tickerRequired => 'ត្រូវការនិមិត្តសញ្ញាភាគហ៊ុន';

  @override
  String get sideBuy => 'ទិញ';

  @override
  String get sideSell => 'លក់';

  @override
  String get pricePerShareRielLabel => 'តម្លៃមួយឯកតា (រៀល)';

  @override
  String get pricePerShareHint => 'ឧ. 7300';

  @override
  String get priceRequired => 'ត្រូវការតម្លៃ';

  @override
  String get invalidPrice => 'តម្លៃមិនត្រឹមត្រូវ';

  @override
  String get quantitySharesLabel => 'ចំនួន (ភាគហ៊ុន)';

  @override
  String get quantityHint => 'ឧ. 100';

  @override
  String get quantityRequired => 'ត្រូវការចំនួន';

  @override
  String get invalidQuantity => 'ចំនួនមិនត្រឹមត្រូវ';

  @override
  String confirmSide(String side) {
    return 'បញ្ជាក់ $side';
  }

  @override
  String get validating => 'កំពុងផ្ទៀងផ្ទាត់...';

  @override
  String errorPrefix(String message) {
    return 'កំហុស៖ $message';
  }

  @override
  String get tradeConfirmedTitle => 'ការជួញដូរបានបញ្ជាក់!';

  @override
  String recordedSummary(String qty, String ticker, String price) {
    return 'បានកត់ត្រា $qty ភាគហ៊ុននៃ $ticker ក្នុងតម្លៃ $price រៀល។';
  }

  @override
  String warningPrefix(String message) {
    return 'ការព្រមាន៖ $message';
  }

  @override
  String get lifoMatchedLots => '📦 ឡូតបានផ្គូផ្គង៖';

  @override
  String matchedLotLine(String qty, String price) {
    return 'បានផ្គូផ្គង $qty ភាគហ៊ុនពីឡូតទិញក្នុងតម្លៃ $price រៀល។';
  }

  @override
  String realisedProfitLossLabel(String value) {
    return 'ចំណេញ/ខាតបានធ្វើ៖ $value រៀល';
  }

  @override
  String get validationErrorTitle => '⚠️ កំហុសក្នុងការផ្ទៀងផ្ទាត់';

  @override
  String get confirmTransactionTitle => '🔔 បញ្ជាក់ប្រតិបត្តិការ';

  @override
  String validationFailedPrefix(String message) {
    return 'ការផ្ទៀងផ្ទាត់បរាជ័យ៖ $message';
  }

  @override
  String get adjustParametersHint =>
      'សូមកែសម្រួលប៉ារ៉ាម៉ែត្រការជួញដូររបស់អ្នក។';

  @override
  String get returnToEdit => '✕ ត្រឡប់ទៅកែសម្រួល';

  @override
  String get stockTickerLabel => 'និមិត្តសញ្ញាភាគហ៊ុន';

  @override
  String get actionLabel => 'សកម្មភាព';

  @override
  String get quantityRowLabel => 'ចំនួន';

  @override
  String quantityValue(String qty) {
    return '$qty ភាគហ៊ុន';
  }

  @override
  String get pricePerShareValueLabel => 'តម្លៃមួយឯកតា';

  @override
  String get estimatedTotalLabel => 'សរុបប៉ាន់ស្មាន';

  @override
  String get simulatedPnlLabel => 'ចំណេញ/ខាតប៉ាន់ស្មាន (បន្ទាប់ពីកម្រៃ)';

  @override
  String get sellLossWarningTitle => '⚠️ ការព្រមាន៖ លក់ខាត!';

  @override
  String sellLossWarningBody(String amount) {
    return 'ការអនុវត្តប្រតិបត្តិការនេះនឹងបណ្តាលឱ្យខាតជាក់ស្តែង $amount រៀល ដោយផ្អែកលើការផ្គូផ្គងតម្លៃថោកជាងមុន។';
  }

  @override
  String get cancel => 'បោះបង់';

  @override
  String get yesSubmitTrade => 'បាទ/ចាស ដាក់ស្នើការជួញដូរ';

  @override
  String get noTradesRecorded => 'មិនទាន់មានការជួញដូរបានកត់ត្រានៅឡើយទេ។';

  @override
  String get pricePerShareColumn => 'តម្លៃមួយឯកតា';

  @override
  String get quantityColumn => 'ចំនួន';

  @override
  String get commissionColumn => 'កម្រៃជើងសា';

  @override
  String errorLoadingHistory(String error) {
    return 'កំហុសក្នុងការផ្ទុកប្រវត្តិ៖ $error';
  }

  @override
  String detailsTitle(String ticker) {
    return 'លម្អិត $ticker';
  }

  @override
  String get failedToLoadDetails => 'បរាជ័យក្នុងការផ្ទុកព័ត៌មានលម្អិត';

  @override
  String get totalBought => 'ទិញសរុប';

  @override
  String get totalSold => 'លក់សរុប';

  @override
  String get remaining => 'នៅសល់';

  @override
  String get realisedPnlLabel => 'ចំណេញ/ខាតដែលបានដឹង';

  @override
  String get buyOrdersTitle => '📈 ការបញ្ជាទិញ';

  @override
  String get sellOrdersTitle => 'ការបញ្ជាលក់';

  @override
  String get noBuyOrders => 'គ្មានការបញ្ជាទិញទេ។';

  @override
  String get noSellOrders => 'គ្មានការបញ្ជាលក់ទេ។';

  @override
  String openSeqLabel(String seq) {
    return 'កំពុងបើក #$seq';
  }

  @override
  String soldSeqLabel(String seq) {
    return 'បានលក់ #$seq';
  }

  @override
  String qtyAtPrice(String qty, String price) {
    return '$qty@$price';
  }

  @override
  String matchedRow(String seq, String qty, String price) {
    return '↳ ផ្គូផ្គង #$seq៖ $qty@$price';
  }

  @override
  String get buyLotsAllocation => '📥 ឡូតទិញ (ការបែងចែកតម្លៃថោកមុន)';

  @override
  String seqLabel(String seq) {
    return 'លេខរៀង #$seq';
  }

  @override
  String get lotOpen => 'នៅបើក';

  @override
  String get lotSold => 'បានលក់';

  @override
  String get remainingQtyLabel => 'ចំនួននៅសល់';

  @override
  String qtyOverQty(String open, String original) {
    return '$open / $original ភាគហ៊ុន';
  }

  @override
  String get noOpenLots => 'គ្មានឡូតបើកនៅសល់ទេ។';

  @override
  String errorLoadingPosition(String error) {
    return 'កំហុសក្នុងការផ្ទុកព័ត៌មានចំណុះ៖ $error';
  }

  @override
  String get authRequiredTitle => 'ត្រូវការចូលគណនី';

  @override
  String get authRequiredDesc =>
      'ដើម្បីមើលប៉ូស៊ីស្យុងសកម្មរបស់អ្នក កត់ត្រាប្រតិបត្តិការថ្មី ឬចូលមើលប្រវត្តិកំណត់ហេតុជួញដូររបស់អ្នក សូមចូលគណនីដោយប្រើ Google។';

  @override
  String get authFeatureLifo =>
      'ការផ្គូផ្គងតម្លៃថោកជាងមុន៖ ការលក់ប្រើឡូតទិញដែលថោកបំផុតជាមុនសិន។';

  @override
  String get authFeaturePosition =>
      'ការបំបែកប៉ូស៊ីស្យុង៖ តម្លៃដើមមធ្យមនៅសល់ក្នុងមួយហ៊ុន។';

  @override
  String get authFeatureSync =>
      'ការធ្វើសមកាលកម្មតាមពេលវេលាជាក់ស្តែង៖ ប្រើ Backend រួមគ្នាជាមួយ Telegram Bot។';

  @override
  String get signInWithGoogle => 'ចូលគណនីជាមួយ Google';

  @override
  String get continueAsGuestDemo => 'ឬបន្តជាភ្ញៀវដោយប្រើគណនីសាកល្បង (សបាយ)';

  @override
  String get guestLabel => 'ភ្ញៀវ';

  @override
  String get logout => 'ចាកចេញ';

  @override
  String lastPriceLabel(String price) {
    return 'តម្លៃចុងក្រោយ៖ $price';
  }

  @override
  String avgCostLabel(String price) {
    return 'តម្លៃដើមមធ្យម៖ $price';
  }

  @override
  String get personalizedAnalyticsLocked => 'ការវិភាគផ្ទាល់ខ្លួន';

  @override
  String get personalizedAnalyticsLockedDesc =>
      'ចូលគណនីជាមួយ Google របស់អ្នកដើម្បីកត់ត្រាប្រតិបត្តិការ តាមដានប្រាក់ចំណេញ/ខាតដែលបានដឹង និងមិនទាន់ដឹង និងមើលឡូតដែលបានផ្គូផ្គង។';

  @override
  String get navLoanCalc => 'គណនាកម្ចី';

  @override
  String get loanTitle => 'កម្មវិធីគណនាកម្ចី';

  @override
  String get loanSubtitle =>
      'គ្រោងកម្ចី និងមើលតារាងសងប្រាក់ពេញលេញ មុនពេលចុះហត្ថលេខា។';

  @override
  String get loanAmount => 'ចំនួនកម្ចី';

  @override
  String get loanCurrency => 'រូបិយប័ណ្ណ';

  @override
  String get loanRate => 'អត្រាការប្រាក់';

  @override
  String get loanPerMonth => '% ក្នុងមួយខែ';

  @override
  String get loanPerYear => '% ក្នុងមួយឆ្នាំ';

  @override
  String get loanTerm => 'រយៈពេល (ខែ)';

  @override
  String get loanMethod => 'វិធីគណនាការប្រាក់';

  @override
  String get loanMethodDeclining => 'សមតុល្យថយចុះ';

  @override
  String get loanMethodFlat => 'អត្រាថេរ';

  @override
  String get loanMethodDecliningDesc =>
      'ការប្រាក់គិតលើសមតុល្យនៅសល់ (EMI) — តម្លៃពិតប្រាកដនៃកម្ចី។';

  @override
  String get loanMethodFlatDesc =>
      'ការប្រាក់គិតលើប្រាក់ដើមដំបូងរាល់ខែ — របៀបដែលធនាគារ និងគ្រឹះស្ថានមីក្រូហិរញ្ញវត្ថុកម្ពុជាភាគច្រើនប្រកាស។';

  @override
  String get loanStartDate => 'កាលបរិច្ឆេទចាប់ផ្តើមកម្ចី';

  @override
  String get loanCalc => 'បង្កើតតារាងសង';

  @override
  String get loanSummary => 'សង្ខេបកម្ចី';

  @override
  String get loanMonthlyPayment => 'បង់ប្រចាំខែ';

  @override
  String get loanTotalInterest => 'ការប្រាក់សរុប';

  @override
  String get loanTotalRepay => 'សងសរុប';

  @override
  String loanCmpFlatSelected(String other, String diff) {
    return 'បើគណនាតាមសមតុល្យថយចុះ កម្ចីដដែលនេះត្រូវការការប្រាក់ $other — តិចជាងអត្រាថេរ $diff។';
  }

  @override
  String loanCmpDecliningSelected(String other, String diff) {
    return 'បើប្រកាសជាអត្រាថេរ តួលេខដដែលនេះត្រូវការការប្រាក់ $other — ច្រើនជាង $diff។';
  }

  @override
  String get loanSchedule => 'តារាងសងប្រាក់';

  @override
  String get loanColNo => '#';

  @override
  String get loanColDate => 'កាលបរិច្ឆេទ';

  @override
  String get loanColPayment => 'បង់';

  @override
  String get loanColPrincipal => 'ប្រាក់ដើម';

  @override
  String get loanColInterest => 'ការប្រាក់';

  @override
  String get loanColBalance => 'សមតុល្យ';

  @override
  String get loanExportCsv => 'ទាញយក CSV';

  @override
  String get loanDisclaimer =>
      'គ្រាន់តែជាការប៉ាន់ស្មាន — តារាងពិតរបស់អ្នកឱ្យខ្ចី ថ្លៃសេវា និងការបង្គត់អាចខុសគ្នា។';

  @override
  String get loanErrInvalid => 'សូមបញ្ចូលចំនួន អត្រា និងរយៈពេលឱ្យត្រឹមត្រូវ។';

  @override
  String get loanErrTerm => 'រយៈពេលកំណត់ត្រឹម ៤៨០ ខែ។';

  @override
  String get loanEmpty => 'បំពេញព័ត៌មានកម្ចី រួចបង្កើតតារាងសង។';
}
