import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class DeliveryAreasScreen extends StatefulWidget {
  const DeliveryAreasScreen({super.key});

  @override
  State<DeliveryAreasScreen> createState() => _DeliveryAreasScreenState();
}

class _DeliveryAreasScreenState extends State<DeliveryAreasScreen> {
  final List<String> _deliveryAreas = ['Gachibowli', 'Hitech City'];
  final _areaController = TextEditingController();

  void _addArea() {
    if (_areaController.text.isNotEmpty) {
      setState(() { _deliveryAreas.add(_areaController.text.trim()); _areaController.clear(); });
    }
  }

  void _removeArea(String area) { setState(() => _deliveryAreas.remove(area)); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(title: const Text('Preferred Delivery Areas')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(PharmacoTokens.space16),
              itemCount: _deliveryAreas.length,
              itemBuilder: (context, index) {
                final area = _deliveryAreas[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: PharmacoTokens.space8),
                  decoration: BoxDecoration(color: PharmacoTokens.white, borderRadius: PharmacoTokens.borderRadiusMedium, boxShadow: PharmacoTokens.shadowZ1()),
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: PharmacoTokens.primaryBase),
                    title: Text(area, style: theme.textTheme.bodyMedium),
                    trailing: IconButton(icon: const Icon(Icons.remove_circle_outline_rounded, color: PharmacoTokens.error), onPressed: () => _removeArea(area)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(PharmacoTokens.space16),
            decoration: BoxDecoration(color: PharmacoTokens.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))]),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: TextField(controller: _areaController, decoration: const InputDecoration(labelText: 'Add New Area'))),
                    const SizedBox(width: PharmacoTokens.space16),
                    IconButton(icon: const Icon(Icons.add_circle_rounded, size: 40), onPressed: _addArea, color: PharmacoTokens.primaryBase),
                  ],
                ),
                const SizedBox(height: PharmacoTokens.space16),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('SAVE PREFERENCES'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
