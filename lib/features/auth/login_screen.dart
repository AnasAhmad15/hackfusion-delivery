import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';
import 'package:pharmaco_delivery_partner/core/services/auth_service.dart';
import 'package:pharmaco_delivery_partner/core/services/fcm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isFormValid = false;
  bool _obscureText = true;
  String? _verificationMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final message = ModalRoute.of(context)?.settings.arguments as String?;
      if (message != null) {
        setState(() {
          _verificationMessage = message;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (_isFormValid != isFormValid) {
      setState(() {
        _isFormValid = isFormValid;
      });
    }
  }

  Future<void> _signIn() async {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        if (user?.emailConfirmedAt != null) {
          FCMService.sendWelcomeNotification('login');
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.emailVerification, arguments: _emailController.text.trim());
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: PharmacoTokens.error),
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
    final lp = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(PharmacoTokens.space24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120, width: 120, fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => CircleAvatar(
                      radius: 44,
                      backgroundColor: PharmacoTokens.primarySurface,
                      child: const Icon(Icons.local_shipping_rounded, size: 44, color: PharmacoTokens.primaryBase),
                    ),
                  ),
                  const SizedBox(height: PharmacoTokens.space24),
                  Text(lp.translate('welcome_partner'),
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: PharmacoTokens.space8),
                  Text(lp.translate('sign_in_to_continue'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: PharmacoTokens.space40),

                  if (_verificationMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(PharmacoTokens.space12),
                      decoration: BoxDecoration(
                        color: PharmacoTokens.primarySurface,
                        borderRadius: PharmacoTokens.borderRadiusMedium,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: PharmacoTokens.primaryBase),
                          const SizedBox(width: PharmacoTokens.space12),
                          Expanded(child: Text(_verificationMessage!, style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.primaryDark))),
                        ],
                      ),
                    ),
                    const SizedBox(height: PharmacoTokens.space24),
                  ],

                  // White form card
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
                        Text(lp.translate('email_address'), style: theme.textTheme.bodySmall?.copyWith(fontWeight: PharmacoTokens.weightSemiBold, color: PharmacoTokens.neutral700)),
                        const SizedBox(height: PharmacoTokens.space8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: lp.translate('email_address'),
                            prefixIcon: const Icon(Icons.email_outlined, color: PharmacoTokens.primaryBase, size: 20),
                          ),
                          validator: (val) => !val!.contains('@') ? lp.translate('invalid_email') : null,
                        ),
                        const SizedBox(height: PharmacoTokens.space20),
                        Text(lp.translate('password'), style: theme.textTheme.bodySmall?.copyWith(fontWeight: PharmacoTokens.weightSemiBold, color: PharmacoTokens.neutral700)),
                        const SizedBox(height: PharmacoTokens.space8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            hintText: lp.translate('password'),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: PharmacoTokens.primaryBase, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: PharmacoTokens.neutral400, size: 20),
                              onPressed: () => setState(() => _obscureText = !_obscureText),
                            ),
                          ),
                          validator: (val) => val!.isEmpty ? lp.translate('enter_password') : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PharmacoTokens.space24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isFormValid && !_isLoading) ? _signIn : null,
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(lp.translate('sign_in')),
                    ),
                  ),
                  const SizedBox(height: PharmacoTokens.space16),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                    child: Text(lp.translate('forgot_password')),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(lp.translate('dont_have_account'), style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.signUp),
                        child: Text(lp.translate('sign_up')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
