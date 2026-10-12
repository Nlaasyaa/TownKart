import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import 'addresses_screen.dart';
import 'order_history_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      _profileFuture = ApiService.getCustomerProfile(userId);
    } else {
      _profileFuture = Future.value({'error': 'User not logged in'});
    }
  }

  void _logout() {
    ref.read(authUserIdProvider.notifier).state = null;
    context.go('/landing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0C831F)));
          }

          if (snapshot.hasError || (snapshot.data != null && snapshot.data!['error'] != null)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error ?? snapshot.data!['error']}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text('Log out'),
                  )
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final fullName = (data['fullName'] ?? 'User').toString();
          final email = (data['email'] ?? '').toString();
          final phone = (data['phone'] ?? '').toString();
          final totalOrders = data['totalOrders'] ?? 0;
          
          final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Top Green Section
                Container(
                  color: const Color(0xFF0C831F),
                  padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROFILE',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: Text(
                              initial,
                              style: const TextStyle(color: Color(0xFF0C831F), fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  phone.isNotEmpty && email.isNotEmpty
                                      ? '$phone • $email'
                                      : phone.isNotEmpty ? phone : email,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '$totalOrders ${totalOrders == 1 ? 'Order' : 'Orders'} placed',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // List Items
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildListItem(
                        icon: Icons.location_on_outlined,
                        title: 'Saved addresses',
                        subtitle: 'Manage your delivery addresses',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressesScreen()));
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildListItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'Order history',
                        subtitle: 'View all past orders',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildListItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Payments & wallet',
                        subtitle: 'UPI · TownCoins · Cards',
                        onTap: () {},
                      ),
                      const SizedBox(height: 16),
                      _buildListItem(
                        icon: Icons.card_giftcard_outlined,
                        title: 'Refer & earn',
                        subtitle: 'Get ₹100 for each friend',
                        onTap: () {},
                      ),
                      const SizedBox(height: 16),
                      _buildListItem(
                        icon: Icons.headset_mic_outlined,
                        title: 'Support',
                        subtitle: 'Chat with us 24x7',
                        onTap: () {},
                      ),
                      const SizedBox(height: 32),
                      
                      // Log Out Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Color(0xFFE53935), size: 20),
                          label: const Text('Log out', style: TextStyle(color: Color(0xFFE53935), fontSize: 16, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE53935)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            backgroundColor: const Color(0xFFFFF5F5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'TownKart v1.0.0',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2ED),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF0C831F)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
