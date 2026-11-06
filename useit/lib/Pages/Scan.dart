import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  final MobileScannerController _cameraController = MobileScannerController(
    formats: const [BarcodeFormat.all], 
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _cardDetected = false;
  bool _isProcessingScan = false; 
  String? _scannedBarcodeValue;

  @override
  void dispose() {
    _cameraController.dispose(); 
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessingScan || _cardDetected) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? barcodeValue = barcodes.first.rawValue;

      if (barcodeValue != null) {
        setState(() {
          _cardDetected = true;
          _scannedBarcodeValue = barcodeValue;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gift card detected!'),
            backgroundColor: Color(0xFF2C4721),
          ),
        );
      }
    }
  }

  void _submitScannedCard() async {
    final barcode = _scannedBarcodeValue;
    if (barcode == null || _isProcessingScan) return;

    // Shut off camera resources before popping to prevent background memory leaks
    await _cameraController.stop();

    if (mounted) {
      Navigator.of(context).pop(barcode);
    }
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
                  IconButton(
                    onPressed: () => _cameraController.toggleTorch(),
                    icon: const Icon(Icons.flash_on_rounded),
                    color: lightText,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0D0E11),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                    ),
                  ),
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
                      colors: [Color(0xFF22242B), Color(0xFF0B0C0E)],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28), 
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!_cardDetected)
                          MobileScanner(
                            controller: _cameraController,
                            onDetect: _onBarcodeDetected,
                          )
                        else
                          const Icon(
                            Icons.check_circle_rounded,
                            color: limeGreen,
                            size: 78,
                          ),
                        if (!_cardDetected)
                          Positioned.fill(
                            child: Container(color: Colors.black26),
                          ),
                        _ScannerCorners(color: scanColor),
                        Positioned(
                          bottom: 34,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  onPressed: _cardDetected ? _submitScannedCard : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: lightText,
                    disabledForegroundColor: mutedText,
                    side: BorderSide(color: _cardDetected ? limeGreen : const Color(0xFF333640)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    _cardDetected ? 'Review in Wallet →' : 'Awaiting Card Placement...',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _continueToManualEntry,
                child: const Text(
                  'Add card manually',
                  style: TextStyle(color: lightText, fontSize: 16, fontWeight: FontWeight.w700),
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
  final Color color;
  const _ScannerCorners({required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _CornerPainter(color: color),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double len = 24;

    // Top Left
    canvas.drawLine(Offset.zero, Offset(0, len), paint);
    canvas.drawLine(Offset.zero, Offset(len, 0), paint);

    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

