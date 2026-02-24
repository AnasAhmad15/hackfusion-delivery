import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/core/services/profile_service.dart';
import 'package:pharmaco_delivery_partner/core/services/auth_service.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/models/onboarding_profile.dart';

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
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    try {
      final data = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return StreamBuilder<Map<String, dynamic>>(
      stream: _profileService.getProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _profileData == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final profileData = snapshot.hasData ? snapshot.data! : _profileData ?? {};

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
          ),
          body: RefreshIndicator(
            onRefresh: _fetchProfile,
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                _buildProfileHeader(theme, profileData),
                const SizedBox(height: 24),
                _buildPersonalInfoCard(theme, profileData),
                const SizedBox(height: 24),
                _buildSectionGroup(
                  'ACCOUNT',
                  [
                    _buildMenuTile(Icons.description_outlined, 'Documents & Verification', () => Navigator.pushNamed(context, AppRoutes.documentsVerification)),
                    _buildMenuTile(Icons.security_outlined, 'Security & Login', () => Navigator.pushNamed(context, AppRoutes.security)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionGroup(
                  'WORK',
                  [
                    _buildMenuTile(Icons.directions_car_outlined, 'Vehicle Details', () => Navigator.pushNamed(context, AppRoutes.editVehicleDetails, arguments: _createProfileForEditing(profileData))),
                    _buildMenuTile(Icons.map_outlined, 'Service Area', () => Navigator.pushNamed(context, AppRoutes.editDeliveryArea, arguments: _createProfileForEditing(profileData))),
                    _buildMenuTile(Icons.access_time, 'Availability Preferences', () {}),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionGroup(
                  'SUPPORT',
                  [
                    _buildMenuTile(Icons.help_outline, 'Help Center & FAQ', () => Navigator.pushNamed(context, AppRoutes.helpAndSupport)),
                    _buildMenuTile(Icons.headset_mic_outlined, 'Contact Support', () {}),
                    _buildMenuTile(Icons.info_outline, 'Terms & Privacy', () {}),
                  ],
                ),
                const SizedBox(height: 40),
                _buildLogoutButton(theme),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Version 1.0.2 (Production)',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(ThemeData theme, Map<String, dynamic> profileData) {
    final String photoUrl = profileData['profile_photo_url'] as String? ?? '';
    final bool isVerified = profileData['profile_completed'] ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            key: ValueKey(photoUrl),
            backgroundColor: Colors.grey[100],
            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            onBackgroundImageError: photoUrl.isNotEmpty ? (e, s) => debugPrint('ProfileScreen: Image load error: $e') : null,
            child: photoUrl.isEmpty ? Icon(Icons.person, size: 40, color: Colors.grey[400]) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profileData['full_name'] as String? ?? 'Delivery Partner',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _authService.currentUser?.email ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _buildVerificationBadge(isVerified),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(ThemeData theme, Map<String, dynamic> profileData) {
    final int? age = profileData['date_of_birth'] != null 
        ? _calculateAge(DateTime.parse(profileData['date_of_birth'])) 
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PERSONAL INFORMATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1.1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                  onPressed: () => _onEditProfile(profileData),
                  tooltip: 'Edit Profile',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildInfoRow(Icons.person_outline, 'Full Name', profileData['full_name'] ?? 'N/A'),
          _buildInfoRow(Icons.phone_outlined, 'Phone Number', profileData['phone'] ?? 'N/A'),
          _buildInfoRow(Icons.calendar_today_outlined, 'Age', age?.toString() ?? 'N/A'),
          _buildInfoRow(Icons.email_outlined, 'Email Address', profileData['email'] ?? _authService.currentUser?.email ?? 'N/A'),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  Widget _buildVerificationBadge(bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isVerified ? Colors.green : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isVerified ? Colors.green : Colors.orange).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVerified ? Icons.verified : Icons.info_outline, size: 14, color: isVerified ? Colors.green : Colors.orange),
          const SizedBox(width: 6),
          Text(
            isVerified ? 'VERIFIED' : 'PENDING KYC',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isVerified ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Added safety for layout
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Standardize column height
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.grey[700], size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _showLogoutConfirmation,
        icon: const Icon(Icons.logout, color: Colors.red, size: 20),
        label: const Text('LOGOUT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.withOpacity(0.2))),
        ),
      ),
    );
  }

  void _onEditProfile(Map<String, dynamic> profileData) async {
    final result = await Navigator.pushNamed(
      context, 
      AppRoutes.editPersonalDetails, 
      arguments: _createProfileForEditing(profileData),
    );
    
    // Always refresh if we returned from the edit screen, 
    // even if result wasn't explicitly 'true', just to be safe.
    await _fetchProfile(); 
  }

  OnboardingProfile _createProfileForEditing(Map<String, dynamic> profileData) {
    // Debug the data being used for editing
    debugPrint('ProfileScreen: Creating editing profile from: ${profileData['full_name']}');
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Logout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Are you sure you want to exit the app? You will need to login again to receive orders.'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _authService.signOut();
                      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: const Text('LOGOUT'),
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
