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
}
