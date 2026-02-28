import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/core/services/earnings_service.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

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
  void dispose() { _amountController.dispose(); _upiController.dispose(); _bankAccountController.dispose(); _ifscController.dispose(); super.dispose(); }

  void _handleWithdraw() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid withdrawal amount'), backgroundColor: PharmacoTokens.error));
      return;
    }
    if (_selectedMethod == 'UPI' && _upiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter UPI ID'), backgroundColor: PharmacoTokens.error));
      return;
    }
    setState(() => _isLoading = true);
    final details = _selectedMethod == 'UPI' ? {'upi_id': _upiController.text} : {'account_number': _bankAccountController.text, 'ifsc': _ifscController.text};
    final result = await _earningsService.withdrawEarnings(amount: amount, method: _selectedMethod, details: details);
    setState(() => _isLoading = false);
    if (result['success'] == true) { if (mounted) _showSuccessDialog(amount); }
    else { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Withdrawal failed'), backgroundColor: PharmacoTokens.error)); }
  }

  void _showSuccessDialog(double amount) {
    final theme = Theme.of(context);
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: PharmacoTokens.borderRadiusCard),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: PharmacoTokens.success, size: 80),
            const SizedBox(height: PharmacoTokens.space16),
            Text('Withdrawal Successful!', style: theme.textTheme.titleLarge),
            const SizedBox(height: PharmacoTokens.space8),
            Text('₹$amount has been initiated to your $_selectedMethod.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500)),
            const SizedBox(height: PharmacoTokens.space24),
            ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context, true); }, child: const Text('DONE')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(title: const Text('Withdraw Funds')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: PharmacoTokens.primaryBase))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(PharmacoTokens.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBalanceHeader(theme),
                const SizedBox(height: PharmacoTokens.space32),
                TextFormField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Withdrawal Amount', prefixText: '₹ ', helperText: 'Enter amount to withdraw')),
                const SizedBox(height: PharmacoTokens.space32),
                Text('Select Payout Method', style: theme.textTheme.titleSmall?.copyWith(fontWeight: PharmacoTokens.weightBold)),
                const SizedBox(height: PharmacoTokens.space16),
                _buildMethodSelector(theme),
                const SizedBox(height: PharmacoTokens.space24),
                _buildMethodDetails(),
                const SizedBox(height: PharmacoTokens.space40),
                _buildHelperText(theme),
                const SizedBox(height: PharmacoTokens.space24),
                ElevatedButton(onPressed: _handleWithdraw, child: const Text('CONFIRM WITHDRAWAL')),
              ],
            ),
          ),
    );
  }

  Widget _buildBalanceHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space24),
      decoration: BoxDecoration(color: PharmacoTokens.primarySurface, borderRadius: PharmacoTokens.borderRadiusCard, border: Border.all(color: PharmacoTokens.primaryBase.withValues(alpha: 0.15))),
      child: Column(
        children: [
          Text('Available for Withdrawal', style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500)),
          const SizedBox(height: PharmacoTokens.space8),
          Text('₹${widget.availableBalance.toStringAsFixed(2)}', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.primaryBase)),
        ],
      ),
    );
  }

  Widget _buildMethodSelector(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _MethodCard(label: 'UPI', icon: Icons.flash_on_rounded, badge: 'Instant', isSelected: _selectedMethod == 'UPI', onTap: () => setState(() => _selectedMethod = 'UPI'))),
        const SizedBox(width: PharmacoTokens.space16),
        Expanded(child: _MethodCard(label: 'Bank', icon: Icons.account_balance_rounded, isSelected: _selectedMethod == 'Bank', onTap: () => setState(() => _selectedMethod = 'Bank'))),
      ],
    );
  }

  Widget _buildMethodDetails() {
    if (_selectedMethod == 'UPI') {
      return TextFormField(controller: _upiController, decoration: const InputDecoration(labelText: 'UPI ID', hintText: 'e.g. yourname@okaxis', prefixIcon: Icon(Icons.alternate_email_rounded)));
    } else {
      return Column(
        children: [
          TextFormField(controller: _bankAccountController, decoration: const InputDecoration(labelText: 'Account Number')),
          const SizedBox(height: PharmacoTokens.space16),
          TextFormField(controller: _ifscController, decoration: const InputDecoration(labelText: 'IFSC Code')),
        ],
      );
    }
  }

  Widget _buildHelperText(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space16),
      decoration: BoxDecoration(color: PharmacoTokens.warning.withValues(alpha: 0.08), borderRadius: PharmacoTokens.borderRadiusMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: PharmacoTokens.warning, size: 20),
          const SizedBox(width: PharmacoTokens.space12),
          Expanded(child: Text('Minimum withdrawal: ₹100. UPI withdrawals are processed instantly. Bank transfers may take up to 24 hours.', style: theme.textTheme.bodySmall?.copyWith(color: PharmacoTokens.neutral700))),
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
  const _MethodCard({required this.label, required this.icon, this.badge, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: PharmacoTokens.borderRadiusCard,
      child: Container(
        padding: const EdgeInsets.all(PharmacoTokens.space16),
        decoration: BoxDecoration(
          color: isSelected ? PharmacoTokens.primaryBase : PharmacoTokens.white,
          borderRadius: PharmacoTokens.borderRadiusCard,
          border: Border.all(color: isSelected ? PharmacoTokens.primaryBase : PharmacoTokens.neutral200),
          boxShadow: isSelected ? null : PharmacoTokens.shadowZ1(),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Icon(icon, color: isSelected ? Colors.white : PharmacoTokens.neutral500, size: 32),
                const SizedBox(height: PharmacoTokens.space8),
                Text(label, style: TextStyle(fontWeight: PharmacoTokens.weightBold, color: isSelected ? Colors.white : PharmacoTokens.neutral700)),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -8, right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: isSelected ? PharmacoTokens.white : PharmacoTokens.primaryBase, borderRadius: PharmacoTokens.borderRadiusFull),
                  child: Text(badge!, style: TextStyle(fontSize: 8, fontWeight: PharmacoTokens.weightBold, color: isSelected ? PharmacoTokens.primaryBase : PharmacoTokens.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
