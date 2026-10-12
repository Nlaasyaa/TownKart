import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/api_service.dart';

class AdminMerchantsScreen extends ConsumerStatefulWidget {
  const AdminMerchantsScreen({super.key});

  @override
  ConsumerState<AdminMerchantsScreen> createState() => _AdminMerchantsScreenState();
}

class _AdminMerchantsScreenState extends ConsumerState<AdminMerchantsScreen> {
  late Future<Map<String, dynamic>> _merchantsFuture;

  @override
  void initState() {
    super.initState();
    _fetchMerchants();
  }

  void _fetchMerchants() {
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      setState(() {
        _merchantsFuture = ApiService.getAdminMerchants(userId);
      });
    } else {
      _merchantsFuture = Future.value({'error': 'User ID not found'});
    }
  }

  Future<void> _updateStatus(String merchantId, String status) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null) return;
    
    // Optimistic UI update or just show loading/refresh
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator())
    );
    
    final result = await ApiService.updateMerchantStatus(userId, merchantId, status);
    
    if (mounted) Navigator.pop(context); // Close dialog

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
      _fetchMerchants();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _merchantsFuture,
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

        final merchants = snapshot.data!['merchants'] as List<dynamic>? ?? [];
        final pendingCount = merchants.where((m) => m['approval_status'] == 'PENDING').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Merchants', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text('${merchants.length} total • $pendingCount pending approval', style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
                          _buildFilterChip('Approved', false),
                          const SizedBox(width: 8),
                          _buildFilterChip('Pending', false),
                          const SizedBox(width: 8),
                          _buildFilterChip('Suspended', false),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    merchants.isEmpty 
                      ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No merchants found', style: TextStyle(color: Colors.grey))))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingTextStyle: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            columns: const [
                              DataColumn(label: Text('SHOP')),
                              DataColumn(label: Text('SELLER CODE')),
                              DataColumn(label: Text('TOWN')),
                              DataColumn(label: Text('PRODUCTS')),
                              DataColumn(label: Text('GMV (30D)')),
                              DataColumn(label: Text('STATUS')),
                              DataColumn(label: Text('ACTIONS')),
                            ],
                            rows: merchants.map((m) {
                              final status = m['approval_status'] ?? 'UNKNOWN';
                              Color statusColor = Colors.grey;
                              Color statusBg = Colors.grey.shade100;
                              if (status == 'APPROVED') {
                                statusColor = const Color(0xFF006D31);
                                statusBg = const Color(0xFFE8F5E9);
                              } else if (status == 'PENDING') {
                                statusColor = Colors.orange.shade800;
                                statusBg = Colors.orange.shade50;
                              } else if (status == 'SUSPENDED') {
                                statusColor = Colors.red;
                                statusBg = const Color(0xFFFFEBEE);
                              }

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(radius: 12, backgroundColor: const Color(0xFF006D31), child: Text(m['shop_name'][0], style: const TextStyle(color: Colors.white, fontSize: 10))),
                                        const SizedBox(width: 8),
                                        Text(m['shop_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(m['seller_code'] ?? '-', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text(m['city'] ?? 'Unknown', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text('${m['products_count'] ?? 0}', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text(m['gmv'] != null ? '₹${m['gmv']}' : '-', style: const TextStyle(fontSize: 12))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (status == 'PENDING')
                                          IconButton(
                                            icon: Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 18),
                                            onPressed: () => _updateStatus(m['id'], 'APPROVED'),
                                            tooltip: 'Approve',
                                          ),
                                        if (status != 'SUSPENDED')
                                          IconButton(
                                            icon: Icon(Icons.block, color: Colors.red.shade300, size: 18),
                                            onPressed: () => _updateStatus(m['id'], 'SUSPENDED'),
                                            tooltip: 'Suspend',
                                          ),
                                      ],
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
