import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/widgets/custom_button.dart';
import 'package:pharmaco_delivery_partner/core/models/onboarding_profile.dart';
import 'package:pharmaco_delivery_partner/core/services/profile_service.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';

class ProfileSummaryScreen extends StatefulWidget {
  final OnboardingProfile profile;
  const ProfileSummaryScreen({super.key, required this.profile});

  @override
  State<ProfileSummaryScreen> createState() => _ProfileSummaryScreenState();
}

class _ProfileSummaryScreenState extends State<ProfileSummaryScreen> {
  final _profileService = ProfileService();
  bool _isLoading = false;

  Future<void> _submitProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _profileService.updateOnboardingProfile(widget.profile);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Confirm (4/4)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummarySection(context, 'Personal Details', {
              'Full Name': widget.profile.fullName ?? 'N/A',
              'Phone Number': widget.profile.phone ?? 'N/A',
              'Date of Birth': widget.profile.dateOfBirth?.toLocal().toString().split(' ')[0] ?? 'N/A',
              'Gender': widget.profile.gender ?? 'N/A',
              'Age': _calculateAge(widget.profile.dateOfBirth)?.toString() ?? 'N/A',
            }),
            const SizedBox(height: 24),
            _buildSummarySection(context, 'Vehicle Details', {
              'Vehicle Type': widget.profile.vehicleType ?? 'N/A',
              'Model': widget.profile.vehicleModel ?? 'N/A',
              'Registration': widget.profile.vehicleRegistration ?? 'N/A',
            }),
            const SizedBox(height: 24),
            _buildSummarySection(context, 'Delivery Area', {
              'Preferred Area': widget.profile.preferredDeliveryArea ?? 'N/A',
            }),
            const SizedBox(height: 48),
            CustomButton(
              text: _isLoading ? 'SAVING...' : 'CONFIRM & COMPLETE PROFILE',
              onPressed: _isLoading ? () {} : _submitProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, String title, Map<String, String> data) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.edit_outlined), 
              onPressed: () {
                switch (title) {
                  case 'Personal Details':
                    Navigator.pushNamed(context, AppRoutes.personalDetails, arguments: widget.profile);
                    break;
                  case 'Vehicle Details':
                    Navigator.pushNamed(context, AppRoutes.vehicleDetailsOnboarding, arguments: widget.profile);
                    break;
                  case 'Delivery Area':
                    Navigator.pushNamed(context, AppRoutes.deliveryAreaOnboarding, arguments: widget.profile);
                    break;
                }
              },
            ),
          ],
        ),
        const Divider(),
        ...data.entries.map((entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  entry.value, 
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
