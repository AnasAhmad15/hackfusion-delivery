import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/widgets/custom_button.dart';
import 'package:pharmaco_delivery_partner/core/services/earnings_service.dart';

class WithdrawFundsScreen extends StatefulWidget {
  final double availableBalance;
  const WithdrawFundsScreen({super.key, required this.availableBalance});

  @override
  State<WithdrawFundsScreen> createState() => _WithdrawFundsScreenState();
}

class _WithdrawFundsScreenState extends State<WithdrawFundsScreen> {
  final _earningsService = EarningsService();
  final _amountController = TextEditingController();
  final _upiController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  
  String _selectedMethod = 'UPI';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  void _handleWithdraw() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid withdrawal amount'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedMethod == 'UPI' && _upiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter UPI ID'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final details = _selectedMethod == 'UPI' 
      ? {'upi_id': _upiController.text}
      : {'account_number': _bankAccountController.text, 'ifsc': _ifscController.text};

    final result = await _earningsService.withdrawEarnings(
      amount: amount,
      method: _selectedMethod,
      details: details,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        _showSuccessDialog(amount);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Withdrawal failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Withdrawal Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '₹$amount has been initiated to your $_selectedMethod.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'DONE',
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Go back to earnings screen
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw Funds')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBalanceHeader(theme),
                const SizedBox(height: 32),
                _buildAmountInput(),
                const SizedBox(height: 32),
                const Text('Select Payout Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _buildMethodSelector(theme),
                const SizedBox(height: 24),
                _buildMethodDetails(),
                const SizedBox(height: 40),
                _buildHelperText(),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'CONFIRM WITHDRAWAL',
                  onPressed: _handleWithdraw,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildBalanceHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text('Available for Withdrawal', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            '₹${widget.availableBalance.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Withdrawal Amount',
        prefixText: '₹ ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperText: 'Enter amount to withdraw',
      ),
    );
  }

  Widget _buildMethodSelector(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _MethodCard(
            label: 'UPI',
            icon: Icons.flash_on,
            badge: 'Instant',
            isSelected: _selectedMethod == 'UPI',
            onTap: () => setState(() => _selectedMethod = 'UPI'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MethodCard(
            label: 'Bank',
            icon: Icons.account_balance,
            isSelected: _selectedMethod == 'Bank',
            onTap: () => setState(() => _selectedMethod = 'Bank'),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodDetails() {
    if (_selectedMethod == 'UPI') {
      return TextFormField(
        controller: _upiController,
        decoration: InputDecoration(
          labelText: 'UPI ID',
          hintText: 'e.g. yourname@okaxis',
          prefixIcon: const Icon(Icons.alternate_email),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      return Column(
        children: [
          TextFormField(
            controller: _bankAccountController,
            decoration: InputDecoration(
              labelText: 'Account Number',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ifscController,
            decoration: InputDecoration(
              labelText: 'IFSC Code',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildHelperText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Minimum withdrawal: ₹100. UPI withdrawals are processed instantly. Bank transfers may take up to 24 hours.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.label,
    required this.icon,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? theme.primaryColor : Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : theme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.primaryColor : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
