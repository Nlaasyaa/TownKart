import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/api_service.dart';

class AdminCustomersScreen extends ConsumerStatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  ConsumerState<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<AdminCustomersScreen> {
  late Future<Map<String, dynamic>> _customersFuture;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      _customersFuture = ApiService.getAdminCustomers(userId);
    } else {
      _customersFuture = Future.value({'error': 'User ID not found'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _customersFuture,
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

        final customers = snapshot.data!['customers'] as List<dynamic>? ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Customers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text('${customers.length} total customers', style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildFilterChip('All', true),
                          const SizedBox(width: 8),
                          _buildFilterChip('Active', false),
                          const SizedBox(width: 8),
                          _buildFilterChip('New', false),
                          const SizedBox(width: 8),
                          _buildFilterChip('VIP', false),
                          const SizedBox(width: 8),
                          _buildFilterChip('Blocked', false),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    customers.isEmpty 
                      ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No customers found', style: TextStyle(color: Colors.grey))))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingTextStyle: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            columns: const [
                              DataColumn(label: Text('CUSTOMER')),
                              DataColumn(label: Text('PHONE')),
                              DataColumn(label: Text('TOWN')),
                              DataColumn(label: Text('ORDERS')),
                              DataColumn(label: Text('LIFETIME SPEND')),
                              DataColumn(label: Text('STATUS')),
                              DataColumn(label: Text('')),
                            ],
                            rows: customers.map((c) {
                              final totalOrders = c['total_orders'] ?? 0;
                              final lifetimeSpend = c['lifetime_spend'] ?? 0;
                              return DataRow(
                                cells: [
                                  DataCell(Text(c['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataCell(Text(c['phone'] ?? '-', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text(c['city'] ?? 'Unknown', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text('$totalOrders', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text('₹${lifetimeSpend.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('Active', style: TextStyle(color: Color(0xFF006D31), fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ),
                                  DataCell(
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text('View', style: TextStyle(color: Colors.blue, fontSize: 12)),
                                    )
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF006D31) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade600,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}
