import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleModel {
  final String id;
  final String vehicleType;
  final String brand;
  final String model;

  VehicleModel({
    required this.id,
    required this.vehicleType,
    required this.brand,
    required this.model,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      vehicleType: json['vehicle_type'],
      brand: json['brand'],
      model: json['model'],
    );
  }

  String get displayName => '$brand $model';
}

class VehicleService {
  final _client = Supabase.instance.client;

  Future<List<VehicleModel>> searchVehicleModels({
    required String type,
    required String query,
    int limit = 10,
  }) async {
    if (query.length < 2) return [];

    try {
      final response = await _client
          .from('vehicle_models')
          .select()
          .eq('vehicle_type', type)
          .eq('is_active', true)
          .or('brand.ilike.%$query%,model.ilike.%$query%')
          .limit(limit);

      return (response as List)
          .map((json) => VehicleModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching vehicle models: $e');
      return [];
    }
  }
}
