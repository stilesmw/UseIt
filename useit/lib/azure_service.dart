import 'package:http/http.dart' as http;
import 'dart:convert';
import 'azure_config.dart'; 
class AzureService {
  
  static const String _baseUrl = AzureConfig.baseUrl;
  static const String _functionKey = AzureConfig.functionKey;


  
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
        print('Server returned error code for $routeName: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception thrown while connecting to $routeName: $e');
      return [];
    }
  }


  Future<List<dynamic>> getGiftCards() async => await _fetchTable('giftcards');

  Future<List<dynamic>> getMerchants() async => await _fetchTable('merchants');


  Future<List<dynamic>> getTransactions() async => await _fetchTable('transactions');


  Future<List<dynamic>> getUsers() async => await _fetchTable('users');
}