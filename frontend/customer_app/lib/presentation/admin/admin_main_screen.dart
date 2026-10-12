import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/admin_tab_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'customers/admin_customers_screen.dart';
import 'merchants/admin_merchants_screen.dart';
import 'products/admin_products_screen.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _adminName = 'Loading...';
  String _adminDesignation = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      // Create a new method getAdminProfile in ApiService
      final response = await ApiService.getAdminProfile(userId);
      if (response['error'] == null && mounted) {
        setState(() {
          _adminName = response['adminName'] ?? 'Admin';
          _adminDesignation = response['adminDesignation'] ?? 'Administrator';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(adminTabProvider);

    final List<Widget> pages = [
      const AdminDashboardScreen(),
      const AdminCustomersScreen(),
      const AdminMerchantsScreen(),
      const AdminProductsScreen(),
      const Center(child: Text('Orders')),
      const Center(child: Text('Categories')),
      const Center(child: Text('Analytics')),
      const Center(child: Text('Settings')),
    ];

    final isDesktop = MediaQuery.of(context).size.width > 800;

    final sidebar = Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart, color: Color(0xFF006D31)),
              SizedBox(width: 8),
              Text('TownKart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const Text('Local • Fresh • Fast', style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 32),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12, bottom: 8),
                  child: Text('CONSOLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                ),
                _buildNavItem(ref, 0, Icons.dashboard_outlined, 'Dashboard'),
                _buildNavItem(ref, 1, Icons.people_outline, 'Customers'),
                _buildNavItem(ref, 2, Icons.storefront_outlined, 'Merchants'),
                _buildNavItem(ref, 3, Icons.inventory_2_outlined, 'Products'),
                _buildNavItem(ref, 4, Icons.receipt_long_outlined, 'Orders'),
                _buildNavItem(ref, 5, Icons.category_outlined, 'Categories'),
                _buildNavItem(ref, 6, Icons.analytics_outlined, 'Analytics'),
                _buildNavItem(ref, 7, Icons.settings_outlined, 'Settings'),
              ],
            ),
          ),
          
          // Profile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF006D31),
                  radius: 16,
                  child: Text(_adminName.isNotEmpty ? _adminName[0] : 'A', style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_adminName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(_adminDesignation, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18, color: Colors.grey),
                  onPressed: () => context.go('/landing'),
                )
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F7F5),
      drawer: isDesktop ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (isDesktop) sidebar,
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      if (!isDesktop)
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                        ),
                      Expanded(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Search merchants, orders, customers...',
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                              prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF006D31), size: 14),
                            SizedBox(width: 6),
                            Text('Live - All systems normal', style: TextStyle(color: Color(0xFF006D31), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.grey),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                
                // Page Content
                Expanded(
                  child: pages[selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(WidgetRef ref, int index, IconData icon, String title) {
    final selectedIdx = ref.watch(adminTabProvider);
    final isSelected = selectedIdx == index;
    
    return InkWell(
      onTap: () {
        ref.read(adminTabProvider.notifier).state = index;
        if (!MediaQuery.of(context).size.width.isFinite || MediaQuery.of(context).size.width <= 800) {
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            Navigator.of(context).pop();
          }
        }
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF006D31) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
