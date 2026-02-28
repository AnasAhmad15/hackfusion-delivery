import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

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
  final List<String> _paymentMethods = ['Cash', 'UPI', 'Card', 'Already Paid Online'];

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (photo != null) setState(() => _imageFile = File(photo.path));
  }

  Future<void> _confirmDelivery() async {
    if (_imageFile == null || _selectedPaymentMethod == null) return;
    if (_selectedPaymentMethod == 'Cash' && !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final double totalAmount = (widget.order['total_amount'] as num?)?.toDouble() ?? 0.0;
      final double amountReceived = _selectedPaymentMethod == 'Cash' ? double.tryParse(_amountController.text) ?? 0.0 : totalAmount;
      final result = await _orderService.completeOrderWithDetails(
        orderId: widget.order['id'], imageFile: _imageFile!, paymentMethod: _selectedPaymentMethod!,
        amountReceived: amountReceived,
        paymentStatus: (_selectedPaymentMethod == 'Already Paid Online' || _selectedPaymentMethod == 'UPI' || _selectedPaymentMethod == 'Card') ? 'paid' : 'paid',
      );
      if (result['success'] == true && mounted) { _showSuccessAnimation(); }
      else if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['message']}'))); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: PharmacoTokens.success, size: 80),
            const SizedBox(height: PharmacoTokens.space16),
            Text('Delivery Completed Successfully', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) { Navigator.of(context).pop(); Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false); }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(title: const Text('Confirm Delivery')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: PharmacoTokens.primaryBase))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(PharmacoTokens.space16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderDetails(order, totalAmount, theme),
                  const SizedBox(height: PharmacoTokens.space24),
                  _buildDeliveryProofSection(theme),
                  const SizedBox(height: PharmacoTokens.space24),
                  _buildPaymentSection(totalAmount, theme),
                  const SizedBox(height: PharmacoTokens.space32),
                  _buildConfirmButton(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> order, double totalAmount, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space16),
      decoration: BoxDecoration(color: PharmacoTokens.white, borderRadius: PharmacoTokens.borderRadiusCard, boxShadow: PharmacoTokens.shadowZ1()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order #${order['id'].toString().substring(0, 8).toUpperCase()}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
          const Divider(),
          _detailRow(Icons.person_outline_rounded, 'Customer', order['customer_name'] ?? 'N/A', theme),
          _detailRow(Icons.location_on_outlined, 'Address', order['delivery_address'] ?? 'N/A', theme),
          _detailRow(Icons.currency_rupee_rounded, 'Total Amount', '₹$totalAmount', theme),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: PharmacoTokens.neutral400),
          const SizedBox(width: PharmacoTokens.space8),
          Expanded(
            child: RichText(
              text: TextSpan(style: theme.textTheme.bodyMedium, children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: PharmacoTokens.weightBold)),
                TextSpan(text: value),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryProofSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery Proof (Mandatory)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: PharmacoTokens.weightBold)),
        const SizedBox(height: PharmacoTokens.space12),
        if (_imageFile == null)
          InkWell(
            onTap: _takePhoto,
            child: Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(color: PharmacoTokens.neutral100, borderRadius: PharmacoTokens.borderRadiusMedium, border: Border.all(color: PharmacoTokens.neutral300)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded, size: 50, color: PharmacoTokens.neutral400),
                  const SizedBox(height: PharmacoTokens.space8),
                  Text('Tap to Take Photo', style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500)),
                ],
              ),
            ),
          )
        else
          Stack(
            children: [
              ClipRRect(borderRadius: PharmacoTokens.borderRadiusMedium, child: Image.file(_imageFile!, height: 250, width: double.infinity, fit: BoxFit.cover)),
              Positioned(top: 8, right: 8, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _takePhoto))),
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentSection(double totalAmount, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: theme.textTheme.titleSmall?.copyWith(fontWeight: PharmacoTokens.weightBold)),
        const SizedBox(height: PharmacoTokens.space12),
        ..._paymentMethods.map((method) => RadioListTile<String>(
          title: Text(method, style: theme.textTheme.bodyMedium),
          value: method, groupValue: _selectedPaymentMethod,
          onChanged: (value) { setState(() { _selectedPaymentMethod = value; if (value != 'Cash') _amountController.clear(); }); },
          contentPadding: EdgeInsets.zero,
        )),
        if (_selectedPaymentMethod == 'Cash')
          Padding(
            padding: const EdgeInsets.only(top: PharmacoTokens.space16),
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount Received', prefixText: '₹ '),
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
    final bool isReady = _imageFile != null && _selectedPaymentMethod != null;
    return ElevatedButton(
      onPressed: isReady ? _confirmDelivery : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        backgroundColor: PharmacoTokens.success,
        foregroundColor: PharmacoTokens.white,
      ),
      child: const Text('CONFIRM DELIVERY', style: TextStyle(fontSize: 16, fontWeight: PharmacoTokens.weightBold)),
    );
  }
}
