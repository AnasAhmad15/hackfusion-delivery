import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/core/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() { _currentPasswordController.dispose(); _newPasswordController.dispose(); _confirmPasswordController.dispose(); super.dispose(); }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.updatePassword(_currentPasswordController.text, _newPasswordController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully'), backgroundColor: PharmacoTokens.success));
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: PharmacoTokens.error));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An unexpected error occurred'), backgroundColor: PharmacoTokens.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(title: const Text('Account Security')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(PharmacoTokens.space24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CircleAvatar(radius: 40, backgroundColor: PharmacoTokens.primarySurface, child: const Icon(Icons.lock_outline_rounded, size: 44, color: PharmacoTokens.primaryBase)),
              const SizedBox(height: PharmacoTokens.space24),
              Text('Change Your Password', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: PharmacoTokens.space32),
              TextFormField(
                controller: _currentPasswordController, obscureText: _obscureCurrent,
                decoration: InputDecoration(labelText: 'Current Password', prefixIcon: const Icon(Icons.lock_open_rounded),
                  suffixIcon: IconButton(icon: Icon(_obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent))),
                validator: (val) => (val == null || val.isEmpty) ? 'Enter current password' : null,
              ),
              const SizedBox(height: PharmacoTokens.space16),
              TextFormField(
                controller: _newPasswordController, obscureText: _obscureNew,
                decoration: InputDecoration(labelText: 'New Password', prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: IconButton(icon: Icon(_obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _obscureNew = !_obscureNew))),
                validator: (val) { if (val == null || val.isEmpty) return 'Enter new password'; if (val.length < 6) return 'Password must be at least 6 characters'; return null; },
              ),
              const SizedBox(height: PharmacoTokens.space16),
              TextFormField(
                controller: _confirmPasswordController, obscureText: _obscureConfirm,
                decoration: InputDecoration(labelText: 'Confirm New Password', prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                  suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
                validator: (val) { if (val != _newPasswordController.text) return 'Passwords do not match'; return null; },
              ),
              const SizedBox(height: PharmacoTokens.space32),
              ElevatedButton(onPressed: _isLoading ? null : _updatePassword, child: Text(_isLoading ? 'UPDATING...' : 'UPDATE PASSWORD')),
            ],
          ),
        ),
      ),
    );
  }
}
