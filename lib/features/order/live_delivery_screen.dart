import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';
import 'package:provider/provider.dart';

class LiveDeliveryScreen extends StatefulWidget {
  const LiveDeliveryScreen({super.key});

  @override
  State<LiveDeliveryScreen> createState() => _LiveDeliveryScreenState();
}

class _LiveDeliveryScreenState extends State<LiveDeliveryScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<geolocator.Position>? _locationSubscription;
  StreamSubscription<Map<String, dynamic>?>? _orderSubscription;
  final OrderService _orderService = OrderService();
  final SupabaseClient _client = Supabase.instance.client;

  LatLng? _pickupLocation;
  LatLng? _deliveryLocation;
  String? _pickupAddress;
  String? _deliveryAddress;
  String? _customerPhone;
  String? _customerName;
  String? _pharmacyName;
  Map<String, dynamic>? _order;

  Marker? _currentLocationMarker;
  bool _isUpdatingStatus = false;
  String? _lastProcessedStatus;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      if (_order == null) {
        _order = Map<String, dynamic>.from(arguments);
        final orderId = _order!['id']?.toString();
        if (orderId != null) {
          _subscribeToOrderStream(orderId);
        }
      }
      _ensureLocationsLoaded();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _orderSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    try {
      bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
        if (permission == geolocator.LocationPermission.denied) return;
      }
      
      if (permission == geolocator.LocationPermission.deniedForever) return;

      final position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );
      
      if (mounted) {
        final initialLatLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocationMarker = Marker(
            markerId: const MarkerId('currentLocation'),
            position: initialLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'My Location'),
          );
        });
      }
    } catch (e) {
      debugPrint('LiveDelivery: Error initializing location: $e');
    }
    _listenToLocation();
  }

  void _listenToLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = geolocator.Geolocator.getPositionStream(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((geolocator.Position position) {
      if (!mounted) return;
      final currentLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocationMarker = Marker(
          markerId: const MarkerId('currentLocation'),
          position: currentLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          rotation: position.heading,
          infoWindow: const InfoWindow(title: 'My Location'),
        );
      });
      _updateDriverLocationInSupabase(currentLatLng);
    });
  }

  void _subscribeToOrderStream(String orderId) {
    _orderSubscription?.cancel();
    _orderSubscription = _orderService.getOrderStream(orderId).listen((data) async {
      if (!mounted || data == null) return;
      final newStatus = (data['status'] as String? ?? '').toLowerCase().trim();
      bool needsLocationReload = _pickupLocation == null || _deliveryLocation == null;
      bool statusChanged = newStatus != _lastProcessedStatus;

      if (statusChanged || needsLocationReload) {
        setState(() {
          _order = Map<String, dynamic>.from(data);
          if (statusChanged) _lastProcessedStatus = newStatus;
        });
        await _ensureLocationsLoaded();
        
        // Removed auto-redirection on status change
      }
    });
  }

  Future<void> _ensureLocationsLoaded() async {
    final order = _order;
    if (order == null) return;
    final pharmacyId = order['pharmacy_id']?.toString();
    final userId = order['user_id']?.toString();
    
    if (_pickupLocation == null && pharmacyId != null) await _loadPharmacyLocation(pharmacyId);
    if (_deliveryLocation == null && userId != null) await _loadCustomerLocation(userId);
    if (_customerPhone == null && userId != null) _loadCustomerPhone(userId);

    if (_pickupLocation != null || _deliveryLocation != null) {
      _checkInitialAutoRedirect();
    }
  }

  bool _initialRedirectDone = false;
  void _checkInitialAutoRedirect() {
    // Disabled initial auto-redirect
  }

  Future<void> _loadPharmacyLocation(String pharmacyId) async {
    debugPrint('LiveDelivery: _loadPharmacyLocation checking ID: $pharmacyId');
    try {
      final res = await _client.from('medical_partners').select('lat, lng, address, medical_name').eq('id', pharmacyId).maybeSingle();
      
      if (res != null) {
        final double? lat = (res['lat'] as num?)?.toDouble();
        final double? lng = (res['lng'] as num?)?.toDouble();
        final String? address = res['address']?.toString();

        LatLng? resolved;
        if (lat != null && lng != null) {
          resolved = LatLng(lat, lng);
        } else if (address != null && address.isNotEmpty) {
          resolved = await _geocodeToLatLng(address);
        }

        if (resolved != null && mounted) {
          setState(() {
            _pickupLocation = resolved;
            _pickupAddress = address;
            _pharmacyName = res['medical_name']?.toString() ?? 'Pharmacy';
          });
          debugPrint('LiveDelivery: Pharmacy location resolved: $resolved');
        }
      }
    } catch (e) {
      debugPrint('LiveDelivery: Error loading pharmacy: $e');
    }
  }

  Future<void> _loadCustomerLocation(String userId) async {
    debugPrint('LiveDelivery: _loadCustomerLocation checking ID: $userId');
    try {
      final res = await _client.from('user_profiles').select('latitude, longitude, address, full_name').eq('id', userId).maybeSingle();
      
      if (res != null) {
        final double? lat = (res['latitude'] as num?)?.toDouble();
        final double? lng = (res['longitude'] as num?)?.toDouble();
        final String? address = res['address']?.toString();

        LatLng? resolved;
        if (lat != null && lng != null) {
          resolved = LatLng(lat, lng);
        } else if (address != null && address.isNotEmpty) {
          resolved = await _geocodeToLatLng(address);
        }

        if (resolved != null && mounted) {
          setState(() {
            _deliveryLocation = resolved;
            _deliveryAddress = address;
            _customerName = res['full_name']?.toString() ?? 'Customer';
          });
          debugPrint('LiveDelivery: Customer location resolved: $resolved');
        }
      }
    } catch (e) {
      debugPrint('LiveDelivery: Error loading customer: $e');
    }
  }

  Future<void> _loadCustomerPhone(String userId) async {
    try {
      final data = await _client.from('user_profiles').select('phone_number').eq('id', userId).maybeSingle();
      if (data != null && mounted) {
        setState(() => _customerPhone = data['phone_number']?.toString());
      }
    } catch (_) {}
  }

  Future<LatLng?> _geocodeToLatLng(String address) async {
    try {
      final results = await geocoding.locationFromAddress(address);
      if (results.isEmpty) return null;
      return LatLng(results.first.latitude, results.first.longitude);
    } catch (_) { return null; }
  }

  Future<void> openGoogleMaps(double lat, double lng) async {
    // travelmode=motorcycle is the standard for 2-wheelers in Google Maps URLs
    // 'mode=l' (lowercase L) is used for 2-wheeler/motorcycle in Google Maps native intents
    final String googleMapsUrl = 'google.navigation:q=$lat,$lng&mode=l'; 
    final Uri uri = Uri.parse(googleMapsUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        debugPrint('LiveDelivery: Launching Google Maps Native Intent: $googleMapsUrl');
        await launchUrl(uri);
      } else {
        debugPrint('LiveDelivery: Native intent failed, falling back to HTTPS URL');
        // mode=b is for bicycling, travelmode=motorcycle is for two-wheelers
        final String fallbackUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=motorcycle';
        final Uri fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch Google Maps or Browser';
        }
      }
    } catch (e) {
      debugPrint('LiveDelivery: Error launching navigation: $e');
      if (mounted) {
        final lp = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${lp.translate('could_not_open_maps')}: $e')),
        );
      }
    }
  }

  void navigateToDestination() {
    if (_order == null) return;
    
    final status = (_order!['status'] as String? ?? 'accepted').toLowerCase().trim();
    debugPrint('LiveDelivery: navigateToDestination current status: $status');
    LatLng? destination;
    
    // Statuses that mean we should go to the customer
    if (['picked_up', 'delivered', 'picked'].contains(status)) {
      destination = _deliveryLocation;
      debugPrint('LiveDelivery: Destination set to CUSTOMER: $destination');
    } else {
      // Statuses like 'accepted', 'ready', 'preparing' mean go to pharmacy
      destination = _pickupLocation;
      debugPrint('LiveDelivery: Destination set to PHARMACY: $destination');
    }

    if (destination != null) {
      openGoogleMaps(destination.latitude, destination.longitude);
    } else {
      debugPrint('LiveDelivery: Destination location NOT FOUND YET. (Pickup: $_pickupLocation, Delivery: $_deliveryLocation)');
      // If locations aren't loaded yet, try to load them again
      _ensureLocationsLoaded();
    }
  }

  Future<void> _updateDriverLocationInSupabase(LatLng position) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
      if (profile != null) {
        final updates = <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (profile.containsKey('last_location_update')) {
          updates['last_location_update'] = DateTime.now().toIso8601String();
        }
        if (profile.containsKey('latitude')) { 
          updates['latitude'] = position.latitude; 
          updates['longitude'] = position.longitude; 
        } else if (profile.containsKey('last_lat')) { 
          updates['last_lat'] = position.latitude; 
          updates['last_lng'] = position.longitude; 
        }
        await _client.from('profiles').update(updates).eq('id', user.id);
      }
    } catch (e) { debugPrint('LiveDelivery: Location update error: $e'); }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _handleArrivedAtPharmacy() async {
    // This method is now bypassed to simplify the flow
    _handlePickedUp();
  }

  Future<void> _handlePickedUp() async {
    if (_order == null) return;
    setState(() => _isUpdatingStatus = true);
    try { 
      // 1. Navigate to Pickup Confirmation Screen for proof
      final result = await Navigator.pushNamed(
        context,
        AppRoutes.pickupConfirmation,
        arguments: _order,
      );

      if (result == true && mounted) {
        // 2. Update status to 'picked_up' in database
        await _orderService.updateOrderStatus(_order!['id'], 'picked_up');
        setState(() {
          _lastProcessedStatus = 'picked_up';
          if (_order != null) {
            _order!['status'] = 'picked_up';
          }
        });
        
        // 3. FORCE fetch fresh customer location from Supabase
        final userId = _order!['user_id']?.toString();
        if (userId != null) {
          debugPrint('LiveDelivery: Refreshing customer location after pickup...');
          await _loadCustomerLocation(userId);
        }

        // 4. Removed auto-redirection to CUSTOMER
        if (_deliveryLocation == null) {
          debugPrint('LiveDelivery: Customer location missing after refresh, trying geocoding/fallback...');
          _ensureLocationsLoaded();
        }
      }
    }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _isUpdatingStatus = false); }
  }

  Future<void> _handleDelivered() async {
    if (_order == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.confirmDelivery,
      arguments: _order,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_order == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final lp = Provider.of<LanguageProvider>(context);
    final status = (_order!['status'] as String? ?? 'accepted').toLowerCase();
    // Simplified flow: Accepted/Ready/Preparing all go to Pharmacy pickup
    final bool isEnRouteToPharmacy = ['accepted', 'ready', 'preparing', 'assigned'].contains(status);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEnRouteToPharmacy 
            ? lp.translate('navigate_pharmacy') 
            : lp.translate('navigate_customer')
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentLocationMarker?.position ?? _pickupLocation ?? const LatLng(19.8540659, 75.3376926), zoom: 14),
            onMapCreated: (c) { _mapController = c; _ensureLocationsLoaded(); },
            markers: {
              if (_pickupLocation != null) Marker(markerId: const MarkerId('pickup'), position: _pickupLocation!, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), infoWindow: InfoWindow(title: 'Pharmacy', snippet: _pickupAddress)),
              if (_deliveryLocation != null) Marker(markerId: const MarkerId('delivery'), position: _deliveryLocation!, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), infoWindow: InfoWindow(title: 'Customer', snippet: _deliveryAddress)),
              if (_currentLocationMarker != null) _currentLocationMarker!,
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          _buildBottomCard(lp),
        ],
      ),
    );
  }

  Widget _buildBottomCard(LanguageProvider lp) {
    final status = (_order!['status'] as String? ?? 'accepted').toLowerCase();
    final bool isEnRouteToPharmacy = ['accepted', 'ready', 'preparing', 'assigned'].contains(status);
    
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 1.0, end: 0.0),
        curve: Curves.easeOutQuart,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value * 200),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnRouteToPharmacy ? 'Pickup From' : 'Deliver To',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEnRouteToPharmacy 
                          ? (_pharmacyName ?? 'Loading pharmacy...')
                          : (_customerName ?? 'Loading customer...'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEnRouteToPharmacy 
                          ? (_pickupAddress ?? 'Fetching address...')
                          : (_deliveryAddress ?? 'Fetching address...'),
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_customerPhone != null)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: IconButton.filled(
                        onPressed: () => _makePhoneCall(_customerPhone!),
                        icon: const Icon(Icons.call),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue,
                          fixedSize: const Size(54, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: navigateToDestination,
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text(
                        'NAVIGATE',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 54),
                        elevation: 4,
                        shadowColor: Colors.blue.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdatingStatus ? null : (isEnRouteToPharmacy ? _handlePickedUp : _handleDelivered),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 54),
                    elevation: 4,
                    shadowColor: Colors.green.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isUpdatingStatus
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEnRouteToPharmacy ? 'CONFIRM PICKUP' : 'CONFIRM DELIVERY',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isEnRouteToPharmacyStatic(String status) => ['accepted', 'assigned'].contains(status);
}
