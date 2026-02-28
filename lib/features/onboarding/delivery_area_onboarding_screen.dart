import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/core/models/onboarding_profile.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/services/profile_service.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class DeliveryAreaOnboardingScreen extends StatefulWidget {
  final OnboardingProfile profile;
  final bool isEditing;
  const DeliveryAreaOnboardingScreen({super.key, required this.profile, this.isEditing = false});

  @override
  State<DeliveryAreaOnboardingScreen> createState() => _DeliveryAreaOnboardingScreenState();
}

class _DeliveryAreaOnboardingScreenState extends State<DeliveryAreaOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _areaController.text = widget.profile.preferredDeliveryArea ?? '';
    }
    _areaController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _areaController.removeListener(_checkForChanges);
    _areaController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    if (!widget.isEditing) return;

    final hasChanged = _areaController.text != (widget.profile.preferredDeliveryArea ?? '');

    if (hasChanged != _hasChanges) {
      setState(() {
        _hasChanges = hasChanged;
      });
    }
  }

  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        widget.profile.preferredDeliveryArea = _areaController.text.trim();
        
        final profileService = ProfileService();
        await profileService.updateOnboardingProfile(widget.profile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery area updated successfully!'),
              backgroundColor: PharmacoTokens.success,
            ),
          );
          if (widget.isEditing) {
            Navigator.pop(context, true);
          } else {
            Navigator.pushNamed(context, AppRoutes.profileSummary, arguments: widget.profile);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update area: ${e.toString()}'),
              backgroundColor: PharmacoTokens.error,
              action: SnackBarAction(
                label: 'RETRY',
                textColor: PharmacoTokens.white,
                onPressed: _submit,
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickLocationFromMap() async {
    final result = await Navigator.pushNamed(context, AppRoutes.mapLocationSelection);
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _areaController.text = result['address'];
        _checkForChanges();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Delivery Area' : 'Delivery Area (3/4)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Set your service location to start receiving nearby orders.',
                style: TextStyle(color: PharmacoTokens.neutral500, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _areaController,
                decoration: InputDecoration(
                  labelText: 'Selected Service Area',
                  hintText: 'Enter manually or use map',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map_outlined, color: PharmacoTokens.primaryBase),
                    onPressed: _pickLocationFromMap,
                    tooltip: 'Select on map',
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please select a location' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickLocationFromMap,
                icon: const Icon(Icons.my_location),
                label: const Text('SELECT ON MAP'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: (_isLoading || (widget.isEditing && !_hasChanges)) ? null : _submit,
                child: Text(_isLoading 
                    ? (widget.isEditing ? 'SAVING...' : 'UPLOADING...') 
                    : (widget.isEditing ? 'SAVE CHANGES' : 'CONTINUE')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
