import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/app/widgets/custom_button.dart';
import 'package:pharmaco_delivery_partner/core/services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      await _authService.resendVerificationEmail(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend email: ${e.toString()}'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 180, // Increased size
              width: 180,  // Added width
              fit: BoxFit.contain, // Added fit
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.email_outlined,
                size: 100,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text('Verify Your Email', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              'We\'ve sent a verification link to ${widget.email}. Please check your inbox and click the link to activate your account.',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            CustomButton(
              text: _isLoading ? 'SENDING...' : 'RESEND VERIFICATION EMAIL',
              onPressed: _isLoading ? null : _resendVerificationEmail,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false),
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
