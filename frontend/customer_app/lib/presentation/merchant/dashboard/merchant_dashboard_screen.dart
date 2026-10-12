import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/merchant_tab_provider.dart';
import '../../../core/services/api_service.dart';

class MerchantDashboardScreen extends ConsumerStatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  ConsumerState<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends ConsumerState<MerchantDashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    // Wait until the end of the frame to read the provider if needed,
    // but ref.read can be used in initState.
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      _dashboardFuture = ApiService.getMerchantDashboard(userId);
    } else {
      _dashboardFuture = Future.value({'error': 'User ID not found'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF006D31)));
          } else if (snapshot.hasError || (snapshot.data != null && snapshot.data!['error'] != null)) {
            return Center(child: Text('Error: ${snapshot.error ?? snapshot.data!['error']}'));
          }

          final data = snapshot.data!;
          final shopName = data['shopName'] ?? 'Your Shop';
          final sellerCode = data['sellerCode'] ?? '---';
          final shopStatus = data['shopStatus'] ?? 'CLOSED';
          final todayRevenue = data['todayRevenue'] ?? 0;
          final todayOrders = data['todayOrders'] ?? 0;
          final pendingAction = data['pendingAction'] ?? 0;
          final productsCount = data['productsCount'] ?? 0;
          final recentOrders = data['recentPendingOrders'] ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Green Header Section
                Container(
                  padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
                  decoration: const BoxDecoration(
                    color: Color(0xFF006D31), // Dark Green
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MERCHANT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              shopName,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
                                  onPressed: () {},
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: shopStatus == 'OPEN' ? Colors.greenAccent : Colors.redAccent, 
                                        shape: BoxShape.circle
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(shopStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Seller code · $sellerCode', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 24),
                      // Revenue Summary Card inside header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TODAY', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 8),
                            Text('₹$todayRevenue', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(Icons.trending_up, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text('+9% vs yesterday', style: TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Overlapping Cards Section
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                          children: [
                            _buildMetricCard(
                              icon: Icons.receipt_long,
                              iconColor: const Color(0xFF006D31),
                              iconBgColor: const Color(0xFFE8F5E9),
                              title: 'Today\'s orders',
                              value: '$todayOrders',
                              trend: '+12%',
                              trendColor: const Color(0xFF0C831F),
                            ),
                            _buildMetricCard(
                              icon: Icons.notifications_active_outlined,
                              iconColor: Colors.orange,
                              iconBgColor: Colors.orange.shade50,
                              title: 'Pending action',
                              value: '$pendingAction',
                              trend: 'action',
                              trendColor: const Color(0xFF006D31),
                            ),
                            _buildMetricCard(
                              icon: Icons.inventory_2_outlined,
                              iconColor: Colors.grey.shade700,
                              iconBgColor: Colors.grey.shade100,
                              title: 'Products',
                              value: '$productsCount',
                              trend: '+3 this wk',
                              trendColor: const Color(0xFF0C831F),
                            ),
                            _buildMetricCard(
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: const Color(0xFF006D31),
                              iconBgColor: const Color(0xFFE8F5E9),
                              title: 'Revenue',
                              value: '₹$todayRevenue',
                              trend: '+9%',
                              trendColor: const Color(0xFF0C831F),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('Quick actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildQuickAction(Icons.add, 'Add product', onTap: () {
                              ref.read(merchantTabProvider.notifier).state = 1;
                            }),
                            _buildQuickAction(Icons.receipt_long, 'Manage\norders', onTap: () {
                              ref.read(merchantTabProvider.notifier).state = 2;
                            }),
                            _buildQuickAction(Icons.local_offer_outlined, 'Categories', onTap: () {
                              ref.read(merchantTabProvider.notifier).state = 3;
                            }),
                            _buildQuickAction(Icons.inventory_2_outlined, 'Inventory', onTap: () {
                              ref.read(merchantTabProvider.notifier).state = 1;
                            }),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pending orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              GestureDetector(
                                onTap: () {
                                  ref.read(merchantTabProvider.notifier).state = 2;
                                },
                                child: Text('See all', style: TextStyle(color: const Color(0xFF006D31), fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (recentOrders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: Text('No pending orders right now', style: TextStyle(color: Colors.grey))),
                          )
                        else
                          ...recentOrders.map<Widget>((order) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                                    child: Text('#${order['id'].toString().padLeft(2, '0').substring(0,2)}', style: const TextStyle(color: Color(0xFF006D31), fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('TK-${order['id'].toString().padLeft(4, '0').substring(0,4)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text('${order['item_count']} items · ₹${order['total']} · ${order['created_at'].toString().substring(11, 16)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {},
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          side: BorderSide(color: Colors.grey.shade300),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          foregroundColor: Colors.black87,
                                        ),
                                        child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          backgroundColor: const Color(0xFF006D31),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          minimumSize: const Size(0, 36),
                                        ),
                                        child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    required String trend,
    required Color trendColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Icon(Icons.arrow_outward, color: Colors.black54, size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(trend, style: TextStyle(color: trendColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: const Color(0xFF006D31)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
