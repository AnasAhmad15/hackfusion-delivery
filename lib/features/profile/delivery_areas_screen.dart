import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/app/widgets/custom_button.dart';

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
      setState(() {
        _deliveryAreas.add(_areaController.text.trim());
        _areaController.clear();
      });
    }
  }

  void _removeArea(String area) {
    setState(() {
      _deliveryAreas.remove(area);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferred Delivery Areas'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _deliveryAreas.length,
              itemBuilder: (context, index) {
                final area = _deliveryAreas[index];
                return ListTile(
                  title: Text(area),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => _removeArea(area),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _areaController,
                    decoration: InputDecoration(
                      labelText: 'Add New Area',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 40),
                  onPressed: _addArea,
                  color: theme.primaryColor,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomButton(
              text: 'SAVE PREFERENCES',
              onPressed: () {
                // Placeholder for saving data
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
