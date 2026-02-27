import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.language, size: 80, color: Colors.blue),
              const SizedBox(height: 32),
              Text(
                languageProvider.translate('select_language'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              _LanguageButton(
                label: 'English',
                isSelected: languageProvider.currentLocale.languageCode == 'en',
                onTap: () => languageProvider.setLanguage('en'),
              ),
              const SizedBox(height: 16),
              _LanguageButton(
                label: 'हिंदी (Hindi)',
                isSelected: languageProvider.currentLocale.languageCode == 'hi',
                onTap: () => languageProvider.setLanguage('hi'),
              ),
              const SizedBox(height: 16),
              _LanguageButton(
                label: 'मराठी (Marathi)',
                isSelected: languageProvider.currentLocale.languageCode == 'mr',
                onTap: () => languageProvider.setLanguage('mr'),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () async {
                  await languageProvider.setFirstTimeCompleted();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  languageProvider.translate('continue'),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
