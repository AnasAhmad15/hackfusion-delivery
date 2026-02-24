import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapLocationService {
  Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Construct a clean address string
        String address = '';
        if (place.name != null && place.name!.isNotEmpty) address += '${place.name}, ';
        if (place.subLocality != null && place.subLocality!.isNotEmpty) address += '${place.subLocality}, ';
        if (place.locality != null && place.locality!.isNotEmpty) address += '${place.locality}, ';
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) address += place.administrativeArea!;
        
        // Remove trailing comma and space if present
        if (address.endsWith(', ')) {
          address = address.substring(0, address.length - 2);
        }
        return address;
      }
      return "Unknown Location";
    } catch (e) {
      print('Error getting address: $e');
      return "Location selection error";
    }
  }
}
