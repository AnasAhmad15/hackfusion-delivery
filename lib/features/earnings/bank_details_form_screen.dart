import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/core/services/payout_details_service.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class BankDetailsFormScreen extends StatefulWidget {
  const BankDetailsFormScreen({super.key});

  @override
  State<BankDetailsFormScreen> createState() => _BankDetailsFormScreenState();
}

class _BankDetailsFormScreenState extends State<BankDetailsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _payoutService = PayoutDetailsService();
  
  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  Future<void> _loadExistingDetails() async {
    final details = await _payoutService.getBankDetails();
    if (details != null && mounted) {
      setState(() {
        _nameController.text = details['account_holder_name'] ?? '';
        _accountController.text = details['account_number'] ?? '';
        _ifscController.text = details['ifsc_code'] ?? '';
        _bankNameController.text = details['bank_name'] ?? '';
      });
    }
    setState(() => _isFetching = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final details = await _payoutService.getBankDetails();
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

      await _payoutService.saveBankDetails(
        accountHolderName: _nameController.text.trim(),
        accountNumber: _accountController.text.trim(),
        ifscCode: _ifscController.text.trim().toUpperCase(),
        bankName: _bankNameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank details saved successfully'), backgroundColor: PharmacoTokens.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.contains('24 hours')) {
          message = 'You can only update details once every 24 hours.';
        } else if (message.contains('unique constraint') || message.contains('account_number')) {
          message = 'This account number is already registered.';
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
      appBar: AppBar(title: const Text('Bank Details'), elevation: 0),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: PharmacoTokens.primaryBase))
          : SingleChildScrollView(
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
                            const Icon(Icons.info_outline_rounded, color: PharmacoTokens.primaryBase, size: 20),
                            const SizedBox(width: PharmacoTokens.space12),
                            Expanded(
                              child: Text(
                                'Ensure your bank details are correct to avoid payout delays.',
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
                      _buildFieldLabel('Account Holder Name'),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter name as per bank records',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter name';
                          if (value.trim().length < 3 || value.trim().length > 50) return 'Name must be 3-50 characters';
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return 'Only alphabets and spaces allowed';
                          return null;
                        },
                      ),
                      const SizedBox(height: PharmacoTokens.space24),
                      _buildFieldLabel('Account Number'),
                      TextFormField(
                        controller: _accountController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your account number',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter account number';
                          if (!RegExp(r'^[0-9]{9,18}$').hasMatch(value)) return 'Account number must be 9-18 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: PharmacoTokens.space24),
                      _buildFieldLabel('IFSC Code'),
                      TextFormField(
                        controller: _ifscController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. SBIN0001234',
                          prefixIcon: Icon(Icons.code_rounded),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter IFSC code';
                          if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.toUpperCase())) return 'Invalid IFSC format';
                          return null;
                        },
                      ),
                      const SizedBox(height: PharmacoTokens.space24),
                      _buildFieldLabel('Bank Name'),
                      TextFormField(
                        controller: _bankNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. State Bank of India',
                          prefixIcon: Icon(Icons.account_balance_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter bank name';
                          if (value.trim().length < 3 || value.trim().length > 60) return 'Bank name must be 3-60 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: PharmacoTokens.space48),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveDetails,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('SAVE BANK DETAILS'),
                      ),
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
