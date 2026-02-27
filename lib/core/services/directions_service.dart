import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteInfo {
  final String distance;
  final String duration;
  final List<LatLng> points;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.points,
  });
}

class DirectionsService {
  DirectionsService({required this.apiKey, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _httpClient;

  Future<RouteInfo?> getRouteInfo({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'key': apiKey,
    });

    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Directions API request failed: ${response.statusCode}');
    }

    final Map<String, dynamic> payload = jsonDecode(response.body) as Map<String, dynamic>;
    final status = payload['status'] as String?;
    if (status != 'OK') {
      final msg = payload['error_message'] as String?;
      throw Exception('Directions API error: $status${msg == null ? '' : ' - $msg'}');
    }

    final routes = payload['routes'] as List<dynamic>;
    if (routes.isEmpty) return null;

    final route = routes.first as Map<String, dynamic>;
    final legs = route['legs'] as List<dynamic>;
    if (legs.isEmpty) return null;

    final leg = legs.first as Map<String, dynamic>;
    final distance = leg['distance']['text'] as String;
    final duration = leg['duration']['text'] as String;

    final overviewPolyline = route['overview_polyline'] as Map<String, dynamic>?;
    final encoded = overviewPolyline?['points'] as String?;
    if (encoded == null || encoded.isEmpty) return null;

    final points = _decodePolyline(encoded);

    return RouteInfo(
      distance: distance,
      duration: duration,
      points: points,
    );
  }

  Future<List<LatLng>> getRoutePolyline({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final info = await getRouteInfo(origin: origin, destination: destination);
    return info?.points ?? <LatLng>[];
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = <LatLng>[];

    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
