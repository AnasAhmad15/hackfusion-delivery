import 'package:flutter/material.dart';
import 'package:pharmaco_delivery_partner/features/home/home_screen.dart' show HomeScreen;
import 'package:pharmaco_delivery_partner/features/orders/orders_screen.dart';
import 'package:pharmaco_delivery_partner/features/earnings/earnings_screen.dart';
import 'package:pharmaco_delivery_partner/features/ratings/ratings_screen.dart';
import 'package:pharmaco_delivery_partner/features/profile/profile_screen.dart';
import 'package:pharmaco_delivery_partner/core/services/order_service.dart';
import 'package:pharmaco_delivery_partner/core/services/profile_service.dart';

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
        const RatingsScreen(),
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
    if (index == 4) {
      _fetchProfilePhoto(); // Refresh photo when profile tab is opened
    }
  }

  static const List<String> _titles = <String>[
    'Dashboard',
    'Orders',
    'My Earnings',
    'Ratings',
    'Profile & Account',
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('EXIT'),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_currentIndex]),
          actions: [
            if (_currentIndex != 4) // Don't show on profile screen itself
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () => _onItemTapped(4),
                  child: CircleAvatar(
                    backgroundImage: _profilePhotoUrl != null ? NetworkImage(_profilePhotoUrl!) : null,
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
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
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
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Earnings',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.star_outline),
              activeIcon: Icon(Icons.star),
              label: 'Ratings',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
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
