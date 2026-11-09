import '../azure_service.dart';

Future<SquareGiftCardLookup> getCard(String gan) =>
    AzureService().lookupSquareGiftCard(gan);
