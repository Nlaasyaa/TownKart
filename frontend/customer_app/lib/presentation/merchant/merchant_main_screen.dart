import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/merchant_tab_provider.dart';
import 'dashboard/merchant_dashboard_screen.dart';
import 'products/merchant_products_screen.dart';
import 'orders/merchant_orders_screen.dart';
import 'categories/merchant_categories_screen.dart';
import 'settings/merchant_settings_screen.dart';

class MerchantMainScreen extends ConsumerWidget {
  const MerchantMainScreen({super.key});

  final List<Widget> _screens = const [
    MerchantDashboardScreen(),
    MerchantProductsScreen(),
    MerchantOrdersScreen(),
    MerchantCategoriesScreen(),
    MerchantSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(merchantTabProvider);

    return Scaffold(
      body: _screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(merchantTabProvider.notifier).state = index;
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF006D31), // Dark Green
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Products'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.local_offer_outlined), activeIcon: Icon(Icons.local_offer), label: 'Categories'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
