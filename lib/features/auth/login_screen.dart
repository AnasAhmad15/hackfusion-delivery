import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/app/widgets/custom_button.dart';
import 'package:pharmaco_delivery_partner/core/services/auth_service.dart';
import 'package:pharmaco_delivery_partner/core/services/fcm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          // Trigger welcome/login notification
          FCMService.sendWelcomeNotification('login');
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.emailVerification, arguments: _emailController.text.trim());
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Theme.of(context).colorScheme.error),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 150, // Increased size
                    width: 150,  // Added width
                    fit: BoxFit.contain, // Added fit
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.local_pharmacy,
                      size: 80,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Welcome, Partner', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Sign in to your account', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
                  const SizedBox(height: 48),
                  if (_verificationMessage != null) ...[
                    _buildEmailVerificationStatus(),
                    const SizedBox(height: 24),
                  ],
                  _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (val) => !val!.contains('@') ? 'Please enter a valid email' : null),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 24),
                  _buildSignInButton(),
                  const SizedBox(height: 16),
                  _buildFooterActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
      ),
      validator: (val) => val!.isEmpty ? 'Please enter your password' : null,
    );
  }

  Widget _buildSignInButton() {
    return CustomButton(
      text: _isLoading ? 'SIGNING IN...' : 'SIGN IN',
      onPressed: (_isFormValid && !_isLoading) ? _signIn : null,
    );
  }

  Widget _buildEmailVerificationStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _verificationMessage ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
          child: const Text('Forgot Password?'),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account?"),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.signUp),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ],
    );
  }
}



