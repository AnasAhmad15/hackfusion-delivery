import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/app/widgets/custom_button.dart';
import 'package:pharmaco_delivery_partner/core/services/auth_service.dart';
import 'package:pharmaco_delivery_partner/core/services/fcm_service.dart';

enum PasswordStrength {
  Weak,
  Medium,
  Strong
}

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
    if (_isFormValid != isFormValid) {
      setState(() {
        _isFormValid = isFormValid;
      });
    }
    _checkPasswordStrength();
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      if (password.length < 6) {
        _passwordStrength = PasswordStrength.Weak;
      } else if (password.length < 10) {
        _passwordStrength = PasswordStrength.Medium;
      } else {
        _passwordStrength = PasswordStrength.Strong;
      }
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
        // Trigger welcome notification
        FCMService.sendWelcomeNotification('registration');
        Navigator.pushReplacementNamed(context, AppRoutes.emailVerification, arguments: _emailController.text.trim());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.toString()}'), backgroundColor: Theme.of(context).colorScheme.error),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Image.asset(
                'assets/images/logo.png',
                height: 150, // Increased size
                width: 150,  // Added width
                fit: BoxFit.contain, // Added fit
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person_add_alt_1,
                  size: 80,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text('Create Your Account', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Join our network of delivery partners.', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
              const SizedBox(height: 48),
              _buildTextField(_fullNameController, 'Full Name', Icons.person_outline),
              const SizedBox(height: 24),
              _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (val) => !val!.contains('@') ? 'Please enter a valid email' : null),
              const SizedBox(height: 24),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 48),
              _buildSignUpButton(),
              const SizedBox(height: 16),
              _buildSignInRedirect(),
            ],
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
      obscureText: _obscureText,
      validator: (val) => val!.length < 6 ? 'Password must be at least 6 characters' : null,
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Row(
      children: [
        _buildStrengthBar(PasswordStrength.Weak, 'Weak'),
        const SizedBox(width: 4),
        _buildStrengthBar(PasswordStrength.Medium, 'Medium'),
        const SizedBox(width: 4),
        _buildStrengthBar(PasswordStrength.Strong, 'Strong'),
      ],
    );
  }

  Widget _buildStrengthBar(PasswordStrength level, String label) {
    final isActive = _passwordStrength.index >= level.index;
    Color color;
    switch (level) {
      case PasswordStrength.Weak:
        color = Colors.red;
        break;
      case PasswordStrength.Medium:
        color = Colors.orange;
        break;
      case PasswordStrength.Strong:
        color = Colors.green;
        break;
    }
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? color : Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return CustomButton(
      text: _isLoading ? 'CREATING ACCOUNT...' : 'CREATE ACCOUNT',
      onPressed: (_isFormValid && !_isLoading) ? _signUp : null,
    );
  }

  Widget _buildSignInRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account?'),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Sign In'),
        ),
      ],
    );
  }
}
