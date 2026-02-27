import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/widgets/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PickupConfirmationScreen extends StatefulWidget {
  const PickupConfirmationScreen({super.key});

  @override
  State<PickupConfirmationScreen> createState() =>
      _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Pickup')),
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
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Capture a pickup proof photo to confirm pickup',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This will mark the order as picked up.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      const SizedBox(height: 40),
                      CustomButton(
                        text: 'CAPTURE PHOTO & CONFIRM',
                        onPressed: _isCapturing
                            ? null
                            : () async {
                                setState(() => _isCapturing = true);
                                try {
                                  final status = await Permission.camera
                                      .request();
                                  if (!status.isGranted) return;

                                  final XFile? photo = await _picker.pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 85,
                                  );
                                  if (photo == null) return;
                                  if (!context.mounted) return;
                                  Navigator.pop(context, true);
                                } finally {
                                  if (mounted) {
                                    setState(() => _isCapturing = false);
                                  }
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
