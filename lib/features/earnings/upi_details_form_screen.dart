import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/core/services/payout_details_service.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class UPIDetailsFormScreen extends StatefulWidget {
  const UPIDetailsFormScreen({super.key});

  @override
  State<UPIDetailsFormScreen> createState() => _UPIDetailsFormScreenState();
}

class _UPIDetailsFormScreenState extends State<UPIDetailsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _payoutService = PayoutDetailsService();
  final _upiController = TextEditingController();
  
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  Future<void> _loadExistingDetails() async {
    final details = await _payoutService.getUPIDetails();
    if (details != null && mounted) {
      setState(() {
        _upiController.text = details['upi_id'] ?? '';
      });
    }
    setState(() => _isFetching = false);
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final details = await _payoutService.getUPIDetails();
      if (details != null) {
        final updatedAt = DateTime.tryParse(details['updated_at'] ?? '');
        if (updatedAt != null && DateTime.now().difference(updatedAt).inHours < 24) {
          final remaining = 24 - DateTime.now().difference(updatedAt).inHours;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Updates allowed once every 24 hours. Please wait $remaining more hours.'),
                backgroundColor: PharmacoTokens.warning,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      await _payoutService.saveUPIDetails(_upiController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UPI ID saved successfully'), backgroundColor: PharmacoTokens.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.contains('24 hours')) {
          message = 'You can only update details once every 24 hours.';
        } else if (message.contains('unique constraint') || message.contains('upi_id')) {
          message = 'This UPI ID is already registered.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: PharmacoTokens.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: PharmacoTokens.primaryBase)));
    }

    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(title: const Text('UPI Details'), elevation: 0),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: PharmacoTokens.primaryBase))
          : Padding(
              padding: const EdgeInsets.all(PharmacoTokens.space24),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(PharmacoTokens.space16),
                        decoration: BoxDecoration(
                          color: PharmacoTokens.primaryBase.withOpacity(0.05),
                          borderRadius: PharmacoTokens.borderRadiusMedium,
                          border: Border.all(color: PharmacoTokens.primaryBase.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: PharmacoTokens.primaryBase, size: 20),
                            const SizedBox(width: PharmacoTokens.space12),
                            Expanded(
                              child: Text(
                                'UPI payouts are processed instantly to your linked ID.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: PharmacoTokens.primaryDark,
                                      fontWeight: PharmacoTokens.weightMedium,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: PharmacoTokens.space32),
                      
                      _buildFieldLabel('UPI ID'),
                      TextFormField(
                        controller: _upiController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. username@okaxis',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter UPI ID';
                          final trimmedValue = value.trim();
                          if (trimmedValue.length < 5 || trimmedValue.length > 50) return 'UPI ID must be 5-50 characters';
                          if (!RegExp(r'^[a-zA-Z0-9.\-_]{2,25}@[a-zA-Z]{2,25}$').hasMatch(trimmedValue)) {
                            return 'Invalid UPI ID format (e.g. username@bank)';
                          }
                          return null;
                        },
                      ),
                      
                      const Spacer(),
                      
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveDetails,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SAVE UPI DETAILS'),
                      ),
                      const SizedBox(height: PharmacoTokens.space20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: PharmacoTokens.weightBold,
          color: PharmacoTokens.neutral500,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
