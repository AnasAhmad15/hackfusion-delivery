import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/services/auth_service.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

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
          const SnackBar(content: Text('Verification email sent!'), backgroundColor: PharmacoTokens.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend email: ${e.toString()}'), backgroundColor: PharmacoTokens.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: const IconThemeData(color: PharmacoTokens.neutral700),
      ),
      body: Padding(
        padding: const EdgeInsets.all(PharmacoTokens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 140, width: 140, fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => CircleAvatar(
                radius: 48,
                backgroundColor: PharmacoTokens.primarySurface,
                child: const Icon(Icons.mark_email_read_outlined, size: 48, color: PharmacoTokens.primaryBase),
              ),
            ),
            const SizedBox(height: PharmacoTokens.space32),
            Text('Verify Your Email', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
            const SizedBox(height: PharmacoTokens.space16),
            Container(
              padding: const EdgeInsets.all(PharmacoTokens.space16),
              decoration: BoxDecoration(
                color: PharmacoTokens.primarySurface,
                borderRadius: PharmacoTokens.borderRadiusMedium,
              ),
              child: Text(
                'We\'ve sent a verification link to ${widget.email}. Please check your inbox and click the link to activate your account.',
                style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.primaryDark),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: PharmacoTokens.space40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resendVerificationEmail,
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('RESEND VERIFICATION EMAIL'),
              ),
            ),
            const SizedBox(height: PharmacoTokens.space16),
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
