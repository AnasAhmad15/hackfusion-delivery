import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/core/services/profile_service.dart';
import 'package:pharmaco_delivery_partner/core/services/auth_service.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/models/onboarding_profile.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _fetchProfile(); }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    try {
      final data = await _profileService.getProfile();
      if (mounted) setState(() { _profileData = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return StreamBuilder<Map<String, dynamic>>(
      stream: _profileService.getProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _profileData == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: PharmacoTokens.primaryBase)));
        }
        final profileData = snapshot.hasData ? snapshot.data! : _profileData ?? {};

        return Scaffold(
          backgroundColor: PharmacoTokens.neutral50,
          body: RefreshIndicator(
            color: PharmacoTokens.primaryBase,
            onRefresh: _fetchProfile,
            child: ListView(
              padding: const EdgeInsets.all(PharmacoTokens.space20),
              children: [
                _buildProfileHeader(theme, profileData),
                const SizedBox(height: PharmacoTokens.space24),
                _buildPersonalInfoCard(theme, profileData, languageProvider),
                const SizedBox(height: PharmacoTokens.space24),
                _buildSectionGroup(theme, 'ACCOUNT', [
                  _buildMenuTile(theme, Icons.description_outlined, 'Documents & Verification', () => Navigator.pushNamed(context, AppRoutes.documentsVerification)),
                  _buildMenuTile(theme, Icons.security_outlined, 'Security & Login', () => Navigator.pushNamed(context, AppRoutes.security)),
                  _buildMenuTile(theme, Icons.language_rounded, languageProvider.translate('change_language'), () => _showLanguageDialog(context, languageProvider)),
                ]),
                const SizedBox(height: PharmacoTokens.space24),
                _buildSectionGroup(theme, 'WORK', [
                  _buildMenuTile(theme, Icons.directions_car_outlined, 'Vehicle Details', () => Navigator.pushNamed(context, AppRoutes.editVehicleDetails, arguments: _createProfileForEditing(profileData))),
                  _buildMenuTile(theme, Icons.map_outlined, 'Service Area', () => Navigator.pushNamed(context, AppRoutes.editDeliveryArea, arguments: _createProfileForEditing(profileData))),
                  _buildMenuTile(theme, Icons.access_time_rounded, 'Availability Preferences', () {}),
                ]),
                const SizedBox(height: PharmacoTokens.space24),
                _buildSectionGroup(theme, 'SUPPORT', [
                  _buildMenuTile(theme, Icons.help_outline_rounded, 'Help Center & FAQ', () => Navigator.pushNamed(context, AppRoutes.helpAndSupport)),
                  _buildMenuTile(theme, Icons.headset_mic_outlined, 'Contact Support', () {}),
                  _buildMenuTile(theme, Icons.info_outline_rounded, 'Terms & Privacy', () {}),
                ]),
                const SizedBox(height: PharmacoTokens.space40),
                _buildLogoutButton(theme, languageProvider),
                const SizedBox(height: PharmacoTokens.space20),
                Center(child: Text('Version 1.0.2 (Production)', style: theme.textTheme.labelSmall?.copyWith(color: PharmacoTokens.neutral400))),
                const SizedBox(height: PharmacoTokens.space20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.translate('select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: provider.currentLocale.languageCode == 'en' ? const Icon(Icons.check_rounded, color: PharmacoTokens.primaryBase) : null,
              onTap: () { provider.setLanguage('en'); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text('हिंदी (Hindi)'),
              trailing: provider.currentLocale.languageCode == 'hi' ? const Icon(Icons.check_rounded, color: PharmacoTokens.primaryBase) : null,
              onTap: () { provider.setLanguage('hi'); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text('मराठी (Marathi)'),
              trailing: provider.currentLocale.languageCode == 'mr' ? const Icon(Icons.check_rounded, color: PharmacoTokens.primaryBase) : null,
              onTap: () { provider.setLanguage('mr'); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, Map<String, dynamic> profileData) {
    final String photoUrl = profileData['profile_photo_url'] as String? ?? '';
    final bool isVerified = profileData['profile_completed'] ?? false;

    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space20),
      decoration: BoxDecoration(
        color: PharmacoTokens.white,
        borderRadius: PharmacoTokens.borderRadiusCard,
        boxShadow: PharmacoTokens.shadowZ1(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: PharmacoTokens.primaryBase, width: 2)),
            child: CircleAvatar(
              radius: 40,
              key: ValueKey(photoUrl),
              backgroundColor: PharmacoTokens.primarySurface,
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              onBackgroundImageError: photoUrl.isNotEmpty ? (e, s) => debugPrint('ProfileScreen: Image load error: $e') : null,
              child: photoUrl.isEmpty ? const Icon(Icons.person_rounded, size: 40, color: PharmacoTokens.primaryBase) : null,
            ),
          ),
          const SizedBox(width: PharmacoTokens.space20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(profileData['full_name'] as String? ?? 'Delivery Partner', style: theme.textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(_authService.currentUser?.email ?? '', style: theme.textTheme.bodySmall?.copyWith(color: PharmacoTokens.neutral500), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: PharmacoTokens.space8),
                _buildVerificationBadge(isVerified),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(ThemeData theme, Map<String, dynamic> profileData, LanguageProvider lp) {
    final int? age = profileData['date_of_birth'] != null ? _calculateAge(DateTime.parse(profileData['date_of_birth'])) : null;

    return Container(
      decoration: BoxDecoration(
        color: PharmacoTokens.white,
        borderRadius: PharmacoTokens.borderRadiusCard,
        boxShadow: PharmacoTokens.shadowZ1(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(PharmacoTokens.space20, PharmacoTokens.space16, PharmacoTokens.space12, PharmacoTokens.space8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PERSONAL INFORMATION', style: theme.textTheme.labelSmall?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.neutral400, letterSpacing: 1.1)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: PharmacoTokens.primaryBase),
                  onPressed: () => _onEditProfile(profileData),
                  tooltip: 'Edit Profile',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildInfoRow(theme, Icons.person_outline_rounded, 'Full Name', profileData['full_name'] ?? 'N/A'),
          _buildInfoRow(theme, Icons.phone_outlined, 'Phone Number', profileData['phone'] ?? 'N/A'),
          _buildInfoRow(theme, Icons.calendar_today_outlined, 'Age', age?.toString() ?? 'N/A'),
          _buildInfoRow(theme, Icons.email_outlined, 'Email Address', profileData['email'] ?? _authService.currentUser?.email ?? 'N/A'),
          const SizedBox(height: PharmacoTokens.space12),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PharmacoTokens.space20, vertical: PharmacoTokens.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: PharmacoTokens.neutral400),
          const SizedBox(width: PharmacoTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: PharmacoTokens.neutral400, fontWeight: PharmacoTokens.weightMedium)),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: PharmacoTokens.weightSemiBold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
    return age;
  }

  Widget _buildVerificationBadge(bool isVerified) {
    final color = isVerified ? PharmacoTokens.success : PharmacoTokens.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: PharmacoTokens.borderRadiusFull,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVerified ? Icons.verified_rounded : Icons.info_outline_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(isVerified ? 'VERIFIED' : 'PENDING KYC', style: TextStyle(fontSize: 10, fontWeight: PharmacoTokens.weightBold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSectionGroup(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: PharmacoTokens.space12),
          child: Text(title, style: theme.textTheme.labelSmall?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.neutral400, letterSpacing: 1.1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: PharmacoTokens.white,
            borderRadius: PharmacoTokens.borderRadiusCard,
            boxShadow: PharmacoTokens.shadowZ1(),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ],
    );
  }

  Widget _buildMenuTile(ThemeData theme, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: PharmacoTokens.neutral600, size: 22),
      title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: PharmacoTokens.weightMedium)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: PharmacoTokens.neutral400),
      shape: RoundedRectangleBorder(borderRadius: PharmacoTokens.borderRadiusCard),
    );
  }

  Widget _buildLogoutButton(ThemeData theme, LanguageProvider lp) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _showLogoutConfirmation,
        icon: const Icon(Icons.logout_rounded, color: PharmacoTokens.error, size: 20),
        label: Text(lp.translate('logout'), style: const TextStyle(color: PharmacoTokens.error, fontWeight: PharmacoTokens.weightBold, letterSpacing: 1.1)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: PharmacoTokens.space16),
          shape: RoundedRectangleBorder(borderRadius: PharmacoTokens.borderRadiusMedium, side: BorderSide(color: PharmacoTokens.error.withValues(alpha: 0.2))),
        ),
      ),
    );
  }

  void _onEditProfile(Map<String, dynamic> profileData) async {
    final result = await Navigator.pushNamed(context, AppRoutes.editPersonalDetails, arguments: _createProfileForEditing(profileData));
    await _fetchProfile();
  }

  OnboardingProfile _createProfileForEditing(Map<String, dynamic> profileData) {
    return OnboardingProfile(
      fullName: profileData['full_name'] as String?,
      phone: profileData['phone'] as String?,
      email: profileData['email'] as String? ?? _authService.currentUser?.email,
      dateOfBirth: profileData['date_of_birth'] != null ? DateTime.parse(profileData['date_of_birth']) : null,
      gender: profileData['gender'] as String?,
      vehicleType: profileData['vehicle_type'] as String?,
      vehicleModel: profileData['vehicle_model'] as String?,
      vehicleRegistration: profileData['vehicle_registration'] as String?,
      preferredDeliveryArea: profileData['preferred_delivery_area'] as String?,
    );
  }

  void _showLogoutConfirmation() {
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(PharmacoTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lp.translate('logout'), style: theme.textTheme.titleLarge),
            const SizedBox(height: PharmacoTokens.space12),
            Text('Are you sure you want to exit the app? You will need to login again to receive orders.', style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500)),
            const SizedBox(height: PharmacoTokens.space24),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL'))),
                const SizedBox(width: PharmacoTokens.space16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _authService.signOut();
                      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: PharmacoTokens.error, foregroundColor: PharmacoTokens.white),
                    child: Text(lp.translate('logout')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
