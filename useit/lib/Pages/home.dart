import 'package:flutter/material.dart';
import 'package:useit/Pages/Wallet.dart';

// One temporary session shared by Home and Wallet.
// Cards are not saved to Azure and disappear when the app restarts.
final WalletSession walletSession = WalletSession.preview();

const _background = Color(0xFF141518);
const _surface = Color(0xFF202126);
const _lime = Color(0xFF8FD14F);
const _lavender = Color(0xFFE4DFFF);
const _muted = Color(0xFFAAA7B7);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.user});

  final Map<String, dynamic>? user;

  @override
  Widget build(BuildContext context) => WalletHome(user: user);
}

class WalletHome extends StatelessWidget {
  const WalletHome({super.key, this.user});

  final Map<String, dynamic>? user;

  String get _userName {
    final name = user?['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    final email = user?['email']?.toString().trim() ?? '';
    return email.isNotEmpty ? email.split('@').first : 'there';
  }

  Future<void> _scanFromHome(BuildContext context) async {
    final barcode = await Navigator.pushNamed<dynamic>(context, '/scan');
    if (!context.mounted || barcode is! String || barcode.trim().isEmpty) {
      return;
    }

    await Navigator.pushNamed<dynamic>(context, '/wallet', arguments: barcode);
  }

  void _openWallet(BuildContext context) {
    Navigator.pushNamed<dynamic>(context, '/wallet');
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // WalletSession is a ChangeNotifier. This rebuilds Home after a card
    // is added, including when returning from Wallet to Home.
    return AnimatedBuilder(
      animation: walletSession,
      builder: (context, _) {
        final cards = walletSession.cards.toList()
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
        final recentCards = cards.take(3).toList();
        final missingBalances = cards.where((c) => c.balanceCents == null).length;
        final knownBalances = cards.length - missingBalances;
        final totalCents = cards.fold<int>(
          0,
          (total, card) => total + (card.balanceCents ?? 0),
        );

        return Scaffold(
          backgroundColor: _background,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $_userName',
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Your Wallet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Notifications',
                          onPressed: () => _comingSoon(context, 'Notifications'),
                          icon: const Icon(Icons.notifications_none_rounded),
                          color: _lavender,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _BalanceCard(
                      cardCount: cards.length,
                      knownBalances: knownBalances,
                      missingBalances: missingBalances,
                      totalCents: totalCents,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Scan Card',
                            onTap: () => _scanFromHome(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.add_rounded,
                            label: 'Add Manual',
                            onTap: () => _comingSoon(context, 'Manual card entry'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.grid_view_rounded,
                            label: 'Categories',
                            onTap: () => _comingSoon(context, 'Categories'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Recent Cards',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openWallet(context),
                          child: const Text('See all', style: TextStyle(color: _lime)),
                        ),
                      ],
                    ),
                    if (recentCards.isEmpty)
                      _EmptyCards(onScan: () => _scanFromHome(context))
                    else
                      ...recentCards.map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecentCard(
                            card: card,
                            onTap: () => _openWallet(context),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _SessionNote(isPreview: walletSession.isPreview),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: _HomeNavigation(
            onWallet: () => _openWallet(context),
            onScan: () => _scanFromHome(context),
            onCategories: () => _comingSoon(context, 'Categories'),
            onSettings: () => _comingSoon(context, 'Settings'),
          ),
        );
      },
    );
  }
}

String _money(int cents) {
  final dollars = (cents ~/ 100).toString();
  final fraction = (cents % 100).toString().padLeft(2, '0');
  final grouped = dollars.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '\$$grouped.$fraction';
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.cardCount,
    required this.knownBalances,
    required this.missingBalances,
    required this.totalCents,
  });

  final int cardCount;
  final int knownBalances;
  final int missingBalances;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final amount = cardCount > 0 && knownBalances == 0
        ? 'Not entered'
        : _money(totalCents);
    final countLabel = '$cardCount ${cardCount == 1 ? 'card' : 'cards'}';
    final note = missingBalances == 0
        ? countLabel
        : '$countLabel · $missingBalances without a balance';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF9BDF59), Color(0xFFE6E1FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL ENTERED BALANCE',
            style: TextStyle(
              color: Color(0xFF2E4530),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              color: Color(0xFF18251A),
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Text(note, style: const TextStyle(
            color: Color(0xFF304732), fontWeight: FontWeight.w700, fontSize: 12,
          )),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: _lime, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  color: _lavender,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.card, required this.onTap});

  final WalletGiftCard card;
  final VoidCallback onTap;

  Color get _color {
    final brand = card.merchant.toLowerCase();
    if (brand.contains('starbucks')) return const Color(0xFF087A51);
    if (brand.contains('amazon')) return const Color(0xFFEB880B);
    if (brand.contains('target')) return const Color(0xFFB61D31);
    if (brand.contains('walmart')) return const Color(0xFF0875C4);
    return const Color(0xFF474750);
  }

  @override
  Widget build(BuildContext context) {
    final initial = card.merchant.isEmpty ? '?' : card.merchant[0].toUpperCase();
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(initial, style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.merchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('•••• ${card.lastFour}', style: const TextStyle(
                      color: _muted, fontSize: 12,
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                card.balanceCents == null ? 'Not entered' : _money(card.balanceCents!),
                style: const TextStyle(color: _lime, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCards extends StatelessWidget {
  const _EmptyCards({required this.onScan});
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(15)),
    child: Column(
      children: [
        const Text('No cards added yet', style: TextStyle(
          color: _lavender, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 4),
        const Text('Scan a test card to get started.', style: TextStyle(color: _muted)),
        TextButton(onPressed: onScan,
          child: const Text('Scan a card', style: TextStyle(color: _lime))),
      ],
    ),
  );
}

class _SessionNote extends StatelessWidget {
  const _SessionNote({required this.isPreview});

  final bool isPreview;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF1C3023),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: _lime, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isPreview ? 'Preview includes sample cards' : 'Temporary wallet', style: const TextStyle(
                color: _lavender, fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 3),
              const Text('Cards are kept only while the app is open.', style: TextStyle(
                color: _muted, fontSize: 12,
              )),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HomeNavigation extends StatelessWidget {
  const _HomeNavigation({
    required this.onWallet,
    required this.onScan,
    required this.onCategories,
    required this.onSettings,
  });

  final VoidCallback onWallet;
  final VoidCallback onScan;
  final VoidCallback onCategories;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF1B1C21),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Row(
          children: [
            Expanded(child: _navItem(Icons.home_rounded, 'Home', () {}, selected: true)),
            Expanded(child: _navItem(Icons.wallet_rounded, 'Wallet', onWallet)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: _lime,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onScan,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.qr_code_scanner_rounded, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text('Scan', style: TextStyle(color: _muted, fontSize: 10)),
                ],
              ),
            ),
            Expanded(child: _navItem(Icons.grid_view_rounded, 'Categories', onCategories)),
            Expanded(child: _navItem(Icons.settings_rounded, 'Settings', onSettings)),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(IconData icon, String label, VoidCallback onTap, {bool selected = false}) {
    final color = selected ? _lime : _muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 3),
            Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
