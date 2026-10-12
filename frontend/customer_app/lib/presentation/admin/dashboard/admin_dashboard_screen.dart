import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/api_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      _dashboardFuture = ApiService.getAdminDashboard(userId);
    } else {
      _dashboardFuture = Future.value({'error': 'User ID not found'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF006D31)));
        } 
        
        if (snapshot.hasError || (snapshot.data != null && snapshot.data!['error'] != null)) {
          final error = snapshot.error ?? snapshot.data!['error'];
          if (error == 'User ID not found') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Session expired. Please log in again.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Go to Login'),
                  )
                ],
              ),
            );
          }
          return Center(child: Text('Error: $error'));
        }

        final data = snapshot.data!;
        final totalCustomers = data['totalCustomers'] ?? 0;
        final totalMerchants = data['totalMerchants'] ?? 0;
        final ordersToday = data['ordersToday'] ?? 0;
        final revenueToday = data['revenueToday'] ?? 0;
        final categoryShare = data['categoryShare'] as List<dynamic>? ?? [];
        final approvals = data['merchantApprovals'] as List<dynamic>? ?? [];

        final adminName = data['adminName'] ?? 'Admin';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OVERVIEW', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text('Good morning, $adminName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const Text("Here's what's happening across TownKart today.", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),
              
              // Metric Cards
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Total customers', '$totalCustomers', '+8.3%', Icons.people)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard('Total merchants', '$totalMerchants', '+12 this week', Icons.storefront)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard('Orders today', '$ordersToday', '+4.1%', Icons.receipt_long)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard('Revenue today', '₹${(double.tryParse(revenueToday.toString()) ?? 0.0) >= 1000 ? ((double.tryParse(revenueToday.toString()) ?? 0.0) / 1000).toStringAsFixed(2) + ' K' : (double.tryParse(revenueToday.toString()) ?? 0.0).toStringAsFixed(0)}', '+11.3%', Icons.trending_up)),
                ],
              ),
              const SizedBox(height: 24),
              
              // Charts Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _buildRevenueChart()),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _buildCategoryShareChart(categoryShare)),
                ],
              ),
              const SizedBox(height: 24),
              
              // Approvals Table
              _buildApprovalsTable(approvals),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF006D31), size: 16),
              ),
              const Icon(Icons.arrow_outward, color: Colors.grey, size: 16),
            ],
          ),
          const SizedBox(height: 24),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Color(0xFF006D31), fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    // Custom mocked bar chart based on screenshot
    final heights = [40, 50, 45, 60, 65, 60, 70, 75, 85, 90, 85, 100];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Last 12 weeks', style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('₹28.4 L', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                  const Text('+14.6% vs prev', style: TextStyle(color: Color(0xFF006D31), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(12, (index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: heights[index].toDouble(),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1B7A43),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('W${index + 1}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                );
              }),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryShareChart(List<dynamic> categoryShare) {
    return Container(
      height: 218,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Category share', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Text('Orders by category', style: TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 16),
          Expanded(
            child: categoryShare.isEmpty 
              ? const Center(child: Text('No data', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: categoryShare.length,
                  itemBuilder: (context, index) {
                    final item = categoryShare[index];
                    final name = item['name'];
                    // Mocking percentage since product_count is returned
                    final percentage = (5 - index) * 15; // fake distribution
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              Text('$percentage%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: percentage / 100.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF004D22),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsTable(List<dynamic> approvals) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Merchant approvals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${approvals.length} shops waiting for review', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: const Text('View all', style: TextStyle(color: Colors.black87, fontSize: 12)),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          approvals.isEmpty 
            ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No pending approvals', style: TextStyle(color: Colors.grey))))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  columns: const [
                    DataColumn(label: Text('SHOP')),
                    DataColumn(label: Text('TOWN')),
                    DataColumn(label: Text('CATEGORIES')),
                    DataColumn(label: Text('SELLER CODE')),
                    DataColumn(label: Text('SUBMITTED')),
                    DataColumn(label: Text('ACTION')),
                  ],
                  rows: approvals.map((shop) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(radius: 12, backgroundColor: const Color(0xFFE8F5E9), child: Text(shop['shop_name'][0], style: const TextStyle(color: Color(0xFF006D31), fontSize: 10))),
                              const SizedBox(width: 8),
                              Text(shop['shop_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                        DataCell(Text(shop['city'] ?? 'Unknown', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(shop['categories'] ?? 'Various', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(shop['seller_code'] ?? '-', style: const TextStyle(fontSize: 12))),
                        DataCell(Text('Recently', style: const TextStyle(fontSize: 12))), // Simplified date
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {},
                                child: const Text('Reject', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006D31),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  minimumSize: const Size(0, 30),
                                ),
                                child: const Text('Approve', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
        ],
      ),
    );
  }
}
