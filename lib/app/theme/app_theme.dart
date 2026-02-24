import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF007AFF); // Medical Blue
  static const Color secondaryColor = Colors.white;
  static const Color textColor = Colors.black87;

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: secondaryColor,
      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: secondaryColor),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
        bodyLarge: TextStyle(fontSize: 16, color: textColor),
      ),

      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: secondaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
