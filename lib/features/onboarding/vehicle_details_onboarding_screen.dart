import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:pharmaco_delivery_partner/app/widgets/custom_button.dart';
import 'package:pharmaco_delivery_partner/core/models/onboarding_profile.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/services/profile_service.dart';
import 'package:pharmaco_delivery_partner/core/services/vehicle_service.dart';
import 'package:pharmaco_delivery_partner/core/utils/validators.dart';

class VehicleDetailsOnboardingScreen extends StatefulWidget {
  final OnboardingProfile profile;
  final bool isEditing;
  const VehicleDetailsOnboardingScreen({super.key, required this.profile, this.isEditing = false});

  @override
  State<VehicleDetailsOnboardingScreen> createState() => _VehicleDetailsOnboardingScreenState();
}

class _VehicleDetailsOnboardingScreenState extends State<VehicleDetailsOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleService();
  String? _vehicleType;
  final _modelController = TextEditingController();
  final _registrationController = TextEditingController();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _vehicleType = widget.profile.vehicleType;
      _modelController.text = widget.profile.vehicleModel ?? '';
      _registrationController.text = widget.profile.vehicleRegistration ?? '';
    }
    _modelController.addListener(_checkForChanges);
    _registrationController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _modelController.removeListener(_checkForChanges);
    _registrationController.removeListener(_checkForChanges);
    _modelController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    if (!widget.isEditing) return;

    final hasChanged = (_vehicleType != widget.profile.vehicleType) ||
        (_modelController.text != (widget.profile.vehicleModel ?? '')) ||
        (_registrationController.text != (widget.profile.vehicleRegistration ?? ''));

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
        widget.profile.vehicleType = _vehicleType;
        widget.profile.vehicleModel = _modelController.text.trim();
        widget.profile.vehicleRegistration = _registrationController.text.trim();

        final profileService = ProfileService();
        await profileService.updateOnboardingProfile(widget.profile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          if (widget.isEditing) {
            Navigator.pop(context, true);
          } else {
            Navigator.pushNamed(context, AppRoutes.deliveryAreaOnboarding, arguments: widget.profile);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update vehicle details: ${e.toString()}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Vehicle Details' : 'Vehicle Details (2/4)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVehicleTypeDropdown(),
              const SizedBox(height: 24),
              _buildVehicleModelAutocomplete(),
              const SizedBox(height: 24),
              _buildRegistrationField(),
              const SizedBox(height: 48),
              CustomButton(
                text: _isLoading 
                    ? (widget.isEditing ? 'SAVING...' : 'UPLOADING...') 
                    : (widget.isEditing ? 'SAVE CHANGES' : 'CONTINUE'),
                onPressed: (_isLoading || (widget.isEditing && !_hasChanges)) ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _vehicleType,
      decoration: InputDecoration(
        labelText: 'Vehicle Type',
        prefixIcon: const Icon(Icons.two_wheeler),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: ['Bike', 'Scooter', 'Car']
          .map((label) => DropdownMenuItem(
                value: label,
                child: Text(label),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _vehicleType = value;
          _modelController.clear();
          _checkForChanges();
        });
      },
      validator: (value) => value == null ? 'Please select a vehicle type' : null,
    );
  }

  Widget _buildVehicleModelAutocomplete() {
    return TypeAheadField<VehicleModel>(
      controller: _modelController,
      builder: (context, controller, focusNode) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Vehicle Name / Model',
            hintText: _vehicleType == null ? 'Select vehicle type first' : 'e.g. Honda Activa',
            prefixIcon: const Icon(Icons.motorcycle),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          enabled: _vehicleType != null,
          validator: (value) => value == null || value.isEmpty ? 'Please select or enter vehicle model' : null,
        );
      },
      suggestionsCallback: (search) async {
        if (_vehicleType == null || search.length < 2) return [];
        return await _vehicleService.searchVehicleModels(
          type: _vehicleType!,
          query: search,
        );
      },
      itemBuilder: (context, VehicleModel suggestion) {
        return ListTile(
          title: Text(suggestion.brand),
          subtitle: Text(suggestion.model),
          leading: const Icon(Icons.directions_bike),
        );
      },
      onSelected: (VehicleModel value) {
        setState(() {
          _modelController.text = value.displayName;
          _checkForChanges();
        });
      },
      emptyBuilder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No models found. You can enter manually.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildRegistrationField() {
    return TextFormField(
      controller: _registrationController,
      decoration: InputDecoration(
        labelText: 'Vehicle Registration Number',
        hintText: 'e.g. MH 12 AB 1234',
        prefixIcon: const Icon(Icons.pin),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\s]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          return newValue.copyWith(text: newValue.text.toUpperCase());
        }),
      ],
      validator: Validators.validateVehicleNumber,
      onChanged: (_) => _checkForChanges(),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
    );
  }
}
