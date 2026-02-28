import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';

class ConfirmDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const ConfirmDeliveryScreen({super.key, required this.order});

  @override
  State<ConfirmDeliveryScreen> createState() => _ConfirmDeliveryScreenState();
}

class _ConfirmDeliveryScreenState extends State<ConfirmDeliveryScreen> {
  final OrderService _orderService = OrderService();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _selectedPaymentMethod;
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final List<String> _paymentMethods = [
    'Cash',
    'UPI',
    'Card',
    'Already Paid Online'
  ];

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  Future<Map<String, dynamic>> _confirmDelivery() async {
    setState(() => _isLoading = true);

    try {
      // Demo mode: skip all validations and just update status
      final result = await _orderService.completeOrderWithDetails(
        orderId: widget.order['id'],
        paymentMethod: _selectedPaymentMethod ?? 'Cash',
      );

      if (result['success'] == true && mounted) {
        _showSuccessAnimation();
        return result;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['message']}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    return {'success': false};
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Delivery Completed Successfully',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(); // Pop dialog
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final order = widget.order;
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Delivery'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderDetails(order, totalAmount),
                  const SizedBox(height: 24),
                  _buildDeliveryProofSection(),
                  const SizedBox(height: 24),
                  _buildPaymentSection(totalAmount),
                  const SizedBox(height: 32),
                  _buildConfirmButton(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> order, double totalAmount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order['id'].toString().substring(0, 8).toUpperCase()}', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            _detailRow(Icons.person, 'Customer', order['customer_name'] ?? 'N/A'),
            _detailRow(Icons.location_on, 'Address', order['delivery_address'] ?? 'N/A'),
            _detailRow(Icons.currency_rupee, 'Total Amount', '₹$totalAmount'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 14),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Delivery Proof (Mandatory)', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        if (_imageFile == null)
          InkWell(
            onTap: _takePhoto,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Tap to Take Photo', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, height: 250, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _takePhoto,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentSection(double totalAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ..._paymentMethods.map((method) => RadioListTile<String>(
          title: Text(method),
          value: method,
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value;
              if (value != 'Cash') _amountController.clear();
            });
          },
          contentPadding: EdgeInsets.zero,
        )),
        if (_selectedPaymentMethod == 'Cash')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount Received',
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter amount';
                final amount = double.tryParse(value);
                if (amount == null) return 'Invalid amount';
                if (amount != totalAmount) return 'Amount must match ₹$totalAmount';
                return null;
              },
            ),
          ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _confirmDelivery,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
        'CONFIRM DELIVERY',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
