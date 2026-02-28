import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/theme/pharmaco_theme.dart';
import 'package:pharmaco_delivery_partner/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pharmaco_delivery_partner/features/navigation/main_navigation_screen.dart';
import 'package:pharmaco_delivery_partner/features/auth/login_screen.dart';
import 'package:pharmaco_delivery_partner/features/language/language_selection_screen.dart';
import 'package:pharmaco_delivery_partner/core/services/fcm_service.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('=== FLUTTER ERROR ===');
    debugPrint('EXCEPTION: ${details.exception}');
    debugPrint('LIBRARY: ${details.library}');
    debugPrint('CONTEXT: ${details.context}');
    final stackLines = details.stack?.toString().split('\n') ?? [];
    for (int i = 0; i < stackLines.length && i < 10; i++) {
      debugPrint('  ${stackLines[i]}');
    }
    debugPrint('... total frames: ${stackLines.length}');
    debugPrint('=== END ERROR ===');
  };

  await Firebase.initializeApp();
  await SupabaseService.initialize();
  await FCMService.initialize();
  
  runZonedGuarded(() {
    runApp(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: const PharmaCoApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('=== ZONE ERROR ===');
    debugPrint('$error');
    debugPrint('$stackTrace');
    debugPrint('=== END ZONE ERROR ===');
  });
}

class PharmaCoApp extends StatelessWidget {
  const PharmaCoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PharmaCo Delivery',
      theme: PharmacoTheme.lightTheme,
      darkTheme: PharmacoTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const AuthWrapper(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      routes: AppRoutes.routes,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (languageProvider.isFirstTime) {
      return const LanguageSelectionScreen();
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;
        if (session == null) {
          return const LoginScreen();
        }

        return const MainNavigationScreen();
      },
    );
  }
}
