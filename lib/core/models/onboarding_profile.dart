import 'dart:io';

class OnboardingProfile {
  String? fullName;
  String? phone;
  String? email;
  File? profileImage;
  DateTime? dateOfBirth;
  String? gender;
  String? vehicleType;
  String? vehicleModel;
  String? vehicleRegistration;
  String? preferredDeliveryArea;

  OnboardingProfile({
    this.fullName,
    this.phone,
    this.email,
    this.profileImage,
    this.dateOfBirth,
    this.gender,
    this.vehicleType,
    this.vehicleModel,
    this.vehicleRegistration,
    this.preferredDeliveryArea,
  });

  factory OnboardingProfile.fromMap(Map<String, dynamic> map) {
    return OnboardingProfile(
      fullName: map['full_name']?.toString(),
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      dateOfBirth: map['date_of_birth'] != null ? DateTime.tryParse(map['date_of_birth'].toString()) : null,
      gender: map['gender']?.toString(),
      vehicleType: map['vehicle_type']?.toString(),
      vehicleModel: map['vehicle_model']?.toString(),
      vehicleRegistration: map['vehicle_registration']?.toString(),
      preferredDeliveryArea: map['preferred_delivery_area']?.toString(),
    );
  }
}
