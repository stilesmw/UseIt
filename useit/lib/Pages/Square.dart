import '../square_gift_card_lookup_service.dart';

Future<SquareGiftCardLookup> getCard(String gan) =>
    SquareGiftCardLookupService().lookupSquareGiftCard(gan);
