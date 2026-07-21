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

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
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
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load trades');
  }

  Future<Map<String, dynamic>> addTrade(String ticker, String side, int price, int qty, {int? commission}) async {
    final body = jsonEncode({
      'ticker': ticker.toUpperCase(),
      'side': side.toUpperCase(),
      'price': price,
      'qty': qty,
      if (commission != null) 'commission': commission,
    });
    final response = await http.post(
      Uri.parse('$baseUrl/api/trades'),
      headers: _headers,
      body: body,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> initTrade(String ticker, String side, int price, int qty, {int? commission}) async {
    final body = jsonEncode({
      'ticker': ticker.toUpperCase(),
      'side': side.toUpperCase(),
      'price': price,
      'qty': qty,
      if (commission != null) 'commission': commission,
    });
    final response = await http.post(
      Uri.parse('$baseUrl/api/trades/init'),
      headers: _headers,
      body: body,
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(decoded['detail'] ?? decoded['error'] ?? 'Failed to validate trade');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> confirmTrade(String ticker, String side, int price, int qty, {int? commission}) async {
    final body = jsonEncode({
      'ticker': ticker.toUpperCase(),
      'side': side.toUpperCase(),
      'price': price,
      'qty': qty,
      if (commission != null) 'commission': commission,
    });
    final response = await http.post(
      Uri.parse('$baseUrl/api/trades/confirm'),
      headers: _headers,
      body: body,
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(decoded['detail'] ?? decoded['error'] ?? 'Failed to submit trade');
    }
    return decoded;
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
