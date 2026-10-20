import 'package:flutter/material.dart';

const _background = Color(0xFF141518);
const _surface = Color(0xFF202126);
const _lime = Color(0xFF8FD14F);
const _lavender = Color(0xFFE4DFFF);
const _mutedText = Color(0xFFAAA7B7);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.user});

  final Map<String, dynamic>? user;

  @override
  Widget build(BuildContext context) {
    return WalletHome(user: user);
  }
}

class WalletHome extends StatelessWidget {
  const WalletHome({super.key, this.user});

  final Map<String, dynamic>? user;

  String get userName {
    final name = user?['name']?.toString().trim();

    if (name != null && name.isNotEmpty) return name;

    final email = user?['email']?.toString() ?? '';
    return email.isNotEmpty ? email.split('@').first : 'there';
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, $userName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your Wallet',
                style: TextStyle(color: _mutedText, fontSize: 16),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scan Card',
                      onTap: () => Navigator.pushNamed(context, '/scan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.add_rounded,
                      label: 'Add Manual',
                      onTap: () => _comingSoon(context, 'Manual card entry'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.grid_view_rounded,
                      label: 'Categories',
                      onTap: () => _comingSoon(context, 'Categories'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Recent Cards',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              const _GiftCardTile(
                brand: 'Starbucks',
                amount: '\$18.50',
                icon: Icons.coffee_rounded,
                color: Color(0xFF0B6B52),
              ),
              const SizedBox(height: 12),
              const _GiftCardTile(
                brand: 'Target',
                amount: '\$25.00',
                icon: Icons.shopping_bag_rounded,
                color: Color(0xFFA92330),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: _lime),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your data is protected',
                            style: TextStyle(
                              color: _lavender,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Your card data is securely protected.',
                            style: TextStyle(
                              color: _mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavigation(
        onHomeTap: () {},
        onScanTap: () => Navigator.pushNamed(context, '/scan'),
        onOtherTap: () => _comingSoon(context, 'That page'),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: _lime, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _lavender,
                  fontSize: 12,
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

class _GiftCardTile extends StatelessWidget {
  const _GiftCardTile({
    required this.brand,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String brand;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              brand,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: _lime,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.onHomeTap,
    required this.onScanTap,
    required this.onOtherTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onScanTap;
  final VoidCallback onOtherTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1B1C21),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: true,
            onTap: onHomeTap,
          ),
          _NavButton(
            icon: Icons.wallet_rounded,
            label: 'Wallet',
            onTap: onOtherTap,
          ),
          GestureDetector(
            onTap: onScanTap,
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: _lime,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.black,
                size: 29,
              ),
            ),
          ),
          _NavButton(
            icon: Icons.grid_view_rounded,
            label: 'Categories',
            onTap: onOtherTap,
          ),
          _NavButton(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: onOtherTap,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _lime : _mutedText;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}