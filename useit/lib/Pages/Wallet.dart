import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../azure_config.dart';
import '../azure_service.dart';
import 'scan.dart'; // Correct lowercase target match matching your filesystem 

const _background = Color(0xFF141518);
const _surface = Color(0xFF202126);
const _lime = Color(0xFF8FD14F);
const _lightText = Color(0xFFE4DFFF);
const _mutedText = Color(0xFFABAA7B);

class WalletSession extends ChangeNotifier {
  WalletSession() : isPreview = false;

  WalletSession.preview() : isPreview = true {
    final now = DateTime.now();
    _cards.addAll([
      WalletGiftCard(merchant: 'Starbucks', barcode: 'DEMO3301', balanceCents: 1845, originalCents: 2500, addedAt: now),
      WalletGiftCard(merchant: 'Amazon', barcode: 'DEMO8WLN', balanceCents: 7500, originalCents: 10000, addedAt: now.subtract(const Duration(minutes: 1))),
      WalletGiftCard(merchant: 'Apple', barcode: 'DEMO9BTL', balanceCents: 5000, originalCents: 5000, addedAt: now.subtract(const Duration(minutes: 2))),
    ]);
  }

  final bool isPreview;
  final List<WalletGiftCard> _cards = [];
  bool _isLoading = false;

  List<WalletGiftCard> get cards => List.unmodifiable(_cards);
  bool get isLoading => _isLoading;
  static const int _currentUserId = 1;

  /// Fetches gift cards cleanly from your Node.js Azure backend database route
    Future<void> fetchWalletCards() async {
    if (isPreview || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    final Uri url = Uri.parse('${AzureConfig.baseUrl}/giftcards');

    try {
      debugPrint("=== [DEBUG] FETCHING CARDS FROM: $url ===");
      final response = await http.get(
        url,
        headers: {'x-functions-key': AzureConfig.functionKey},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _cards.clear();
        for (var item in data) {
          final double balanceDecimal = (item['CurrentBalance'] ?? 0.0).toDouble();
          _cards.add(WalletGiftCard(
            merchant: item['Nickname'] ?? item['MerchantName'] ?? 'Unknown Merchant',
            barcode: item['RawBarcodeData'] ?? '',
            cardId: int.tryParse(item['CardID']?.toString() ?? ''),
            squareGiftCardId: item['SquareGiftCardID']?.toString(),
            status: item['Status']?.toString() ?? 'active',
            balanceCents: (balanceDecimal * 100).toInt(),
            originalCents: (balanceDecimal * 100).toInt(), 
            addedAt: item['DateAdded'] != null ? DateTime.parse(item['DateAdded']) : DateTime.now(),
          ));
        }
        debugPrint("=== [DEBUG] FETCHED ${_cards.length} CARDS SUCCESSFULLY ===");
      } else {
        debugPrint("=== [DEBUG] FETCH FAILED WITH STATUS: ${response.statusCode} ===");
      }
    } catch (error) {
      debugPrint("🚨 === [DEBUG] API RETRIEVAL ERROR TRACE: $error ===");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void add(WalletGiftCard card) {
    final existingIndex = _cards.indexWhere(
      (item) =>
          (card.cardId != null && item.cardId == card.cardId) ||
          (card.squareGiftCardId != null &&
              item.squareGiftCardId == card.squareGiftCardId),
    );
    if (existingIndex == -1) {
      _cards.add(card);
    } else {
      _cards[existingIndex] = card;
    }
    notifyListeners();
  }

  Future<void> softDelete(WalletGiftCard card) async {
    if (isPreview) {
      _cards.remove(card);
      notifyListeners();
      return;
    }

    final cardId = card.cardId;
    if (cardId == null) {
      throw StateError('This card has no database ID. Refresh the wallet and try again.');
    }

    final response = await http
        .delete(
          Uri.parse('${AzureConfig.baseUrl}/giftcards/$cardId'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'x-functions-key': AzureConfig.functionKey,
          },
          body: jsonEncode({'UserID': _currentUserId}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Delete failed (${response.statusCode}).';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] is String) {
          message = body['error'] as String;
        }
      } on FormatException {
        // Keep the status-based error when the server does not return JSON.
      }
      throw Exception(message);
    }

    _cards.removeWhere((item) => item.cardId == cardId);
    notifyListeners();
  }

  void clear() {
    _cards.clear();
    notifyListeners();
  }
}

class WalletGiftCard {
  const WalletGiftCard({
    required this.merchant,
    required this.barcode,
    required this.addedAt,
    this.cardId,
    this.squareGiftCardId,
    this.status = 'active',
    this.balanceCents,
    this.originalCents,
  });

  final String merchant;
  final String barcode;
  final DateTime addedAt;
  final int? cardId;
  final String? squareGiftCardId;
  final String status;
  final int? balanceCents;
  final int? originalCents;

  String get lastFour => barcode.length > 4 ? barcode.substring(barcode.length - 4) : barcode;

  double? get remainingFraction {
    final balance = balanceCents;
    final original = originalCents;
    if (balance == null || original == null || original <= 0 || balance > original) return null;
    return balance / original;
  }
}

enum _WalletSort { recent, balance, name }

class WalletPage extends StatefulWidget {
  const WalletPage({super.key, required this.session});
  final WalletSession session;

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  _WalletSort _sort = _WalletSort.recent;
  String _search = '';
  bool _checkedRouteArguments = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.session.fetchWalletCards();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedRouteArguments) return;
    _checkedRouteArguments = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is String && arguments.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reviewBarcode(arguments);
      });
    }
  }

  Future<void> _reviewBarcode(String barcode) async {
    final lookupFuture = AzureService().lookupSquareGiftCard(barcode.trim());
    final loadingDialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: _lime),
            SizedBox(width: 20),
            Expanded(child: Text('Looking up card in Square Sandbox...')),
          ],
        ),
      ),
    );

    late final SquareGiftCardLookup squareCard;
    try {
      squareCard = await lookupFuture;
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        await loadingDialog;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Square lookup failed: ${error.toString().replaceFirst('Exception: ', '')}',
              ),
            ),
          );
        }
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    await loadingDialog;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReviewCardSheet(
        barcode: barcode.trim(),
        squareCard: squareCard,
        onSaveSuccess: (newCard) => widget.session.add(newCard),
        onTriggerRefresh: () => widget.session.fetchWalletCards(),
      ),
    );
  }

  List<WalletGiftCard> _visibleCards() {
    final query = _search.trim().toLowerCase();
    final cards = widget.session.cards.where((card) {
      return card.merchant.toLowerCase().contains(query) || card.lastFour.toLowerCase().contains(query);
    }).toList();

    cards.sort((a, b) {
      switch (_sort) {
        case _WalletSort.recent:
          return b.addedAt.compareTo(a.addedAt);
        case _WalletSort.balance:
          if (a.balanceCents == null && b.balanceCents != null) return 1;
          if (b.balanceCents == null && a.balanceCents != null) return -1;
          return (b.balanceCents ?? 0).compareTo(a.balanceCents ?? 0);
        case _WalletSort.name:
          return a.merchant.toLowerCase().compareTo(b.merchant.toLowerCase());
      }
    });
    return cards;
  }

  String _formatMoney(int? cents) {
    if (cents == null) return '\$0.00';
    return '\$${(cents / 100).toStringAsFixed(2)}';
  }

  void _showCardDetails(WalletGiftCard card) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.merchant, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Scanned barcode', style: TextStyle(color: _mutedText, fontSize: 14)),
                  Text('•••• ${card.lastFour}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Balance', style: TextStyle(color: _mutedText, fontSize: 14)),
                  Text(_formatMoney(card.balanceCents), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Status', style: TextStyle(color: _mutedText, fontSize: 14)),
                  Text(
                    card.status.toUpperCase(),
                    style: TextStyle(
                      color: card.status.toUpperCase() == 'ACTIVE'
                          ? _lime
                          : Colors.orangeAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmDeleteCard(card),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text(
                    'Remove from wallet',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCard(WalletGiftCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Remove gift card?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This removes ${card.merchant} from your wallet. Its history will be kept, and you can add the Square card again later.',
          style: const TextStyle(color: _lightText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await widget.session.softDelete(card);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gift card removed from wallet.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final cards = _visibleCards();
        return Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            title: const Text('My Wallet', style: TextStyle(color: _lightText, fontWeight: FontWeight.bold)),
            backgroundColor: _surface,
            elevation: 0,
            iconTheme: const IconThemeData(color: _lightText),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (value) => setState(() => _search = value),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search gift cards...',
                      hintStyle: const TextStyle(color: _mutedText),
                      prefixIcon: const Icon(Icons.search, color: _mutedText),
                      filled: true,
                      fillColor: _surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Cards: ${cards.length}', style: const TextStyle(color: _lightText, fontSize: 16, fontWeight: FontWeight.w600)),
                      DropdownButton<_WalletSort>(
                        value: _sort,
                        dropdownColor: _surface,
                        icon: const Icon(Icons.sort, color: _lime),
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        onChanged: (_WalletSort? nv) => nv != null ? setState(() => _sort = nv) : null,
                        items: const [
                          DropdownMenuItem(value: _WalletSort.recent, child: Text('Sort by Recent')),
                          DropdownMenuItem(value: _WalletSort.balance, child: Text('Sort by Balance')),
DropdownMenuItem(value: _WalletSort.name, child: Text('Sort by Name')),
],
),
],
),
const SizedBox(height: 12),
Expanded(
child: widget.session.isLoading
? const Center(child: CircularProgressIndicator(color: _lime))
: cards.isEmpty
? const Center(child: Text('No gift cards found.', style: TextStyle(color: _mutedText, fontSize: 16)))
: ListView.builder(
itemCount: cards.length,
itemBuilder: (context, index) {
final card = cards[index];
return Card(
color: _surface,
margin: const EdgeInsets.symmetric(vertical: 6),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
child: ListTile(
title: Text(card.merchant, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
subtitle: Text(
  '•••• ${card.lastFour} · ${card.status.toUpperCase()}',
  style: const TextStyle(color: _mutedText),
),
trailing: Text(_formatMoney(card.balanceCents), style: const TextStyle(color: _lime, fontWeight: FontWeight.bold, fontSize: 16)),
onTap: () => _showCardDetails(card),
),
);
},
),
),
],
),
),
),
floatingActionButton: FloatingActionButton(
backgroundColor: _lime, // FIXED: Changed 'lime' to private 'lime' variable setup
onPressed: () async {
// FIXED: Dropped compilation 'const' prefix layout trigger to match variable widget execution structures
final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanPage()));
if (result is String && result.isNotEmpty && mounted) {
_reviewBarcode(result);
}
},
child: const Icon(Icons.qr_code_scanner, color: _background),
),
);
},
);
}
}
class _ReviewCardSheet extends StatefulWidget {
const _ReviewCardSheet({required this.barcode, required this.squareCard, required this.onSaveSuccess, required this.onTriggerRefresh});
final String barcode;
final SquareGiftCardLookup squareCard;
final Function(WalletGiftCard) onSaveSuccess;
final VoidCallback onTriggerRefresh;
@override
State<_ReviewCardSheet> createState() => _ReviewCardSheetState();
}
class _ReviewCardSheetState extends State<_ReviewCardSheet> {
final _nicknameController = TextEditingController();
final _balanceController = TextEditingController();
final _pinController = TextEditingController();
bool _isSending = false;
@override
void initState() {
  super.initState();
  _balanceController.text =
      (widget.squareCard.balanceCents / 100).toStringAsFixed(2);
}

@override
void dispose() {
_nicknameController.dispose();
_balanceController.dispose();
_pinController.dispose();
super.dispose();
}
Future<void> _submitPayloadToAzure() async {
if (_isSending) return;
setState(() => _isSending = true);
final Uri azureSaveUrl = Uri.parse('${AzureConfig.baseUrl}/giftcards');
try {
final balanceValue = widget.squareCard.balanceCents / 100;
Map<String, dynamic> giftCardPayload = {
"UserID": 1,
"MerchantID": null,
"SquareGiftCardID": widget.squareCard.id,
"RawBarcodeData": widget.barcode,
"Nickname": _nicknameController.text.trim().isEmpty ? 'Square Gift Card' : _nicknameController.text.trim(),
"CurrentBalance": balanceValue,
"Status": widget.squareCard.state.toLowerCase(),
"Pin": _pinController.text.trim().isEmpty ? null : _pinController.text.trim()
};
final response = await http.post(
azureSaveUrl,
headers: {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'x-functions-key': AzureConfig.functionKey,
},
body: jsonEncode(giftCardPayload),
).timeout(const Duration(seconds: 20));
if (response.statusCode >= 200 && response.statusCode < 300) {
if (!mounted) return;
final responseData = jsonDecode(response.body) as Map<String, dynamic>;
final cardId = int.tryParse(responseData['cardId']?.toString() ?? '');
if (cardId == null) {
  throw const FormatException('Save response did not include a card ID.');
}
final newCardItem = WalletGiftCard(
merchant: _nicknameController.text.trim().isEmpty ? 'Square Gift Card' : _nicknameController.text.trim(),
barcode: widget.barcode,
cardId: cardId,
squareGiftCardId: widget.squareCard.id,
status: widget.squareCard.state.toLowerCase(),
balanceCents: (balanceValue * 100).toInt(),
originalCents: (balanceValue * 100).toInt(),
addedAt: DateTime.now(),
);
widget.onSaveSuccess(newCardItem);
widget.onTriggerRefresh();
if (mounted) {
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Saved successfully!'), backgroundColor: Color(0xFF2C4721)),
);
}
} else {
final details = response.body.trim();
_showError(
  'Save failed (${response.statusCode})'
  '${details.isEmpty ? '.' : ': $details'}',
);
}
} on TimeoutException {
_showError('Saving the card timed out. Check your connection and try again.');
} catch (err) {
_showError('Unable to save the card: $err');
} finally {
if (mounted) setState(() => _isSending = false);
}
}
void _showError(String errMsg) {
if (!mounted) return;
showDialog(
context: context,
builder: (ctx) => AlertDialog(
backgroundColor: _surface,
title: const Text('Database Exception', style: TextStyle(color: Colors.white)),
content: Text(errMsg, style: const TextStyle(color: _lightText)),
actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: _lime)))],
),
);
}
@override
Widget build(BuildContext context) {
return Padding(
padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('Review Scanned Card', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
const SizedBox(height: 12),
Text('Barcode: ${widget.barcode}', style: const TextStyle(color: _lime, fontWeight: FontWeight.w600)),
Text(
  'Square status: ${widget.squareCard.state}',
  style: TextStyle(
    color: widget.squareCard.isActive ? _lime : Colors.orangeAccent,
    fontWeight: FontWeight.w700,
  ),
),
Text(
  'Square balance: ${(widget.squareCard.balanceCents / 100).toStringAsFixed(2)} ${widget.squareCard.currency}',
  style: const TextStyle(color: _lightText),
),
TextField(
controller: _nicknameController,
style: const TextStyle(color: Colors.white),
decoration: const InputDecoration(labelText: 'Nickname / Retailer', labelStyle: TextStyle(color: _mutedText)),
),
TextField(
controller: _balanceController,
readOnly: true,
keyboardType: const TextInputType.numberWithOptions(decimal: true),
style: const TextStyle(color: Colors.white),
decoration: const InputDecoration(
// FIXED: Added backslash escape element character token before the string interpolation identifier sign inside labels
labelText: 'Current Balance (\$)',
labelStyle: TextStyle(color: _mutedText),
),
),
TextField(
controller: _pinController,
style: const TextStyle(color: Colors.white),
decoration: const InputDecoration(labelText: 'PIN (Optional)', labelStyle: TextStyle(color: _mutedText)),
),
const SizedBox(height: 24),
SizedBox(
width: double.infinity,
height: 50,
child: ElevatedButton(
onPressed: _isSending ? null : _submitPayloadToAzure,
style: ElevatedButton.styleFrom(backgroundColor: _lime, foregroundColor: _background),
child: _isSending ? const CircularProgressIndicator(color: _background) : const Text('Save Card to Azure Cloud', style: TextStyle(fontWeight: FontWeight.bold)),
),
)
],
),
);
}
}
