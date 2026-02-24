import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/services/directions_service.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pinput/pinput.dart';

class LiveDeliveryScreen extends StatefulWidget {
  const LiveDeliveryScreen({super.key});

  @override
  State<LiveDeliveryScreen> createState() => _LiveDeliveryScreenState();
}

class _LiveDeliveryScreenState extends State<LiveDeliveryScreen> {
  GoogleMapController? _mapController;
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  final OrderService _orderService = OrderService();

  Marker? _currentLocationMarker;
  Set<Polyline> _polylines = const <Polyline>{};
  bool _isLoadingRoute = false;

  // TODO: Replace with a secure key injection method (e.g. --dart-define / remote config)
  static const String _googleDirectionsApiKey =
      'AIzaSyBoVAzIFrJiRytQZsdEuu0Abr3P1Eakb4U';

  @override
  void initState() {
    super.initState();
    _listenToLocation();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Could not launch the phone app
    }
  }

  void _listenToLocation() async {
    _locationSubscription = _location.onLocationChanged.listen((
      LocationData currentLocation,
    ) {
      if (_mapController != null &&
          currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                currentLocation.latitude!,
                currentLocation.longitude!,
              ),
              zoom: 15.5,
            ),
          ),
        );
        setState(() {
          _currentLocationMarker = Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(
              currentLocation.latitude!,
              currentLocation.longitude!,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: const InfoWindow(title: 'My Location'),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments == null || arguments is! Map<String, dynamic>) {
      return const Scaffold(body: Center(child: Text('Invalid order data.')));
    }
    final order = arguments;
    final pickupLocation = LatLng(
      order['pharmacy_lat'] ?? 37.422,
      order['pharmacy_lng'] ?? -122.084,
    );
    final deliveryLocation = LatLng(
      order['customer_lat'] ?? 37.432,
      order['customer_lng'] ?? -122.094,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Live Delivery')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pickupLocation,
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _loadRouteIfPossible(
                order: order,
                pickup: pickupLocation,
                delivery: deliveryLocation,
              );
            },
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickupLocation,
                infoWindow: const InfoWindow(title: 'Pickup'),
              ),
              Marker(
                markerId: const MarkerId('delivery'),
                position: deliveryLocation,
                infoWindow: const InfoWindow(title: 'Delivery'),
              ),
              if (_currentLocationMarker != null) _currentLocationMarker!,
            },
            polylines: _polylines,
          ),
          if (_isLoadingRoute)
            const Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: LinearProgressIndicator(),
            ),
          _buildBottomCard(context, order),
        ],
      ),
    );
  }

  Future<void> _loadRouteIfPossible({
    required Map<String, dynamic> order,
    required LatLng pickup,
    required LatLng delivery,
  }) async {
    if (_mapController == null) return;
    if (_googleDirectionsApiKey.isEmpty) return;

    final status = (order['status'] as String? ?? 'accepted').toLowerCase();

    // Route logic:
    // - before pickup: current -> pickup
    // - after pickup: pickup -> delivery
    final LatLng? current = _currentLocationMarker?.position;
    final LatLng origin;
    final LatLng destination;
    if (['picked_up', 'on_the_way'].contains(status)) {
      origin = pickup;
      destination = delivery;
    } else {
      origin = current ?? pickup;
      destination = pickup;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final directions = DirectionsService(apiKey: _googleDirectionsApiKey);
      final routePoints = await directions.getRoutePolyline(
        origin: origin,
        destination: destination,
      );

      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        width: 6,
        color: Colors.blue,
      );

      if (!mounted) return;
      setState(() {
        _polylines = {polyline};
      });

      await _fitMapToBounds(<LatLng>[origin, destination, ...routePoints]);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _polylines = const <Polyline>{};
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _fitMapToBounds(List<LatLng> points) async {
    if (_mapController == null) return;
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 56),
    );
  }

  Widget _buildBottomCard(BuildContext context, Map<String, dynamic> order) {
    final theme = Theme.of(context);
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator
            _buildDeliveryProgress('On the Way'),
            const SizedBox(height: 20),
            _buildEtaAndSla(context),
            const Divider(height: 32),
            _buildCustomerInfo(context, order),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPaymentStatus(context, order),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('PAYMENT'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showCompletionSheet(context, order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('COMPLETE'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryProgress(String currentStatus) {
    final steps = ['Accepted', 'Picked Up', 'On the Way', 'Delivered'];
    final currentIndex = steps.indexOf(currentStatus);

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isEven) {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex <= currentIndex;
          return Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? Colors.blue : Colors.grey.shade300,
            ),
          );
        } else {
          return Expanded(
            child: Container(
              height: 2,
              color: (index ~/ 2) < currentIndex
                  ? Colors.blue
                  : Colors.grey.shade300,
            ),
          );
        }
      }),
    );
  }

  void _showPaymentStatus(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Payment Transparency',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildPaymentRow(
              'Customer Payment',
              '₹${order['payout']}',
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildPaymentRow(
              'Status',
              'SUCCESSFUL',
              color: Colors.green,
              isBadge: true,
            ),
            const Divider(height: 32),
            _buildPaymentRow(
              'Pharmacy Share',
              '₹${order['payout']}',
              subText: 'Credited to Pharmacy',
            ),
            const SizedBox(height: 12),
            _buildPaymentRow(
              'Your Commission',
              '₹${order['commission_amount'] ?? 40.0}',
              subText: 'Instant Wallet Credit',
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Note: You do not need to collect any cash. Payments are handled digitally.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    bool isBadge = false,
    String? subText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isBold ? Colors.black : Colors.grey.shade700,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (subText != null)
              Text(
                subText,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
          ],
        ),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
      ],
    );
  }

  void _showCompletionSheet(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Complete Delivery',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Provide proof of delivery to finish',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildProofOption(
              context,
              'OTP Verification',
              Icons.pin_outlined,
              () => _verifyOtp(context, order),
            ),
            const SizedBox(height: 16),
            _buildProofOption(
              context,
              'Photo Capture',
              Icons.camera_alt_outlined,
              () => _capturePhoto(context, order),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProofOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _verifyOtp(BuildContext context, Map<String, dynamic> order) async {
    final TextEditingController otpController = TextEditingController();
    final theme = Theme.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ask the customer for the 4-digit code sent to their phone.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Pinput(
              length: 4,
              controller: otpController,
              autofocus: true,
              defaultPinTheme: PinTheme(
                width: 50,
                height: 50,
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 50,
                height: 50,
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onCompleted: (pin) => Navigator.pop(context, true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('VERIFY'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _finishOrder(context, order, 'otp');
    }
  }

  void _capturePhoto(BuildContext context, Map<String, dynamic> order) {
    // Mock photo capture
    _finishOrder(context, order, 'photo');
  }

  void _finishOrder(
    BuildContext context,
    Map<String, dynamic> order,
    String type,
  ) async {
    setState(() => _isLoading = true);
    final result = await _orderService.completeOrder(
      orderId: order['id'],
      proofType: type,
    );
    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      _showSuccessReceipt(context, result);
    }
  }

  void _showSuccessReceipt(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Delivery Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildPaymentRow('Earnings', '₹${data['payout']}'),
            const SizedBox(height: 8),
            _buildPaymentRow(
              'Peak Hour Bonus',
              '₹${data['bonus']}',
              color: Colors.blue,
            ),
            const Divider(height: 32),
            _buildPaymentRow(
              'Total Credited',
              '₹${data['total']}',
              isBold: true,
              color: Colors.green,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('BACK TO HOME'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isLoading = false;

  Widget _buildEtaAndSla(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESTIMATED TIME OF ARRIVAL',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            Text(
              '12:35 PM',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Column(
          children: [
            const CircularProgressIndicator(
              value: 0.75,
            ), // Example SLA progress
            const SizedBox(height: 4),
            Text(
              'SLA',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(BuildContext context, Map<String, dynamic> order) {
    return Row(
      children: [
        const CircleAvatar(child: Icon(Icons.person)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order['customer_name'] ?? 'N/A',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(order['customer_address'] ?? 'N/A'),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.green),
          onPressed: () => _makePhoneCall(order['customer_phone'] ?? ''),
        ),
      ],
    );
  }
}
