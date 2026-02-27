import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/features/auth/login_screen.dart';
import 'package:pharmaco_delivery_partner/features/home/home_screen.dart';
import 'package:pharmaco_delivery_partner/features/order/incoming_order_screen.dart';
import 'package:pharmaco_delivery_partner/features/order/order_details_screen.dart';
import 'package:pharmaco_delivery_partner/features/order/pickup_confirmation_screen.dart';
import 'package:pharmaco_delivery_partner/features/order/live_delivery_screen.dart';
import 'package:pharmaco_delivery_partner/features/earnings/earnings_screen.dart';
import 'package:pharmaco_delivery_partner/features/auth/signup_screen.dart';
import 'package:pharmaco_delivery_partner/features/auth/forgot_password_screen.dart';
import 'package:pharmaco_delivery_partner/features/profile/profile_screen.dart';
import 'package:pharmaco_delivery_partner/features/profile/documents_verification_screen.dart';
import 'package:pharmaco_delivery_partner/features/ratings/ratings_screen.dart';
import 'package:pharmaco_delivery_partner/features/profile/vehicle_details_screen.dart';
import 'package:pharmaco_delivery_partner/features/profile/delivery_areas_screen.dart';
import 'package:pharmaco_delivery_partner/features/profile/security_screen.dart';
import 'package:pharmaco_delivery_partner/features/profile/help_and_support_screen.dart';
import 'package:pharmaco_delivery_partner/features/auth/email_verification_screen.dart';
import 'package:pharmaco_delivery_partner/features/order/order_summary_screen.dart';
import 'package:pharmaco_delivery_partner/features/earnings/withdraw_funds_screen.dart';
import 'package:pharmaco_delivery_partner/features/onboarding/map_location_selection_screen.dart';
import 'package:pharmaco_delivery_partner/features/onboarding/personal_details_screen.dart';
import 'package:pharmaco_delivery_partner/features/onboarding/vehicle_details_onboarding_screen.dart';
import 'package:pharmaco_delivery_partner/features/onboarding/delivery_area_onboarding_screen.dart';
import 'package:pharmaco_delivery_partner/features/onboarding/profile_summary_screen.dart';
import 'package:pharmaco_delivery_partner/features/navigation/main_navigation_screen.dart';
import 'package:pharmaco_delivery_partner/core/models/onboarding_profile.dart';
import 'package:pharmaco_delivery_partner/app/routes/slide_route.dart';

import 'package:pharmaco_delivery_partner/features/order/confirm_delivery_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String home = '/home';
  static const String incomingOrder = '/incoming-order';
  static const String orderDetails = '/order-details';
  static const String pickupConfirmation = '/pickup-confirmation';
  static const String liveDelivery = '/live-delivery';
  static const String earnings = '/earnings';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';
  static const String documentsVerification = '/documents-verification';
  static const String ratings = '/ratings';
  static const String vehicleDetails = '/profile/vehicle';
  static const String deliveryAreas = '/profile/areas';
  static const String security = '/security';
  static const String helpAndSupport = '/help-and-support';
  static const String emailVerification = '/email-verification';
  static const String personalDetails = '/onboarding/personal-details';
  static const String vehicleDetailsOnboarding = '/vehicle-details-onboarding';
  static const String deliveryAreaOnboarding = '/delivery-area-onboarding';
  static const String mapLocationSelection = '/map-location-selection';
  static const String withdrawFunds = '/earnings/withdraw';
  static const String orderSummary = '/order/summary';
  static const String profileSummary = '/onboarding/summary';

  static const String editPersonalDetails = '/profile/edit-personal';
  static const String editVehicleDetails = '/profile/edit-vehicle';
  static const String editDeliveryArea = '/profile/edit-area';

  static const String confirmDelivery = '/order/confirm-delivery';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case editPersonalDetails:
        if (settings.arguments is OnboardingProfile) {
          final profile = settings.arguments as OnboardingProfile;
          return SlideRoute(page: PersonalDetailsScreen(profile: profile, isEditing: true));
        } else {
          // Fallback for when arguments are not the expected type (e.g. from HomeScreen)
          return SlideRoute(page: PersonalDetailsScreen(profile: OnboardingProfile(), isEditing: true));
        }
      case editVehicleDetails:
        final profile = settings.arguments as OnboardingProfile;
        return SlideRoute(page: VehicleDetailsOnboardingScreen(profile: profile, isEditing: true));
      case editDeliveryArea:
        final profile = settings.arguments as OnboardingProfile;
        return SlideRoute(page: DeliveryAreaOnboardingScreen(profile: profile, isEditing: true));
      case mapLocationSelection:
        return SlideRoute(page: const MapLocationSelectionScreen());
      case withdrawFunds:
        final balance = settings.arguments as double;
        return SlideRoute(page: WithdrawFundsScreen(availableBalance: balance));
      case orderSummary:
        return SlideRoute(page: const OrderSummaryScreen());
      default:
        return null;
    }
  }

  static Map<String, WidgetBuilder> get routes {
    return {
      home: (context) => const MainNavigationScreen(),
      incomingOrder: (context) => const IncomingOrderScreen(),
      orderDetails: (context) => const OrderDetailsScreen(),
      pickupConfirmation: (context) => const PickupConfirmationScreen(),
      liveDelivery: (context) => const LiveDeliveryScreen(),
      earnings: (context) => const EarningsScreen(),
      signUp: (context) => const SignUpScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      profile: (context) => const ProfileScreen(),
      documentsVerification: (context) => const DocumentsVerificationScreen(),
      vehicleDetails: (context) => const VehicleDetailsScreen(),
      deliveryAreas: (context) => const DeliveryAreasScreen(),
      security: (context) => const SecurityScreen(),
      helpAndSupport: (context) => const HelpAndSupportScreen(),
      emailVerification: (context) {
        final email = ModalRoute.of(context)!.settings.arguments as String;
        return EmailVerificationScreen(email: email);
      },
      personalDetails: (context) {
        // Always start with a fresh profile object for the onboarding flow.
        final profile = OnboardingProfile();
        return PersonalDetailsScreen(profile: profile);
      },
      vehicleDetailsOnboarding: (context) {
        final profile = ModalRoute.of(context)!.settings.arguments as OnboardingProfile;
        return VehicleDetailsOnboardingScreen(profile: profile);
      },
      deliveryAreaOnboarding: (context) {
        final profile = ModalRoute.of(context)!.settings.arguments as OnboardingProfile;
        return DeliveryAreaOnboardingScreen(profile: profile);
      },
      profileSummary: (context) {
        final profile = ModalRoute.of(context)!.settings.arguments as OnboardingProfile;
        return ProfileSummaryScreen(profile: profile);
      },
      confirmDelivery: (context) {
        final order = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return ConfirmDeliveryScreen(order: order);
      },
    };
  }
}
