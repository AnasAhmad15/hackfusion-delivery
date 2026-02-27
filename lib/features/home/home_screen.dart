import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/core/models/onboarding_profile.dart';
import 'package:pharmaco_delivery_partner/core/services/profile_service.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:pharmaco_delivery_partner/app/routes/app_routes.dart';
import 'package:pharmaco_delivery_partner/core/services/earnings_service.dart';
import 'package:pharmaco_delivery_partner/core/services/documents_service.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onTabChange;
  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<HomeScreen> {
  final ProfileService _profileService = ProfileService();
  final OrderService _orderService = OrderService();
  final EarningsService _earningsService = EarningsService();
  final DocumentsService _documentsService = DocumentsService();
  bool _isAvailable = false;
  bool _isProfileComplete = false;
  bool _isVerified = false;
  bool _isLoadingProfile = true;
  StreamSubscription? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _fetchInitialState();
  }

  Future<void> _fetchInitialState() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profileData = await _profileService.getProfile();
      final isVerified = await _documentsService.isVerificationComplete();
      
      if (mounted) {
        setState(() {
          _isProfileComplete = profileData['profile_completed'] ?? false;
          _isVerified = isVerified;
          _isAvailable = profileData['is_available'] ?? false;
          _isLoadingProfile = false;
        });
        if (_isAvailable && _isVerified) _listenForIncomingOrders();
      }
    } catch (e) {
      if (mounted) {
        final lp = Provider.of<LanguageProvider>(context, listen: false);
        setState(() => _isLoadingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lp.translate('failed_to_load_profile')}: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: lp.translate('retry'),
              textColor: Colors.white,
              onPressed: _fetchInitialState,
            ),
          ),
        );
      }
    }
  }

  void _toggleAvailability(bool hasActiveOrder) async {
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    if (!_isVerified) {
      _showVerificationRequiredSheet(lp);
      return;
    }

    if (hasActiveOrder && _isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lp.translate('cannot_go_offline_active_order')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newStatus = !_isAvailable;
    setState(() => _isAvailable = newStatus);
    
    try {
      await _profileService.updateAvailability(newStatus);
      if (newStatus) {
        _listenForIncomingOrders();
      } else {
        _orderSubscription?.cancel();
      }
    } catch (e) {
      setState(() => _isAvailable = !newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showVerificationRequiredSheet(LanguageProvider lp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_outlined, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              lp.translate('verification_pending'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              lp.translate('complete_verification_long_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.documentsVerification);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(lp.translate('complete_verification')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _listenForIncomingOrders() {
    _orderSubscription?.cancel();
    _orderSubscription = _orderService.getIncomingOrders().listen((orders) async {
      if (orders.isNotEmpty && _isAvailable && mounted) {
        // Check if there is already an active order before showing the incoming order screen
        final activeOrder = await _orderService.getActiveOrderStream().first;
        if (activeOrder == null && mounted) {
          Navigator.pushNamed(context, AppRoutes.incomingOrder, arguments: orders.first);
        } else {
          debugPrint('HomeScreen: Skipping incoming order because an active order already exists.');
        }
      }
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final lp = Provider.of<LanguageProvider>(context);

    return StreamBuilder<Map<String, dynamic>>(
      stream: _profileService.getProfileStream(),
      builder: (context, profileSnapshot) {
        final profileData = profileSnapshot.data;
        
        // Update local status variables from stream data
        if (profileSnapshot.hasData) {
          _isAvailable = profileData?['is_available'] ?? false;
          _isProfileComplete = profileData?['profile_completed'] ?? false;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: StreamBuilder<Map<String, dynamic>?>(
            stream: _orderService.getActiveOrderStream(),
            builder: (context, activeOrderSnapshot) {
              final activeOrder = activeOrderSnapshot.data;
              final bool hasActiveOrder = activeOrder != null;

              return SafeArea(
                child: RefreshIndicator(
                  onRefresh: _fetchInitialState,
                  child: ListView(
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      if (!_isVerified) _buildVerificationBanner(theme, lp),
                      _buildHeader(theme, hasActiveOrder, lp),
                      const SizedBox(height: 24),
                      if (hasActiveOrder) ...[
                        _buildActiveDeliveryCard(theme, activeOrder, lp),
                        const SizedBox(height: 24),
                      ],
                      _buildStatsGrid(theme, lp),
                      const SizedBox(height: 24),
                      _buildRecentActivitySection(theme, lp),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVerificationBanner(ThemeData theme, LanguageProvider lp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lp.translate('verification_required'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                ),
                Text(
                  lp.translate('complete_verification_desc'),
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.documentsVerification),
            child: Text(lp.translate('complete').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool hasActiveOrder, LanguageProvider lp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isAvailable ? lp.translate('online') : lp.translate('offline'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isAvailable ? Colors.green : Colors.grey,
              ),
            ),
            Text(
              _isAvailable ? lp.translate('waiting_for_orders') : lp.translate('go_online_to_earn'),
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        Switch.adaptive(
          value: _isAvailable,
          activeColor: Colors.green,
          onChanged: (_) => _isProfileComplete 
              ? _toggleAvailability(hasActiveOrder) 
              : _promptToCompleteProfile(lp),
        ),
      ],
    );
  }

  Widget _buildActiveDeliveryCard(ThemeData theme, Map<String, dynamic> order, LanguageProvider lp) {
    final statusKey = (order['status'] as String? ?? 'assigned').toLowerCase();
    final status = lp.translate(statusKey).toUpperCase();
    
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.orderDetails, arguments: order),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lp.translate('active_delivery'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Order #${order['id'].toString().substring(0, 8).toUpperCase()}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  order['customer_address'] ?? 'Loading address...',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.directions_run, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(lp.translate('tap_to_view_details'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme, LanguageProvider lp) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          theme,
          lp.translate('todays_earnings'),
          _earningsService.getTodaysEarningsStream(),
          Icons.account_balance_wallet_outlined,
          Colors.blue,
          isCurrency: true,
        ),
        _buildStatCard(
          theme,
          lp.translate('completed'),
          _orderService.getCompletedDeliveriesCount(),
          Icons.check_circle_outline,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, dynamic data, IconData icon, Color color, {bool isCurrency = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 4),
              if (data is Stream<double>)
                StreamBuilder<double>(
                  stream: data,
                  builder: (context, snapshot) => Text(
                    '${isCurrency ? '₹' : ''}${snapshot.data?.toStringAsFixed(isCurrency ? 0 : 0) ?? '0'}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              else if (data is Future<int>)
                FutureBuilder<int>(
                  future: data,
                  builder: (context, snapshot) => Text(
                    '${snapshot.data ?? 0}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(ThemeData theme, LanguageProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(lp.translate('recent_activity'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => widget.onTabChange(1),
              child: Text(lp.translate('view_all')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.history, color: Colors.grey[400], size: 48),
              const SizedBox(height: 12),
              Text(
                lp.translate('no_recent_activity'),
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              Text(
                lp.translate('complete_orders_to_see'),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _promptToCompleteProfile(LanguageProvider lp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lp.translate('complete_profile_to_go_online')),
        action: SnackBarAction(
          label: lp.translate('complete').toUpperCase(),
          onPressed: () async {
            final profile = await _profileService.getProfile();
            if (mounted) {
              Navigator.pushNamed(
                context, 
                AppRoutes.editPersonalDetails, 
                arguments: OnboardingProfile.fromMap(profile),
              );
            }
          },
        ),
      ),
    );
  }
}