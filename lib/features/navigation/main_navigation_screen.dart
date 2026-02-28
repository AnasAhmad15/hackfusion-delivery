import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/features/home/home_screen.dart' show HomeScreen;
import 'package:pharmaco_delivery_partner/features/orders/orders_screen.dart';
import 'package:pharmaco_delivery_partner/features/earnings/earnings_screen.dart';
import 'package:pharmaco_delivery_partner/features/profile/profile_screen.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:pharmaco_delivery_partner/core/services/profile_service.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final OrderService _orderService = OrderService();
  final ProfileService _profileService = ProfileService();
  String? _profilePhotoUrl;

  List<Widget> get _widgetOptions => <Widget>[
        HomeScreen(onTabChange: _onItemTapped),
        const OrdersScreen(),
        const EarningsScreen(),
        const ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    _fetchProfilePhoto();
  }

  Future<void> _fetchProfilePhoto() async {
    try {
      final profile = await _profileService.getProfile();
      if (mounted && profile['profile_photo_url'] != null) {
        setState(() {
          _profilePhotoUrl = profile['profile_photo_url'] as String?;
        });
      }
    } catch (e) {
      // Ignore errors for this optional feature
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 3) {
      _fetchProfilePhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(lp.translate('exit_app')),
            content: Text(lp.translate('exit_confirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(lp.translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PharmacoTokens.error,
                  foregroundColor: PharmacoTokens.white,
                  minimumSize: const Size(100, 44),
                ),
                child: Text(lp.translate('exit')),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: PharmacoTokens.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            _getAppBarTitle(lp),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: PharmacoTokens.weightBold,
              color: PharmacoTokens.neutral900,
            ),
          ),
          actions: [
            if (_currentIndex != 3) // Hide profile icon when on Profile tab
              Padding(
                padding: const EdgeInsets.only(right: PharmacoTokens.space16),
                child: GestureDetector(
                  onTap: () => _onItemTapped(3),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: PharmacoTokens.primarySurface,
                    backgroundImage: _profilePhotoUrl != null ? NetworkImage(_profilePhotoUrl!) : null,
                    child: _profilePhotoUrl == null
                        ? const Icon(Icons.person_rounded, size: 20, color: PharmacoTokens.primaryBase)
                        : null,
                  ),
                ),
              ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: PharmacoTokens.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PharmacoTokens.space8,
                vertical: PharmacoTokens.space8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_outlined, Icons.home_rounded, 0),
                  _buildNavItem(Icons.list_alt_outlined, Icons.list_alt_rounded, 1, badgeStream: true),
                  _buildNavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 2),
                  _buildNavItem(Icons.person_outline_rounded, Icons.person_rounded, 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, int index, {bool badgeStream = false}) {
    final isSelected = _currentIndex == index;
    
    Widget baseIcon = Icon(
      isSelected ? activeIcon : icon,
      color: isSelected ? PharmacoTokens.primaryBase : PharmacoTokens.neutral400,
      size: 26,
    );

    Widget iconWidget = baseIcon;

    if (badgeStream) {
      iconWidget = StreamBuilder<int>(
        stream: _orderService.getAvailableOrdersCountStream(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Badge(
            label: Text(count.toString(), style: const TextStyle(fontSize: 10, color: PharmacoTokens.white)),
            isLabelVisible: count > 0,
            backgroundColor: PharmacoTokens.error,
            child: baseIcon,
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: PharmacoTokens.durationMedium,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? PharmacoTokens.space20 : PharmacoTokens.space12,
          vertical: PharmacoTokens.space8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? PharmacoTokens.primarySurface : Colors.transparent,
          borderRadius: PharmacoTokens.borderRadiusFull,
        ),
        child: iconWidget,
      ),
    );
  }

  String _getAppBarTitle(LanguageProvider lp) {
    switch (_currentIndex) {
      case 0:
        return lp.translate('home'); // or 'Dashboard'
      case 1:
        return lp.translate('orders');
      case 2:
        return lp.translate('earnings');
      case 3:
        return lp.translate('profile');
      default:
        return 'PharmaCo Delivery';
    }
  }
}
