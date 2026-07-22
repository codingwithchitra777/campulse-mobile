import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Singleton instance
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  String get baseUrl => 'https://campulse-backend.fastapicloud.dev';

  // Active user ID: 'guest' until a Google (or demo) sign-in sets it, mirroring
  // the web app's ApiService.activeUserId default (frontend/src/app/services/api.service.ts).
  String activeUserId = 'guest';

  // JWT minted by the backend at login. The backend's get_current_user verifies
  // this bearer token on every authed request — X-User-Id alone now 401s.
  String? authToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
        'X-User-Id': activeUserId,
      };

  Future<List<dynamic>> getPrices() async {
    final response = await http.get(Uri.parse('$baseUrl/api/prices'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load prices');
  }

  Future<List<dynamic>> getTrades({String? ticker}) async {
    String url = '$baseUrl/api/trades';
    if (ticker != null && ticker.isNotEmpty) {
      url += '?ticker=${ticker.toUpperCase()}';
    }
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // /api/trades is now paginated: {items, total, limit, offset}.
      if (decoded is Map && decoded['items'] is List) return decoded['items'] as List;
      if (decoded is List) return decoded; // legacy shape
      return const [];
    }
    throw Exception('Failed to load trades');
  }

  /// Trade payload shared by create/init/confirm. Price & commission are sent as
  /// numbers (Decimal-safe) so USD cents and fractional gold survive; market and
  /// currency drive multi-market recording (omit → backend defaults to CSX/KHR).
  Map<String, dynamic> _tradeBody(
    String ticker,
    String side,
    num price,
    int qty, {
    num? commission,
    String? market,
    String? currency,
    DateTime? orderDate,
  }) =>
      {
        'ticker': ticker.toUpperCase(),
        'side': side.toUpperCase(),
        'price': price,
        'qty': qty,
        if (commission != null) 'commission': commission,
        if (market != null) 'market': market,
        if (currency != null) 'currency': currency,
        if (orderDate != null) 'orderDate': orderDate.toUtc().toIso8601String(),
      };

  Future<Map<String, dynamic>> addTrade(String ticker, String side, num price, int qty,
      {num? commission, String? market, String? currency, DateTime? orderDate}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/trades'),
      headers: _headers,
      body: jsonEncode(_tradeBody(ticker, side, price, qty,
          commission: commission, market: market, currency: currency, orderDate: orderDate)),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> initTrade(String ticker, String side, num price, int qty,
      {num? commission, String? market, String? currency, DateTime? orderDate}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/trades/init'),
      headers: _headers,
      body: jsonEncode(_tradeBody(ticker, side, price, qty,
          commission: commission, market: market, currency: currency, orderDate: orderDate)),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(decoded['detail'] ?? decoded['error'] ?? 'Failed to validate trade');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> confirmTrade(String ticker, String side, num price, int qty,
      {num? commission, String? market, String? currency, DateTime? orderDate}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/trades/confirm'),
      headers: _headers,
      body: jsonEncode(_tradeBody(ticker, side, price, qty,
          commission: commission, market: market, currency: currency, orderDate: orderDate)),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(decoded['detail'] ?? decoded['error'] ?? 'Failed to submit trade');
    }
    return decoded;
  }

  /// US equity symbol lookup (Finnhub) for the record form's US market.
  Future<List<dynamic>> searchSymbols(String q) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/market/search').replace(queryParameters: {'q': q}),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded['results'] as List?) ?? const [];
    }
    return const [];
  }

  /// Market-aware live quote (CSX feed / Finnhub / gold board).
  Future<Map<String, dynamic>?> getMarketQuote(String symbol, String market) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/market/quote/${symbol.toUpperCase()}')
          .replace(queryParameters: {'market': market}),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>> getPosition(String symbol) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/position/${symbol.toUpperCase()}'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load position details');
  }

  Future<List<dynamic>> getPortfolio({String valuationMode = 'BID'}) async {
    final uri = Uri.parse('$baseUrl/api/portfolio').replace(queryParameters: {
      'valuationMode': valuationMode,
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load portfolio');
  }

  Future<List<dynamic>> getTopOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/api/top-orders'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load top orders');
  }

  Future<List<dynamic>> getTopTickers() async {
    final response = await http.get(Uri.parse('$baseUrl/api/top-tickers'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load top tickers');
  }

  Future<Map<String, dynamic>> googleLogin(String credential) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'credential': credential}),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(decoded['detail'] ?? 'Google sign-in failed');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> demoLogin(String userId, String userName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/demo'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'userName': userName}),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(decoded['detail'] ?? 'Demo sign-in failed');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> getChartsTimeline(String? market, String? targetCurrency, String valuationMode) async {
    final queryParams = <String, String>{};
    if (market != null && market.isNotEmpty && market != 'ALL') {
      queryParams['market'] = market;
    }
    if (targetCurrency != null && targetCurrency.isNotEmpty) {
      queryParams['targetCurrency'] = targetCurrency;
    }
    queryParams['valuationMode'] = valuationMode;

    final uri = Uri.parse('$baseUrl/api/charts/timeline').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load charts timeline');
  }

  Future<Map<String, dynamic>> getLatestExchangeRate(String baseCurrency, String targetCurrency) async {
    final uri = Uri.parse('$baseUrl/api/market/exchange-rates/latest').replace(queryParameters: {
      'baseCurrency': baseCurrency,
      'targetCurrency': targetCurrency,
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load latest exchange rate');
  }

  Future<Map<String, dynamic>> getExchangeRateHistory(String baseCurrency, String targetCurrency, {int limit = 30}) async {
    final uri = Uri.parse('$baseUrl/api/market/exchange-rates/history').replace(queryParameters: {
      'baseCurrency': baseCurrency,
      'targetCurrency': targetCurrency,
      'limit': limit.toString(),
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load exchange rate history');
  }

  // ── Loans (personal debt ledger, kept separate from trading) ──────────

  /// The user's loans. Returns `{items, deliverable}` — deliverable is false
  /// when no Telegram is linked (no repayment receipts possible).
  Future<Map<String, dynamic>> getLoans({String? direction, String? status}) async {
    final params = <String, String>{};
    if (direction != null) params['direction'] = direction;
    if (status != null) params['status'] = status;
    final uri = Uri.parse('$baseUrl/api/loans').replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to load loans');
  }

  /// Per (direction, currency) outstanding totals — never blended.
  Future<List<dynamic>> getLoansSummary() async {
    final response = await http.get(Uri.parse('$baseUrl/api/loans/summary'), headers: _headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded['items'] as List?) ?? const [];
    }
    throw Exception('Failed to load loan summary');
  }

  Future<Map<String, dynamic>> createLoan({
    required String direction,
    required String counterparty,
    required num principal,
    required String currency,
    DateTime? loanDate,
    DateTime? dueDate,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'direction': direction,
      'counterparty': counterparty,
      'principal': principal,
      'currency': currency,
      if (loanDate != null) 'loanDate': _dateOnly(loanDate),
      if (dueDate != null) 'dueDate': _dateOnly(dueDate),
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final response = await http.post(Uri.parse('$baseUrl/api/loans'),
        headers: _headers, body: jsonEncode(body));
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(decoded['detail'] ?? 'Failed to create loan');
    }
    return decoded as Map<String, dynamic>;
  }

  Future<void> deleteLoan(String loanId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/loans/$loanId'), headers: _headers);
    if (response.statusCode >= 400) throw Exception('Failed to delete loan');
  }

  Future<List<dynamic>> getRepayments(String loanId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/loans/$loanId/repayments'), headers: _headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded['items'] as List?) ?? const [];
    }
    throw Exception('Failed to load repayments');
  }

  Future<Map<String, dynamic>> addRepayment(String loanId,
      {required num amount, DateTime? paidDate, String? note}) async {
    final body = <String, dynamic>{
      'amount': amount,
      if (paidDate != null) 'paidDate': _dateOnly(paidDate),
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final response = await http.post(Uri.parse('$baseUrl/api/loans/$loanId/repayments'),
        headers: _headers, body: jsonEncode(body));
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(decoded['detail'] ?? 'Failed to record repayment');
    }
    return decoded as Map<String, dynamic>;
  }

  /// The loan API expects plain `YYYY-MM-DD` dates (not ISO timestamps).
  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<Map<String, dynamic>> getMarketPriceHistory(String symbol, {int days = 30}) async {
    final uri = Uri.parse('$baseUrl/api/market/price-history/$symbol').replace(queryParameters: {
      'days': days.toString(),
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load market price history');
  }
}
