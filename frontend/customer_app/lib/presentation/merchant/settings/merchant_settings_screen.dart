import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../auth/landing_screen.dart';

class MerchantSettingsScreen extends ConsumerStatefulWidget {
  const MerchantSettingsScreen({super.key});

  @override
  ConsumerState<MerchantSettingsScreen> createState() => _MerchantSettingsScreenState();
}

class _MerchantSettingsScreenState extends ConsumerState<MerchantSettingsScreen> {
  late Future<Map<String, dynamic>> _settingsFuture;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      _settingsFuture = ApiService.getMerchantSettings(userId);
    } else {
      _settingsFuture = Future.value({'error': 'User ID not found'});
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF006D31)));
          } else if (snapshot.hasError || (snapshot.data != null && snapshot.data!['error'] != null)) {
            return Center(child: Text('Error: ${snapshot.error ?? snapshot.data!['error']}'));
          }

          final data = snapshot.data!['settings'] ?? {};
          final shopName = data['shop_name'] ?? 'Your Shop';
          final sellerCode = data['seller_code'] ?? '---';
          final shopStatus = data['shop_status'] ?? 'CLOSED';
          final gstNumber = data['gst_number'] ?? 'Not provided';
          final ownerName = data['owner_name'] ?? 'Unknown';
          final address = data['address'] ?? 'No address';
          final workingHours = data['working_hours'] ?? 'Not specified';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Green Header
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 60),
                      decoration: const BoxDecoration(
                        color: Color(0xFF006D31), // Dark Green
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.storefront, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(shopName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Seller code · $sellerCode', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.power_settings_new, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(shopStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Accepting orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Turn off to pause new orders. Existing ones continue.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            Switch(
                              value: shopStatus == 'OPEN',
                              onChanged: (val) {},
                              activeColor: const Color(0xFF006D31),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // SHOP INFORMATION
                _buildSectionHeader('SHOP INFORMATION'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Shop name', shopName),
                      const Divider(height: 1),
                      _buildInfoRow('GST number', gstNumber),
                      const Divider(height: 1),
                      _buildInfoRow('Owner', ownerName, isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ADDRESS & HOURS
                _buildSectionHeader('ADDRESS & HOURS'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRowWithIcon(Icons.location_on_outlined, 'Address', address),
                      const Divider(height: 1),
                      _buildInfoRowWithIcon(Icons.access_time, 'Working hours', workingHours, isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // BUSINESS
                _buildSectionHeader('BUSINESS'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildBusinessRow(Icons.monetization_on_outlined, 'Subscription', 'TownKart Plus · Renews 24 Dec'),
                      const Divider(height: 1),
                      _buildBusinessRow(Icons.account_balance_wallet_outlined, 'Payouts', 'Bank · HDFC ••4821', isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // LOG OUT BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(authUserIdProvider.notifier).state = null;
                      ref.read(authRoleProvider.notifier).state = null;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LandingScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Log out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      backgroundColor: Colors.red.shade50,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Text(
        title,
        style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: isLast ? 16 : 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithIcon(IconData icon, String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: isLast ? 16 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Icon(icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessRow(IconData icon, String title, String subtitle, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: isLast ? 16 : 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF006D31), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
