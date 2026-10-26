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

  // 2. Add controllers and safety locks
  final MobileScannerController _cameraController = MobileScannerController(
    formats: const [BarcodeFormat.all], 
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _cardDetected = false;
  bool _isProcessingScan = false; 
  String? _scannedBarcodeValue;

  @override
  void dispose() {
    _cameraController.dispose(); // 3. Clean up the camera resources
    super.dispose();
  }

  // 4. Handle actual live camera frame detections
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

  // 5. Action triggered by pressing the confirmation button
  Future<void> _submitScannedCard() async {
    if (_scannedBarcodeValue == null || _isProcessingScan) return;

    setState(() {
      _isProcessingScan = true;
    });

    // Show a loading dialog over the UI
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: limeGreen),
      ),
    );

    try {
      // TODO: Call your Azure Node.js API here:
      // await NetworkService.saveGiftCard(_scannedBarcodeValue!);
      
      await Future.delayed(const Duration(seconds: 2)); // Simulated network call

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading spinner

      // Pop back to wallet/home layout successfully
      Navigator.pop(context); 
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading spinner
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save card. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isProcessingScan = false;
        _cardDetected = false;
        _scannedBarcodeValue = null;
      });
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
              // Header Row
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

              // Scanner Box Container
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

                        // Status Info text banner layout
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

              // Primary Action Confirmation/Simulation Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  onPressed: _cardDetected ? _submitScannedCard : null, // Disabled until a real card registers
                  style: OutlinedButton.styleFrom(
                    foregroundColor: lightText,
                    disabledForegroundColor: mutedText,
                    side: BorderSide(color: _cardDetected ? limeGreen : const Color(0xFF333640)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _cardDetected
                        ? 'Confirm & Save to Wallet →'
                        : 'Awaiting Card Placement...',
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

// Keep your existing _ScannerCorners class code exactly the same down here...
class _ScannerCorners extends StatelessWidget {
  const _ScannerCorners({super.key, required this.color});

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
            bottom: !top ? BorderSide(color: color, width: 4) : BorderSide.none,
            left: left ? BorderSide(color: color, width: 4) : BorderSide.none,
            right: !left ? BorderSide(color: color, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(18) : Radius.zero,
            topRight: top && !left ? const Radius.circular(18) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(18) : Radius.zero,
            bottomRight: !top && !left ? const Radius.circular(18) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
