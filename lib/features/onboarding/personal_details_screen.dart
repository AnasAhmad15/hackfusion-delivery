import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/models/onboarding_profile.dart';
import 'package:pharmaco_delivery_partner/core/services/profile_service.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final OnboardingProfile profile;
  final bool isEditing;
  const PersonalDetailsScreen({super.key, required this.profile, this.isEditing = false});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  File? _profileImage;
  bool _hasChanges = false;
  bool _isPickingImage = false;
  bool _isFormValid = false;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _fullNameController.text = widget.profile.fullName ?? '';
      _phoneController.text = widget.profile.phone ?? '';
      _emailController.text = widget.profile.email ?? '';
      _selectedDate = widget.profile.dateOfBirth;
      _selectedGender = widget.profile.gender;
    }
    _fullNameController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_checkForChanges);
    _phoneController.removeListener(_checkForChanges);
    _emailController.removeListener(_checkForChanges);
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    if (!widget.isEditing) return;

    final hasChanged = (_fullNameController.text != (widget.profile.fullName ?? '')) ||
        (_phoneController.text != (widget.profile.phone ?? '')) ||
        (_emailController.text != (widget.profile.email ?? '')) ||
        (_selectedDate != widget.profile.dateOfBirth) ||
        (_selectedGender != widget.profile.gender) ||
        (_profileImage != null);

    if (hasChanged != _hasChanges) {
      setState(() {
        _hasChanges = hasChanged;
      });
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    
    setState(() => _isPickingImage = true);
    
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (!mounted) return;

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _checkForChanges();
        });
      }
    } catch (e) {
      debugPrint('PersonalDetailsScreen: Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime lastDate = DateTime(now.year - 18, now.month, now.day);
    
    // Ensure initialDate is not after lastDate
    DateTime initialDate = _selectedDate ?? lastDate;
    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: lastDate,
      helpText: 'Select Date of Birth (Must be 18+)',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _checkForChanges();
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        widget.profile.fullName = _fullNameController.text.trim();
        widget.profile.phone = _phoneController.text.trim();
        widget.profile.email = _emailController.text.trim();
        widget.profile.dateOfBirth = _selectedDate;
        widget.profile.gender = _selectedGender;
        widget.profile.profileImage = _profileImage;

        debugPrint('PersonalDetailsScreen: Updating profile in Supabase...');
        final profileService = ProfileService();
        await profileService.updateOnboardingProfile(widget.profile);
        debugPrint('PersonalDetailsScreen: Update successful');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: PharmacoTokens.success,
            ),
          );
          if (widget.isEditing) {
            Navigator.pop(context, true);
          } else {
            Navigator.pushNamed(context, AppRoutes.vehicleDetailsOnboarding, arguments: widget.profile);
          }
        }
      } catch (e) {
        debugPrint('PersonalDetailsScreen: Update failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Personal Details' : 'Personal Details (1/4)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: PharmacoTokens.primarySurface,
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? const Icon(Icons.camera_alt_rounded, color: PharmacoTokens.primaryBase, size: 50)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Upload Profile Photo',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 48),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phoneController,
                enabled: !widget.isEditing, // Phone is non-editable during edit mode
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildDatePicker(context),
              const SizedBox(height: 24),
              _buildGenderDropdown(),
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

  Widget _buildDatePicker(BuildContext context) {
    return FormField<DateTime>(
      initialValue: _selectedDate,
      validator: (value) {
        if (_selectedDate == null) {
          return 'Please select your date of birth';
        }
        final DateTime now = DateTime.now();
        final DateTime minAgeDate = DateTime(now.year - 18, now.month, now.day);
        if (_selectedDate!.isAfter(minAgeDate)) {
          return 'You must be at least 18 years old';
        }
        return null;
      },
      builder: (FormFieldState<DateTime> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () async {
                await _selectDate(context);
                state.didChange(_selectedDate);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: state.errorText,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Select your date of birth'
                            : '${_selectedDate!.toLocal()}'.split(' ')[0],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender (Optional)',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: ['Male', 'Female', 'Other', 'Prefer not to say']
          .map((label) => DropdownMenuItem(
                value: label,
                child: Text(label),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
          _checkForChanges();
        });
      },
    );
  }
}
