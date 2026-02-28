import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/core/services/auth_service.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

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
    setState(() => _isLoading = true);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(
        backgroundColor: PharmacoTokens.white, elevation: 0,
        scrolledUnderElevation: PharmacoTokens.elevationZ1,
        surfaceTintColor: Colors.transparent,
        title: Text('Reset Password', style: theme.textTheme.headlineMedium),
        iconTheme: const IconThemeData(color: PharmacoTokens.neutral700),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(PharmacoTokens.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: PharmacoTokens.primarySurface,
                  child: const Icon(Icons.lock_reset_rounded, size: 44, color: PharmacoTokens.primaryBase),
                ),
                const SizedBox(height: PharmacoTokens.space24),
                Text('Forgot Your Password?', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
                const SizedBox(height: PharmacoTokens.space8),
                Text('Enter your email to receive a reset link.', style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500), textAlign: TextAlign.center),
                const SizedBox(height: PharmacoTokens.space40),

                Container(
                  padding: const EdgeInsets.all(PharmacoTokens.space24),
                  decoration: BoxDecoration(
                    color: PharmacoTokens.white,
                    borderRadius: PharmacoTokens.borderRadiusCard,
                    boxShadow: PharmacoTokens.shadowZ1(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email Address', style: theme.textTheme.bodySmall?.copyWith(fontWeight: PharmacoTokens.weightSemiBold, color: PharmacoTokens.neutral700)),
                      const SizedBox(height: PharmacoTokens.space8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined, color: PharmacoTokens.primaryBase, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: PharmacoTokens.space32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetEmail,
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('SEND RESET LINK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
