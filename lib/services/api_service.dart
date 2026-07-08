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

  Future<List<dynamic>> getPortfolio() async {
    final response = await http.get(Uri.parse('$baseUrl/api/portfolio'), headers: _headers);
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
}
