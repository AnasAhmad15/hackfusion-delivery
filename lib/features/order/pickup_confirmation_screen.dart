import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pinput/pinput.dart';
import 'package:pharmaco_delivery_partner/app/widgets/custom_button.dart';

class PickupConfirmationScreen extends StatefulWidget {
  const PickupConfirmationScreen({super.key});

  @override
  State<PickupConfirmationScreen> createState() => _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  bool _isManualEntry = false;
  final TextEditingController _pinController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _pinController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleConfirmation(String code) {
    if (code.isNotEmpty) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Pickup'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: constraints.maxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_isManualEntry) ...[
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  _handleConfirmation(barcode.rawValue!);
                                  break;
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Scan QR code from pharmacy to confirm pickup',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: () => setState(() => _isManualEntry = true),
                          icon: const Icon(Icons.keyboard_outlined),
                          label: const Text('ENTER OTP MANUALLY'),
                        ),
                      ] else ...[
                        const SizedBox(height: 40),
                        const Icon(Icons.pin_outlined, size: 80, color: Colors.blue),
                        const SizedBox(height: 24),
                        const Text(
                          'Enter 4-digit OTP provided by the pharmacist',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Pinput(
                            length: 4,
                            controller: _pinController,
                            defaultPinTheme: PinTheme(
                              width: 56,
                              height: 56,
                              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onCompleted: (pin) => _handleConfirmation(pin),
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextButton.icon(
                          onPressed: () => setState(() => _isManualEntry = false),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('SWITCH TO SCANNER'),
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: 40),
                      CustomButton(
                        text: 'CONFIRM PICKUP',
                        onPressed: () {
                          if (_isManualEntry) {
                            _handleConfirmation(_pinController.text);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
