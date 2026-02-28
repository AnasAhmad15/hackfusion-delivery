import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(PharmacoTokens.space16),
        children: [
          _buildHelpItem(context, theme, 'FAQs', 'Find answers to frequently asked questions.', Icons.quiz_outlined),
          const SizedBox(height: PharmacoTokens.space12),
          _buildHelpItem(context, theme, 'Contact Us', 'Get in touch with our support team.', Icons.support_agent_outlined),
          const SizedBox(height: PharmacoTokens.space12),
          _buildHelpItem(context, theme, 'Terms of Service', 'Read our terms and conditions.', Icons.article_outlined),
        ],
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, ThemeData theme, String title, String subtitle, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: PharmacoTokens.white, borderRadius: PharmacoTokens.borderRadiusCard, boxShadow: PharmacoTokens.shadowZ1()),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: PharmacoTokens.space20, vertical: PharmacoTokens.space8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(color: PharmacoTokens.primarySurface, shape: BoxShape.circle),
          child: Icon(icon, color: PharmacoTokens.primaryBase, size: 22),
        ),
        title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: PharmacoTokens.neutral500)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: PharmacoTokens.neutral400),
        onTap: () {},
      ),
    );
  }
}
