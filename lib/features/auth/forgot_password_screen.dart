import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/widgets/custom_button.dart';
import 'package:pharmaco_delivery_partner/core/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _sendResetEmail() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent! Please check your inbox.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_reset, size: 80, color: theme.primaryColor),
                const SizedBox(height: 24),
                Text(
                  'Forgot Your Password?',
                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email to receive a reset link.',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildTextField(_emailController, 'Email Address', Icons.email_outlined),
                const SizedBox(height: 32),
                CustomButton(
                  text: _isLoading ? 'SENDING...' : 'SEND RESET LINK',
                  onPressed: _isLoading ? () {} : _sendResetEmail,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }
}
