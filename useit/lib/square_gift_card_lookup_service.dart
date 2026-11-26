import 'package:supabase_flutter/supabase_flutter.dart';

class SquareGiftCardLookupService {
  Future<SquareGiftCardLookup> lookupSquareGiftCard(String gan) async {
    final response = await Supabase.instance.client.functions.invoke(
      'square-gift-card-lookup',
      body: {'gan': gan.trim()},
    );

    final responseBody = response.data;
    if (responseBody is! Map<String, dynamic>) {
      throw Exception('Square lookup returned an invalid response.');
    }

    final giftCard = responseBody['giftCard'];
    if (giftCard is! Map<String, dynamic>) {
      throw Exception('Square lookup did not return gift card details.');
    }
    return SquareGiftCardLookup.fromJson(giftCard);
  }
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