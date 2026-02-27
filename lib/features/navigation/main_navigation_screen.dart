import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharmaco_delivery_partner/features/home/home_screen.dart' show HomeScreen;
import 'package:pharmaco_delivery_partner/features/orders/orders_screen.dart';
import 'package:pharmaco_delivery_partner/features/earnings/earnings_screen.dart';
import 'package:pharmaco_delivery_partner/features/profile/profile_screen.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:pharmaco_delivery_partner/core/services/profile_service.dart';
import 'package:pharmaco_delivery_partner/core/providers/language_provider.dart';

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
      _fetchProfilePhoto(); // Refresh photo when profile tab is opened
    }
  }

  List<String> _getTitles(LanguageProvider lp) => [
        lp.translate('dashboard'),
        lp.translate('orders'),
        lp.translate('my_earnings'),
        lp.translate('profile_account'),
      ];

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final titles = _getTitles(lp);
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
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: Text(lp.translate('exit')),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[_currentIndex]),
          actions: [
            if (_currentIndex != 3) // Don't show on profile screen itself
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () => _onItemTapped(3),
                  child: CircleAvatar(
                    backgroundImage: _profilePhotoUrl != null
                        ? NetworkImage(_profilePhotoUrl!)
                        : null,
                    child: _profilePhotoUrl == null ? const Icon(Icons.person) : null,
                  ),
                ),
              ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: lp.translate('home'),
            ),
            BottomNavigationBarItem(
              icon: StreamBuilder<int>(
                stream: _orderService.getAvailableOrdersCountStream(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Badge(
                    label: Text(count.toString()),
                    isLabelVisible: count > 0,
                    child: const Icon(Icons.list_alt_outlined),
                  );
                },
              ),
              activeIcon: StreamBuilder<int>(
                stream: _orderService.getAvailableOrdersCountStream(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Badge(
                    label: Text(count.toString()),
                    isLabelVisible: count > 0,
                    child: const Icon(Icons.list_alt),
                  );
                },
              ),
              label: lp.translate('orders'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              activeIcon: const Icon(Icons.account_balance_wallet),
              label: lp.translate('earnings'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: lp.translate('profile'),
            ),
          ],
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
