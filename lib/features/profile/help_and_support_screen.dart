import 'package:flutter/material.dart';

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHelpItem(context, 'FAQs', 'Find answers to frequently asked questions.', Icons.quiz_outlined),
          const Divider(),
          _buildHelpItem(context, 'Contact Us', 'Get in touch with our support team.', Icons.support_agent_outlined),
          const Divider(),
          _buildHelpItem(context, 'Terms of Service', 'Read our terms and conditions.', Icons.article_outlined),
        ],
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // TODO: Implement navigation to the specific help section
      },
    );
  }
}
