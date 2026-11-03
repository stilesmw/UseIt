import 'package:flutter/material.dart';

const _background = Color(0xFF141518);
const _surface = Color(0xFF202126);
const _lime = Color(0xFF8FD14F);
const _lightText = Color(0xFFE4DFFF);
const _mutedText = Color(0xFFAAA7B7);

/// Temporary in-memory data shared by wallet screens during this app session.
/// This is NOT persistent storage. Clear it when a user signs out.
class WalletSession extends ChangeNotifier {
  WalletSession() : isPreview = false;

  /// Fictional cards to preview the design. Never use real card data here.
  WalletSession.preview() : isPreview = true {
    final now = DateTime.now();
    _cards.addAll([
      WalletGiftCard(merchant: 'Starbucks', barcode: 'DEMO3301',
          balanceCents: 1845, originalCents: 2500, addedAt: now),
      WalletGiftCard(merchant: 'Amazon', barcode: 'DEMO8WLN',
          balanceCents: 7500, originalCents: 10000,
          addedAt: now.subtract(const Duration(minutes: 1))),
      WalletGiftCard(merchant: 'Apple', barcode: 'DEMO9BTL',
          balanceCents: 5000, originalCents: 5000,
          addedAt: now.subtract(const Duration(minutes: 2))),
      WalletGiftCard(merchant: 'Target', barcode: 'DEMO1188',
          balanceCents: 1237, originalCents: 2500,
          addedAt: now.subtract(const Duration(minutes: 3))),
      WalletGiftCard(merchant: 'Nike', barcode: 'DEMO77Y3',
          balanceCents: 6000, originalCents: 6000,
          addedAt: now.subtract(const Duration(minutes: 4))),
    ]);
  }

  final bool isPreview;
  final List<WalletGiftCard> _cards = [];

  List<WalletGiftCard> get cards => List.unmodifiable(_cards);

  void add(WalletGiftCard card) {
    _cards.add(card);
    notifyListeners();
  }

  void clear() {
    _cards.clear();
    notifyListeners();
  }
}

/// Card values stay in memory only; never print or log the barcode.
class WalletGiftCard {
  const WalletGiftCard({
    required this.merchant,
    required this.barcode,
    required this.addedAt,
    this.balanceCents,
    this.originalCents,
  });

  final String merchant;
  final String barcode;
  final DateTime addedAt;
  final int? balanceCents;
  final int? originalCents;

  String get lastFour => barcode.length > 4
      ? barcode.substring(barcode.length - 4)
      : barcode;

  /// Remaining fraction is only meaningful if both balances are known.
  double? get remainingFraction {
    final balance = balanceCents;
    final original = originalCents;
    if (balance == null || original == null || original <= 0 ||
        balance > original) {
      return null;
    }
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedRouteArguments) return;
    _checkedRouteArguments = true;

    // A scan started from Home can pass its result to /wallet.
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is String && arguments.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reviewBarcode(arguments);
      });
    }
  }

  Future<void> _openScanner() async {
    final barcode = await Navigator.of(context).pushNamed<dynamic>('/scan');
    if (!mounted || barcode is! String || barcode.trim().isEmpty) return;
    await _reviewBarcode(barcode);
  }

  Future<void> _reviewBarcode(String barcode) async {
    final card = await showModalBottomSheet<WalletGiftCard>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReviewCardSheet(barcode: barcode.trim()),
    );

    if (!mounted || card == null) return;
    widget.session.add(card);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added for this app session only.')),
    );
  }

  List<WalletGiftCard> _visibleCards() {
    final query = _search.trim().toLowerCase();
    final cards = widget.session.cards.where((card) {
      return card.merchant.toLowerCase().contains(query) ||
          card.lastFour.toLowerCase().contains(query);
    }).toList();

    cards.sort((a, b) {
      switch (_sort) {
        case _WalletSort.recent:
          return b.addedAt.compareTo(a.addedAt);
        case _WalletSort.balance:
          if (a.balanceCents == null && b.balanceCents != null) return 1;
          if (b.balanceCents == null && a.balanceCents != null) return -1;
          final amount = (b.balanceCents ?? 0).compareTo(a.balanceCents ?? 0);
          return amount != 0 ? amount : b.addedAt.compareTo(a.addedAt);
        case _WalletSort.name:
          final name = a.merchant.toLowerCase().compareTo(b.merchant.toLowerCase());
          return name != 0 ? name : b.addedAt.compareTo(a.addedAt);
      }
    });
    return cards;
  }

  void _goHome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      _comingSoon('Go back to Home from your app navigation');
    }
  }

  void _comingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showCardDetails(WalletGiftCard card) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.merchant, style: const TextStyle(
                color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 20),
              _detailRow('Scanned barcode', '•••• ${card.lastFour}'),
              const SizedBox(height: 12),
              _detailRow('Balance', _formatMoney(card.balanceCents)),
              const SizedBox(height: 12),
              _detailRow('Original balance', _formatMoney(card.originalCents)),
              const SizedBox(height: 20),
              const Text('Card details and secure storage are coming next.',
                style: TextStyle(color: _mutedText)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final cards = _visibleCards();
        return Scaffold(
          backgroundColor: _background,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Wallet', style: TextStyle(
                        color: _lightText, fontSize: 25,
                        fontWeight: FontWeight.w700,
                      )),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (value) => setState(() => _search = value),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search cards...',
                          hintStyle: const TextStyle(color: _mutedText),
                          prefixIcon: const Icon(Icons.search, color: _mutedText),
                          filled: true,
                          fillColor: _surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        children: [
                          _sortChip('Recent', _WalletSort.recent),
                          _sortChip('Balance', _WalletSort.balance),
                          _sortChip('Name', _WalletSort.name),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.session.isPreview
                            ? 'Preview mode • Includes sample cards'
                            : 'Temporary wallet • Cards are not saved after closing the app',
                        style: const TextStyle(color: _mutedText, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: cards.isEmpty
                            ? _emptyState()
                            : ListView.separated(
                                padding: const EdgeInsets.only(bottom: 20),
                                itemCount: cards.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 14),
                                itemBuilder: (_, index) => _GiftCardTile(
                                  card: cards[index],
                                  onTap: () => _showCardDetails(cards[index]),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: _WalletNavigation(
            onHome: _goHome,
            onScan: _openScanner,
            onCategories: () => _comingSoon('Categories is coming soon.'),
            onSettings: () => _comingSoon('Settings is coming soon.'),
          ),
        );
      },
    );
  }

  Widget _sortChip(String label, _WalletSort sort) {
    final selected = _sort == sort;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _sort = sort),
      showCheckmark: false,
      selectedColor: _lime,
      backgroundColor: _surface,
      labelStyle: TextStyle(
        color: selected ? Colors.black : _lightText,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _emptyState() {
    final hasQuery = _search.trim().isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: _mutedText, size: 54),
          const SizedBox(height: 14),
          Text(hasQuery ? 'No matching cards' : 'No cards in your wallet yet',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _lightText, fontSize: 17,
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(hasQuery ? 'Try another search.' : 'Scan a test card to get started.',
            textAlign: TextAlign.center, style: const TextStyle(color: _mutedText)),
          if (!hasQuery) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _openScanner,
              style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan a card'),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _detailRow(String label, String value) => Row(
  children: [
    Expanded(child: Text(label, style: const TextStyle(color: _mutedText))),
    Flexible(child: Text(value, textAlign: TextAlign.end,
      style: const TextStyle(color: _lightText, fontWeight: FontWeight.w600))),
  ],
);

String _formatMoney(int? cents) {
  if (cents == null) return 'Not provided';
  final whole = cents ~/ 100;
  final fraction = (cents % 100).toString().padLeft(2, '0');
  return '\$$whole.$fraction';
}

class _GiftCardTile extends StatelessWidget {
  const _GiftCardTile({required this.card, required this.onTap});

  final WalletGiftCard card;
  final VoidCallback onTap;

  Color get _brandColor {
    final name = card.merchant.toLowerCase();
    if (name.contains('starbucks')) return const Color(0xFF08774A);
    if (name.contains('amazon')) return const Color(0xFFF47C00);
    if (name.contains('target')) return const Color(0xFFB90011);
    if (name.contains('walmart')) return const Color(0xFF0875C4);
    return const Color(0xFF303033);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = card.remainingFraction;
    final initial = card.merchant.isEmpty ? '?' : card.merchant[0].toUpperCase();
    return Material(
      color: _brandColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 165),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GIFT CARD', style: TextStyle(color: Colors.white70,
                        fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(card.merchant, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white,
                          fontSize: 19, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('•••• ${card.lastFour}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12,
                          letterSpacing: 1)),
                    ],
                  )),
                  const SizedBox(width: 10),
                  Container(
                    width: 42, height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white12,
                      borderRadius: BorderRadius.circular(12)),
                    child: Text(initial, style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(_formatMoney(card.balanceCents), maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w800)),
                    ],
                  )),
                  if (remaining != null) ...[
                    const SizedBox(width: 12),
                    SizedBox(width: 80, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Used ${((1 - remaining) * 100).round()}%',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 5),
                        ClipRRect(borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(value: remaining,
                            minHeight: 5, backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),
                      ],
                    )),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCardSheet extends StatefulWidget {
  const _ReviewCardSheet({required this.barcode});
  final String barcode;

  @override
  State<_ReviewCardSheet> createState() => _ReviewCardSheetState();
}

class _ReviewCardSheetState extends State<_ReviewCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _merchant = TextEditingController();
  final _balance = TextEditingController();
  final _original = TextEditingController();

  @override
  void dispose() {
    _merchant.dispose();
    _balance.dispose();
    _original.dispose();
    super.dispose();
  }

  String? _validateMoney(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(text)) {
      return 'Enter an amount like 25.00, or leave blank.';
    }
    return null;
  }

  int? _cents(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final parts = text.split('.');
    final dollars = int.parse(parts[0]);
    final fraction = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
    return dollars * 100 + int.parse(fraction);
  }

  void _add() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(WalletGiftCard(
      merchant: _merchant.text.trim(),
      barcode: widget.barcode,
      balanceCents: _cents(_balance.text),
      originalCents: _cents(_original.text),
      addedAt: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final barcode = widget.barcode;
    final lastFour = barcode.length > 4 ? barcode.substring(barcode.length - 4) : barcode;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, MediaQuery.of(context).viewInsets.bottom + 22),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Review gift card', style: TextStyle(color: Colors.white,
                fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Scanned barcode: •••• $lastFour', style: const TextStyle(color: _mutedText)),
              const SizedBox(height: 18),
              _input(_merchant, 'Merchant / brand', validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Enter a merchant name.';
                return null;
              }),
              const SizedBox(height: 12),
              _input(_balance, 'Current balance (optional)', money: true, validator: _validateMoney),
              const SizedBox(height: 12),
              _input(_original, 'Original balance (optional)', money: true, validator: _validateMoney),
              const SizedBox(height: 12),
              const Text('Temporary only: closing the app clears this card.',
                style: TextStyle(color: _mutedText, fontSize: 12)),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: _add,
                style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text('Add for this session'),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String label, {
    bool money = false, String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: money ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _lightText),
      prefixText: money ? '\$ ' : null,
      prefixStyle: const TextStyle(color: Colors.white),
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF555660))),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _lime)),
    ),
  );
}

class _WalletNavigation extends StatelessWidget {
  const _WalletNavigation({required this.onHome, required this.onScan,
    required this.onCategories, required this.onSettings});

  final VoidCallback onHome;
  final VoidCallback onScan;
  final VoidCallback onCategories;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF1B1C21),
    child: SafeArea(top: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Row(children: [
        Expanded(child: _navItem(Icons.home_rounded, 'Home', onHome)),
        Expanded(child: _navItem(Icons.account_balance_wallet_rounded, 'Wallet', () {}, selected: true)),
        Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Material(color: _lime, shape: const CircleBorder(),
            child: InkWell(onTap: onScan, customBorder: const CircleBorder(),
              child: const Padding(padding: EdgeInsets.all(14),
                child: Icon(Icons.qr_code_scanner_rounded, color: Colors.black)))),
          const SizedBox(height: 3),
          const Text('Scan', style: TextStyle(color: _mutedText, fontSize: 10)),
        ])),
        Expanded(child: _navItem(Icons.grid_view_rounded, 'Categories', onCategories)),
        Expanded(child: _navItem(Icons.settings_rounded, 'Settings', onSettings)),
      ]),
    )),
  );

  Widget _navItem(IconData icon, String label, VoidCallback onTap, {bool selected = false}) {
    final color = selected ? _lime : _mutedText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color),
          const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 10)),
        ]),
      ),
    );
  }
}
