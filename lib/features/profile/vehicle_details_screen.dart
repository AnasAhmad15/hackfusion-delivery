import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/widgets/custom_button.dart';

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
    setState(() {
      _isLoading = true;
    });
    // Placeholder for saving data
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle details updated successfully!')),
      );
      Navigator.pop(context);
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.motorcycle, size: 80, color: theme.primaryColor),
            const SizedBox(height: 24),
            Text(
              'Manage Your Vehicle',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildTextField(_makeController, 'Make (e.g., Honda, TVS)'),
            const SizedBox(height: 16),
            _buildTextField(_modelController, 'Model (e.g., Activa, Jupiter)'),
            const SizedBox(height: 16),
            _buildTextField(_regNumberController, 'Registration Number'),
            const SizedBox(height: 32),
            CustomButton(
              text: _isLoading ? 'SAVING...' : 'SAVE CHANGES',
              onPressed: _isLoading ? () {} : _saveVehicleDetails,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }
}
