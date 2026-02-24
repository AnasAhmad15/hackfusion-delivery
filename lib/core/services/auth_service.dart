import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;

  User? get currentUser => _auth.currentUser;

  Future<User?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final AuthResponse res = await _auth.signUp(
      email: email,
      password: password,
    );

    if (res.user != null) {
      await Supabase.instance.client.from('profiles').insert({
        'id': res.user!.id,
        'full_name': fullName,
      });
    }
    return res.user;
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final AuthResponse res = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resendVerificationEmail(String email) async {
    await _auth.resend(type: OtpType.signup, email: email);
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    // 1. Verify current session
    final session = _auth.currentSession;
    if (session == null) {
      throw AuthException('User not authenticated');
    }

    // 2. Re-authenticate to verify current password (security best practice)
    try {
      await _auth.signInWithPassword(
        email: session.user.email!,
        password: currentPassword,
      );
    } catch (e) {
      throw AuthException('Incorrect current password');
    }

    // 3. Update to new password
    await _auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}