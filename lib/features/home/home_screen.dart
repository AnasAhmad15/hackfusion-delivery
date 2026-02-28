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
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

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
            backgroundColor: PharmacoTokens.error,
            action: SnackBarAction(label: lp.translate('retry'), textColor: Colors.white, onPressed: _fetchInitialState),
          ),
        );
      }
    }
  }

  void _toggleAvailability(bool hasActiveOrder) async {
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    if (!_isVerified) { _showVerificationRequiredSheet(lp); return; }

    if (hasActiveOrder && _isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lp.translate('cannot_go_offline_active_order')), backgroundColor: PharmacoTokens.warning),
      );
      return;
    }

    final newStatus = !_isAvailable;
    setState(() => _isAvailable = newStatus);
    
    try {
      await _profileService.updateAvailability(newStatus);
      if (newStatus) { _listenForIncomingOrders(); } else { _orderSubscription?.cancel(); }
    } catch (e) {
      setState(() => _isAvailable = !newStatus);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _showVerificationRequiredSheet(LanguageProvider lp) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(PharmacoTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 32, backgroundColor: PharmacoTokens.warningLight, child: const Icon(Icons.verified_user_outlined, size: 32, color: PharmacoTokens.warning)),
            const SizedBox(height: PharmacoTokens.space16),
            Text(lp.translate('verification_pending'), style: theme.textTheme.titleLarge),
            const SizedBox(height: PharmacoTokens.space8),
            Text(lp.translate('complete_verification_long_desc'), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500)),
            const SizedBox(height: PharmacoTokens.space24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.documentsVerification); },
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
  void dispose() { _orderSubscription?.cancel(); super.dispose(); }

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
        if (profileSnapshot.hasData) {
          _isAvailable = profileData?['is_available'] ?? false;
          _isProfileComplete = profileData?['profile_completed'] ?? false;
        }

        return Scaffold(
          backgroundColor: PharmacoTokens.neutral50,
          body: StreamBuilder<Map<String, dynamic>?>(
            stream: _orderService.getActiveOrderStream(),
            builder: (context, activeOrderSnapshot) {
              final activeOrder = activeOrderSnapshot.data;
              final bool hasActiveOrder = activeOrder != null;

              return SafeArea(
                child: RefreshIndicator(
                  color: PharmacoTokens.primaryBase,
                  onRefresh: _fetchInitialState,
                  child: ListView(
                    padding: const EdgeInsets.all(PharmacoTokens.space20),
                    children: [
                      if (!_isVerified) _buildVerificationBanner(theme, lp),
                      _buildHeader(theme, hasActiveOrder, lp),
                      const SizedBox(height: PharmacoTokens.space24),
                      if (hasActiveOrder) ...[
                        _buildActiveDeliveryCard(theme, activeOrder, lp),
                        const SizedBox(height: PharmacoTokens.space24),
                      ],
                      _buildStatsGrid(theme, lp),
                      const SizedBox(height: PharmacoTokens.space24),
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
      margin: const EdgeInsets.only(bottom: PharmacoTokens.space24),
      padding: const EdgeInsets.all(PharmacoTokens.space16),
      decoration: BoxDecoration(
        color: PharmacoTokens.warningLight,
        borderRadius: PharmacoTokens.borderRadiusMedium,
        border: Border.all(color: PharmacoTokens.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: PharmacoTokens.warning),
          const SizedBox(width: PharmacoTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lp.translate('verification_required'), style: theme.textTheme.bodySmall?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.warning)),
                Text(lp.translate('complete_verification_desc'), style: theme.textTheme.labelSmall?.copyWith(color: PharmacoTokens.neutral700)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.documentsVerification),
            child: Text(lp.translate('complete').toUpperCase()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool hasActiveOrder, LanguageProvider lp) {
    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space20),
      decoration: BoxDecoration(
        color: PharmacoTokens.white,
        borderRadius: PharmacoTokens.borderRadiusCard,
        boxShadow: PharmacoTokens.shadowZ1(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(
                    color: _isAvailable ? PharmacoTokens.success : PharmacoTokens.neutral400,
                    shape: BoxShape.circle,
                  )),
                  const SizedBox(width: PharmacoTokens.space8),
                  Text(
                    _isAvailable ? lp.translate('online') : lp.translate('offline'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: PharmacoTokens.weightBold,
                      color: _isAvailable ? PharmacoTokens.success : PharmacoTokens.neutral500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _isAvailable ? lp.translate('waiting_for_orders') : lp.translate('go_online_to_earn'),
                style: theme.textTheme.bodySmall?.copyWith(color: PharmacoTokens.neutral400),
              ),
            ],
          ),
          Switch.adaptive(
            value: _isAvailable,
            onChanged: (_) => _isProfileComplete ? _toggleAvailability(hasActiveOrder) : _promptToCompleteProfile(lp),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryCard(ThemeData theme, Map<String, dynamic> order, LanguageProvider lp) {
    final statusKey = (order['status'] as String? ?? 'assigned').toLowerCase();
    final status = lp.translate(statusKey).toUpperCase();
    
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [PharmacoTokens.primaryBase, PharmacoTokens.primaryDark, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: PharmacoTokens.borderRadiusCard,
        boxShadow: [
          BoxShadow(color: PharmacoTokens.primaryBase.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.orderDetails, arguments: order),
          borderRadius: PharmacoTokens.borderRadiusCard,
          child: Padding(
            padding: const EdgeInsets.all(PharmacoTokens.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lp.translate('active_delivery'), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: PharmacoTokens.weightBold, letterSpacing: 1.2)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: PharmacoTokens.space8, vertical: PharmacoTokens.space4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: PharmacoTokens.borderRadiusSmall),
                      child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: PharmacoTokens.weightBold)),
                    ),
                  ],
                ),
                const SizedBox(height: PharmacoTokens.space12),
                Text('Order #${order['id'].toString().substring(0, 8).toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: PharmacoTokens.weightBold)),
                const SizedBox(height: 4),
                Text(order['customer_address'] ?? 'Loading address...', style: const TextStyle(color: Colors.white70, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: PharmacoTokens.space16),
                Row(
                  children: [
                    const Icon(Icons.directions_run, color: Colors.white, size: 18),
                    const SizedBox(width: PharmacoTokens.space8),
                    Text(lp.translate('tap_to_view_details'), style: const TextStyle(color: Colors.white, fontWeight: PharmacoTokens.weightMedium)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
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
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: PharmacoTokens.space16, crossAxisSpacing: PharmacoTokens.space16, childAspectRatio: 1.5,
      children: [
        _buildStatCard(theme, lp.translate('todays_earnings'), _earningsService.getTodaysEarningsStream(), Icons.account_balance_wallet_outlined, PharmacoTokens.primaryBase, isCurrency: true),
        _buildStatCard(theme, lp.translate('completed'), _orderService.getCompletedDeliveriesCount(), Icons.check_circle_outline_rounded, PharmacoTokens.success),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, dynamic data, IconData icon, Color color, {bool isCurrency = false}) {
    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        borderRadius: PharmacoTokens.borderRadiusCard,
        boxShadow: PharmacoTokens.shadowZ1(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(PharmacoTokens.space8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: PharmacoTokens.borderRadiusSmall),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: PharmacoTokens.neutral400)),
              const SizedBox(height: 2),
              if (data is Stream<double>)
                StreamBuilder<double>(
                  stream: data,
                  builder: (context, snapshot) => Text(
                    '${isCurrency ? '₹' : ''}${snapshot.data?.toStringAsFixed(0) ?? '0'}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold),
                  ),
                )
              else if (data is Future<int>)
                FutureBuilder<int>(
                  future: data,
                  builder: (context, snapshot) => Text(
                    '${snapshot.data ?? 0}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold),
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
            Text(lp.translate('recent_activity'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
            TextButton(onPressed: () => widget.onTabChange(1), child: Text(lp.translate('view_all'))),
          ],
        ),
        const SizedBox(height: PharmacoTokens.space8),
        Container(
          padding: const EdgeInsets.all(PharmacoTokens.space24),
          decoration: BoxDecoration(
            color: PharmacoTokens.white,
            borderRadius: PharmacoTokens.borderRadiusCard,
            boxShadow: PharmacoTokens.shadowZ1(),
          ),
          child: Column(
            children: [
              Icon(Icons.history_rounded, color: PharmacoTokens.neutral300, size: 48),
              const SizedBox(height: PharmacoTokens.space12),
              Text(lp.translate('no_recent_activity'), style: theme.textTheme.bodyMedium?.copyWith(color: PharmacoTokens.neutral500, fontWeight: PharmacoTokens.weightMedium)),
              Text(lp.translate('complete_orders_to_see'), style: theme.textTheme.labelSmall?.copyWith(color: PharmacoTokens.neutral400)),
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
              Navigator.pushNamed(context, AppRoutes.editPersonalDetails, arguments: OnboardingProfile.fromMap(profile));
            }
          },
        ),
      ),
    );
  }
}