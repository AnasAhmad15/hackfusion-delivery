import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final _makeController = TextEditingController(text: 'Honda');
  final _modelController = TextEditingController(text: 'Activa');
  final _regNumberController = TextEditingController(text: 'AP-05-XY-1234');
  bool _isLoading = false;

  Future<void> _saveVehicleDetails() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle details updated successfully!'), backgroundColor: PharmacoTokens.success));
      Navigator.pop(context);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(title: const Text('Vehicle Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(PharmacoTokens.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(radius: 40, backgroundColor: PharmacoTokens.primarySurface, child: const Icon(Icons.motorcycle_rounded, size: 44, color: PharmacoTokens.primaryBase)),
            const SizedBox(height: PharmacoTokens.space24),
            Text('Manage Your Vehicle', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: PharmacoTokens.space32),
            TextField(controller: _makeController, decoration: const InputDecoration(labelText: 'Make (e.g., Honda, TVS)')),
            const SizedBox(height: PharmacoTokens.space16),
            TextField(controller: _modelController, decoration: const InputDecoration(labelText: 'Model (e.g., Activa, Jupiter)')),
            const SizedBox(height: PharmacoTokens.space16),
            TextField(controller: _regNumberController, decoration: const InputDecoration(labelText: 'Registration Number')),
            const SizedBox(height: PharmacoTokens.space32),
            ElevatedButton(onPressed: _isLoading ? null : _saveVehicleDetails, child: Text(_isLoading ? 'SAVING...' : 'SAVE CHANGES')),
          ],
        ),
      ),
    );
  }
}
