import 'package:flutter/material.dart';

const _background = Color(0xFF141518);
const _surface = Color(0xFF202126);
const _lime = Color(0xFF8FD14F);
const _lavender = Color(0xFFE4DFFF);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WalletHome();
  }
}

class GiftCardSummary {
  const GiftCardSummary({
    required this.merchant,
    required this.maskedNumber,
    required this.balance,
    required this.updated,
    required this.color,
    required this.mark,
    this.markColor = Colors.white,
  });

  final String merchant;
  final String maskedNumber;
  final String balance;
  final String updated;
  final Color color;
  final String mark;
  final Color markColor;
}

/// Static data source; replace with a SQLite-backed repository when available.
class WalletHome extends StatelessWidget {
  const WalletHome({super.key});

  static const cards = <GiftCardSummary>[
    GiftCardSummary(
      merchant: 'Starbucks',
      maskedNumber: '2847 3301',
      balance: '\$18.45',
      updated: '2 days ago',
      color: Color(0xFF087348),
      mark: '★',
    ),
    GiftCardSummary(
      merchant: 'Amazon',
      maskedNumber: 'PK2M-8WLN',
      balance: '\$75.00',
      updated: '1 week ago',
      color: Color(0xFFE28A35),
      mark: 'A',
    ),
    GiftCardSummary(
      merchant: 'Apple',
      maskedNumber: '2W3R-9BTL',
      balance: '\$50.00',
      updated: 'Never',
      color: Color(0xFF393A40),
      mark: '●',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _Header(),
                  const SizedBox(height: 24),
                  const _BalanceCard(),
                  const SizedBox(height: 24),
                  const _QuickActions(),
                  const SizedBox(height: 28),
                  _RecentCards(cards: cards),
                  const SizedBox(height: 22),
                  const _SecurityBanner(),
                  const SizedBox(height: 18),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavigation(),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .58),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your Wallet',
              style: TextStyle(
                color: _lavender,
                fontSize: 29,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5,
              ),
            ),
          ],
        ),
      ),
      Material(
        color: _surface,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: 'Notifications',
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: _lavender),
        ),
      ),
    ],
  );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) => Container(
    height: 174,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF8FD14F), Color(0xFFC7DDA8), Color(0xFFE4DFFF)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TOTAL BALANCE',
          style: TextStyle(
            color: Color(0xFF30342B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '\$224.74',
          style: TextStyle(
            color: Color(0xFF191B1A),
            fontSize: 38,
            height: 1.1,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            const Text(
              '6 active cards',
              style: TextStyle(
                color: Color(0xFF30342B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData('Scan Card', Icons.qr_code_scanner_rounded, '/scan'),
      _ActionData('Add Manual', Icons.add_rounded, '/add-card'),
      _ActionData('Categories', Icons.grid_view_rounded, '/categories'),
    ];
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: _ActionButton(action: actions[i])),
          if (i != actions.length - 1) const SizedBox(width: 11),
        ],
      ],
    );
  }
}

class _ActionData {
  const _ActionData(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});
  final _ActionData action;

  @override
  Widget build(BuildContext context) => Material(
    color: _surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(context, action.route),
      child: SizedBox(
        height: 92,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: _lime, size: 25),
            const SizedBox(height: 9),
            Text(
              action.label,
              maxLines: 1,
              style: const TextStyle(
                color: _lavender,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecentCards extends StatelessWidget {
  const _RecentCards({required this.cards});
  final List<GiftCardSummary> cards;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const Text(
            'Recent Cards',
            style: TextStyle(
              color: _lavender,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/wallet'),
            style: TextButton.styleFrom(
              foregroundColor: _lime,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'See all',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      for (final card in cards) ...[
        _CardRow(card: card),
        const SizedBox(height: 9),
      ],
    ],
  );
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card});
  final GiftCardSummary card;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        Container(
          width: 43,
          height: 43,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: card.color,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            card.mark,
            style: TextStyle(
              color: card.markColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.merchant,
                style: const TextStyle(
                  color: _lavender,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.maskedNumber,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .48),
                  fontSize: 11,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              card.balance,
              style: const TextStyle(
                color: _lime,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.updated,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFF1C2A20),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified_user_rounded, color: _lime, size: 23),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'End-to-end encrypted',
              style: TextStyle(
                color: _lavender,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Your card data is stored securely on-device',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: _surface,
      border: Border(top: BorderSide(color: Color(0xFF2C2D32))),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 67,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              route: '/',
              selected: true,
            ),
            _NavItem(
              icon: Icons.credit_card_rounded,
              label: 'Wallet',
              route: '/wallet',
            ),
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/scan'),
              customBorder: const CircleBorder(),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: _lime,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFF1A2017),
                  size: 25,
                ),
              ),
            ),
            _NavItem(
              icon: Icons.grid_view_rounded,
              label: 'Categories',
              route: '/categories',
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              route: '/settings',
            ),
          ],
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final String route;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _lime : Colors.white.withValues(alpha: .4);
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
