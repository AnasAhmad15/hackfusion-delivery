import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pharmaco_delivery_partner/app/widgets/custom_button.dart';
import 'package:pharmaco_delivery_partner/core/services/map_location_service.dart';

class MapLocationSelectionScreen extends StatefulWidget {
  const MapLocationSelectionScreen({super.key});

  @override
  State<MapLocationSelectionScreen> createState() => _MapLocationSelectionScreenState();
}

class _MapLocationSelectionScreenState extends State<MapLocationSelectionScreen> {
  GoogleMapController? _mapController;
  final MapLocationService _locationService = MapLocationService();
  
  LatLng _currentCenter = const LatLng(19.0760, 72.8777); // Default to Mumbai
  String _currentAddress = "Loading address...";
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLocating = true);
    
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLocating = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLocating = false);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLocating = false);
      return;
    } 

    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    _updateAddress(latLng);
    setState(() => _isLocating = false);
  }

  Future<void> _updateAddress(LatLng position) async {
    final address = await _locationService.getAddressFromLatLng(position);
    if (mounted) {
      setState(() {
        _currentCenter = position;
        _currentAddress = address;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Full screen map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentCenter, zoom: 12),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) => _currentCenter = position.target,
            onCameraIdle: () => _updateAddress(_currentCenter),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Dynamic Pin in Center
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35), // Compensate for pin height
              child: Icon(
                Icons.location_on,
                size: 50,
                color: theme.primaryColor,
              ),
            ),
          ),

          // Top Header Info
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Select Service Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 48.0),
                    child: Text(
                      'Move the map to set your delivery area.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Current Location Button
          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              child: _isLocating 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.my_location, color: theme.primaryColor),
              onPressed: _determinePosition,
            ),
          ),

          // Bottom Action Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Selected Area:',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.place, color: theme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentAddress,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'CONFIRM LOCATION',
                    onPressed: () {
                      Navigator.pop(context, {
                        'address': _currentAddress,
                        'lat': _currentCenter.latitude,
                        'lng': _currentCenter.longitude,
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
