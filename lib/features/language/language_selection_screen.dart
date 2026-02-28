import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: PharmacoTokens.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: PharmacoTokens.primarySurface,
                child: const Icon(Icons.language_rounded, size: 44, color: PharmacoTokens.primaryBase),
              ),
              const SizedBox(height: PharmacoTokens.space32),
              Text(
                languageProvider.translate('select_language'),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: PharmacoTokens.space48),
              _LanguageButton(label: 'English', isSelected: languageProvider.currentLocale.languageCode == 'en', onTap: () => languageProvider.setLanguage('en')),
              const SizedBox(height: PharmacoTokens.space16),
              _LanguageButton(label: 'हिंदी (Hindi)', isSelected: languageProvider.currentLocale.languageCode == 'hi', onTap: () => languageProvider.setLanguage('hi')),
              const SizedBox(height: PharmacoTokens.space16),
              _LanguageButton(label: 'मराठी (Marathi)', isSelected: languageProvider.currentLocale.languageCode == 'mr', onTap: () => languageProvider.setLanguage('mr')),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () async {
                  await languageProvider.setFirstTimeCompleted();
                  if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: Text(languageProvider.translate('continue'), style: const TextStyle(fontSize: 18)),
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
  const _LanguageButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: PharmacoTokens.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.all(PharmacoTokens.space16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? PharmacoTokens.primaryBase : PharmacoTokens.neutral200, width: 2),
          borderRadius: PharmacoTokens.borderRadiusMedium,
          color: isSelected ? PharmacoTokens.primarySurface : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 18, fontWeight: isSelected ? PharmacoTokens.weightBold : FontWeight.normal, color: isSelected ? PharmacoTokens.primaryBase : PharmacoTokens.neutral900)),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: PharmacoTokens.primaryBase),
          ],
        ),
      ),
    );
  }
}
