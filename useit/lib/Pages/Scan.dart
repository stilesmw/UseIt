import 'package:flutter/material.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  static const Color backgroundColor = Color(0xFF15161A);
  static const Color limeGreen = Color(0xFF8ED84F);
  static const Color lightText = Color(0xFFE9E4FF);
  static const Color mutedText = Color(0xFFAAA7B7);

  bool _cardDetected = false;

  void _simulateCardDetected() {
    setState(() => _cardDetected = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gift card detected!'),
        backgroundColor: Color(0xFF2C4721),
      ),
    );
  }

  void _continueToManualEntry() {
    Navigator.pushNamed(context, '/add-card');
  }

  @override
  Widget build(BuildContext context) {
    final scanColor = _cardDetected ? const Color(0xFFBFA7FF) : limeGreen;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: lightText,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0D0E11),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Scan Gift Card',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 50),
                ],
              ),

              const SizedBox(height: 42),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF22242B),
                        Color(0xFF0B0C0E),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Replace this area later with a real camera preview.
                      Icon(
                        _cardDetected
                            ? Icons.check_circle_rounded
                            : Icons.document_scanner_outlined,
                        color: _cardDetected ? limeGreen : Colors.white12,
                        size: 78,
                      ),

                      _ScannerCorners(color: scanColor),

                      Positioned(
                        bottom: 34,
                        child: Text(
                          _cardDetected
                              ? 'Card detected — ready to add'
                              : 'Point camera at barcode or card number',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  onPressed: _simulateCardDetected,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: lightText,
                    side: const BorderSide(color: Color(0xFF333640)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _cardDetected
                        ? 'Continue with detected card →'
                        : 'Simulate: Card detected →',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextButton(
                onPressed: _continueToManualEntry,
                child: const Text(
                  'Add card manually',
                  style: TextStyle(
                    color: lightText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerCorners extends StatelessWidget {
  const _ScannerCorners({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 330,
      child: Stack(
        children: [
          _corner(alignment: Alignment.topLeft, top: true, left: true),
          _corner(alignment: Alignment.topRight, top: true, left: false),
          _corner(alignment: Alignment.bottomLeft, top: false, left: true),
          _corner(alignment: Alignment.bottomRight, top: false, left: false),
        ],
      ),
    );
  }

  Widget _corner({
    required Alignment alignment,
    required bool top,
    required bool left,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          border: Border(
            top: top ? BorderSide(color: color, width: 4) : BorderSide.none,
            bottom:
                !top ? BorderSide(color: color, width: 4) : BorderSide.none,
            left: left ? BorderSide(color: color, width: 4) : BorderSide.none,
            right:
                !left ? BorderSide(color: color, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(18) : Radius.zero,
            topRight: top && !left ? const Radius.circular(18) : Radius.zero,
            bottomLeft:
                !top && left ? const Radius.circular(18) : Radius.zero,
            bottomRight:
                !top && !left ? const Radius.circular(18) : Radius.zero,
          ),
        ),
      ),
    );
  }
}