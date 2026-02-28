import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/services/auth_service.dart';
import 'package:pharmaco_delivery_partner/core/services/fcm_service.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

enum PasswordStrength { Weak, Medium, Strong }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isFormValid = false;
  bool _obscureText = true;
  PasswordStrength _passwordStrength = PasswordStrength.Weak;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_validateForm);
    _emailController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (_isFormValid != isFormValid) setState(() => _isFormValid = isFormValid);
    _checkPasswordStrength();
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      if (password.length < 6) { _passwordStrength = PasswordStrength.Weak; }
      else if (password.length < 10) { _passwordStrength = PasswordStrength.Medium; }
      else { _passwordStrength = PasswordStrength.Strong; }
    });
  }

  Future<void> _signUp() async {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );
      if (mounted) {
        FCMService.sendWelcomeNotification('registration');
        Navigator.pushReplacementNamed(context, AppRoutes.emailVerification, arguments: _emailController.text.trim());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.toString()}'), backgroundColor: PharmacoTokens.error),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: PharmacoTokens.space24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: PharmacoTokens.space16),
              Image.asset(
                'assets/images/logo.png',
                height: 100, width: 100, fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => CircleAvatar(
                  radius: 40,
                  backgroundColor: PharmacoTokens.primarySurface,
                  child: const Icon(Icons.person_add_alt_1_rounded, size: 40, color: PharmacoTokens.primaryBase),
                ),
              ),
              const SizedBox(height: PharmacoTokens.space16),
              Text('Create Your Account', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: PharmacoTokens.space8),
              Text('Join our network of delivery partners.', style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500), textAlign: TextAlign.center),
              const SizedBox(height: PharmacoTokens.space32),

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
                    _buildLabel(theme, 'Full Name'),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: PharmacoTokens.primaryBase, size: 20),
                      ),
                    ),
                    const SizedBox(height: PharmacoTokens.space20),
                    _buildLabel(theme, 'Email Address'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined, color: PharmacoTokens.primaryBase, size: 20),
                      ),
                      validator: (val) => !val!.contains('@') ? 'Please enter a valid email' : null,
                    ),
                    const SizedBox(height: PharmacoTokens.space20),
                    _buildLabel(theme, 'Password'),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        hintText: 'Create a password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: PharmacoTokens.primaryBase, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: PharmacoTokens.neutral400, size: 20),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                      validator: (val) => val!.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: PharmacoTokens.space12),
                    _buildPasswordStrengthIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: PharmacoTokens.space32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isFormValid && !_isLoading) ? _signUp : null,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('CREATE ACCOUNT'),
                ),
              ),
              const SizedBox(height: PharmacoTokens.space16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?', style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500)),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sign In')),
                ],
              ),
              const SizedBox(height: PharmacoTokens.space24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PharmacoTokens.space8),
      child: Text(text, style: theme.textTheme.bodySmall?.copyWith(fontWeight: PharmacoTokens.weightSemiBold, color: PharmacoTokens.neutral700)),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Row(
      children: [
        _buildStrengthBar(PasswordStrength.Weak),
        const SizedBox(width: 4),
        _buildStrengthBar(PasswordStrength.Medium),
        const SizedBox(width: 4),
        _buildStrengthBar(PasswordStrength.Strong),
      ],
    );
  }

  Widget _buildStrengthBar(PasswordStrength level) {
    final isActive = _passwordStrength.index >= level.index;
    Color color;
    switch (level) {
      case PasswordStrength.Weak: color = PharmacoTokens.error; break;
      case PasswordStrength.Medium: color = PharmacoTokens.warning; break;
      case PasswordStrength.Strong: color = PharmacoTokens.success; break;
    }
    return Expanded(
      child: AnimatedContainer(
        duration: PharmacoTokens.durationMedium,
        height: 6,
        decoration: BoxDecoration(
          color: isActive ? color : PharmacoTokens.neutral200,
          borderRadius: PharmacoTokens.borderRadiusFull,
        ),
      ),
    );
  }
}
