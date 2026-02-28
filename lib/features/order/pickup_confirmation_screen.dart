import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class PickupConfirmationScreen extends StatefulWidget {
  const PickupConfirmationScreen({super.key});

  @override
  State<PickupConfirmationScreen> createState() => _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(title: const Text('Confirm Pickup')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight, maxWidth: constraints.maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(PharmacoTokens.space24),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: PharmacoTokens.primarySurface,
                        child: const Icon(Icons.camera_alt_outlined, size: 44, color: PharmacoTokens.primaryBase),
                      ),
                      const SizedBox(height: PharmacoTokens.space24),
                      Text('Capture a pickup proof photo to confirm pickup', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
                      const SizedBox(height: PharmacoTokens.space12),
                      Text('This will mark the order as picked up.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500)),
                      const Spacer(),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('CAPTURE PHOTO & CONFIRM'),
                        onPressed: _isCapturing ? null : () async {
                          setState(() => _isCapturing = true);
                          try {
                            final status = await Permission.camera.request();
                            if (!status.isGranted) return;
                            final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                            if (photo == null) return;
                            if (!context.mounted) return;
                            Navigator.pop(context, true);
                          } finally {
                            if (mounted) setState(() => _isCapturing = false);
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
