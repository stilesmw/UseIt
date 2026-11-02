// Need flutter pub add http
import 'dart:convert';
import 'package:http/http.dart' as http;

const _token = 'EAAAlzyG3jJxsZqTlEAE8fYC3sviKR8f4YYLuJKZlDkNGCgne2GE9Diu4XHtXP7w';
const _location = 'LH90Q3J5435ZE';

// Sends request to Square
Future<Map> _square(String path, {Map? body}) async {
  final h = {
    'Authorization': 'Bearer $_token',
    'Square-Version': '2026-09-16',
    'Content-Type': 'application/json',
  };
  final uri = Uri.parse('https://connect.squareupsandbox.com$path');
  final res = body == null
      ? await http.get(uri, headers: h)
      : await http.post(uri, headers: h, body: jsonEncode(body));
  final data = jsonDecode(res.body) as Map;
  if (res.statusCode >= 400) throw data['errors'][0]['detail'];
  return data;
}

// Look up a card from the scanned number
Future<Map> getCard(String number) async =>
    (await _square('/v2/gift-cards/from-gan', body: {'gan': number}))['gift_card'];

// Take money off the card 
Future<void> redeem(String cardId, int cents) => _activity(cardId, 'REDEEM', cents);

// Add money to the card
Future<void> load(String cardId, int cents) => _activity(cardId, 'LOAD', cents);

Future<void> _activity(String cardId, String type, int cents) =>
    _square('/v2/gift-cards/activities', body: {
      'idempotency_key': DateTime.now().microsecondsSinceEpoch.toString(),
      'gift_card_activity': {
        'type': type,
        'location_id': _location,
        'gift_card_id': cardId,
        '${type.toLowerCase()}_activity_details': {
          'amount_money': {'amount': cents, 'currency': 'USD'},
          if (type == 'LOAD') 'buyer_payment_instrument_ids': ['test'],
        },
      },
    });