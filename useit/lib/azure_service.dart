import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'azure_config.dart'; 

class AzureService {
  
  static const String _baseUrl = AzureConfig.baseUrl;
  static const String _functionKey = AzureConfig.functionKey;

  Future<SquareGiftCardLookup> lookupSquareGiftCard(String gan) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/square/gift-cards/lookup'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'x-functions-key': _functionKey,
          },
          body: jsonEncode({'gan': gan}),
        )
        .timeout(const Duration(seconds: 15));

    Map<String, dynamic> responseBody;
    try {
      responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('Square lookup returned an invalid response.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        responseBody['error']?.toString() ??
            'Square lookup failed (${response.statusCode}).',
      );
    }

    final giftCard = responseBody['giftCard'];
    if (giftCard is! Map<String, dynamic>) {
      throw Exception('Square lookup did not return gift card details.');
    }
    return SquareGiftCardLookup.fromJson(giftCard);
  }

  
  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-functions-key': _functionKey, // Passes your secure cloud app function key
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'error': 'Cloud connection failed: $e'};
    }
  }

  
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-functions-key': _functionKey, // Passes your secure cloud app function key
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'error': 'Cloud connection failed: $e'};
    }
  }


  Future<List<dynamic>> _fetchTable(String routeName) async {
    final url = Uri.parse('$_baseUrl/$routeName');
    try {
      final response = await http.get(
        url,
        headers: {
          'x-functions-key': _functionKey, // Core validation key required for secure cloud table reads
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        debugPrint('Server returned error code for $routeName: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception thrown while connecting to $routeName: $e');
      return [];
    }
  }


  Future<List<dynamic>> getGiftCards() async => await _fetchTable('giftcards');

  Future<List<dynamic>> getMerchants() async => await _fetchTable('merchants');


  Future<List<dynamic>> getTransactions() async => await _fetchTable('transactions');


  Future<List<dynamic>> getUsers() async => await _fetchTable('users');
}

class SquareGiftCardLookup {
  const SquareGiftCardLookup({
    required this.id,
    required this.state,
    required this.balanceCents,
    required this.currency,
  });

  final String id;
  final String state;
  final int balanceCents;
  final String currency;

  bool get isActive => state.toUpperCase() == 'ACTIVE';

  factory SquareGiftCardLookup.fromJson(Map<String, dynamic> json) {
    final balance = json['balance'];
    if (json['id'] is! String ||
        json['state'] is! String ||
        balance is! Map<String, dynamic> ||
        balance['amount'] is! int ||
        balance['currency'] is! String) {
      throw Exception('Square returned incomplete gift card details.');
    }

    return SquareGiftCardLookup(
      id: json['id'] as String,
      state: json['state'] as String,
      balanceCents: balance['amount'] as int,
      currency: balance['currency'] as String,
    );
  }
}