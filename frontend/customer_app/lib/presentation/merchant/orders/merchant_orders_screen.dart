import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class MerchantOrdersScreen extends ConsumerStatefulWidget {
  const MerchantOrdersScreen({super.key});

  @override
  ConsumerState<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends ConsumerState<MerchantOrdersScreen> {
  String _selectedStatus = 'Pending';
  late Future<Map<String, dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      _ordersFuture = ApiService.getMerchantOrders(userId);
    } else {
      _ordersFuture = Future.value({'error': 'User ID not found'});
    }
  }

  // Map display label to DB status value
  static const _statusMap = {
    'Pending': 'PLACED',
    'Preparing': 'ACCEPTED',
    'Ready': 'READY',
    'Completed': 'DELIVERED',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Orders', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF006D31)));
          } else if (snapshot.hasError || (snapshot.data != null && snapshot.data!['error'] != null)) {
            return Center(child: Text('Error: ${snapshot.error ?? snapshot.data!['error']}'));
          }

          final allOrders = snapshot.data!['orders'] as List<dynamic>? ?? [];

          // Compute live counts per status
          final counts = <String, int>{};
          for (final label in _statusMap.keys) {
            counts[label] = allOrders.where((o) => o['status'] == _statusMap[label]).length;
          }

          // Filter for selected status
          final dbStatus = _statusMap[_selectedStatus];
          final filteredOrders = allOrders.where((o) => o['status'] == dbStatus).toList();

          return Column(
            children: [
              // Filter chips bar
              Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: _statusMap.keys.map((label) {
                      final count = counts[label] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildFilterChip(label, count: count > 0 ? '$count' : null),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No $_selectedStatus orders', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final items = order['items'] as List<dynamic>? ?? [];
                          final itemStrings = items
                              .map((item) => '${item['quantity']} × ${item['product_name']} ${item['variant_name'] ?? ''}'.trim())
                              .toList();

                          final orderId = 'TK-${(order['id'] as String).substring(0, 8).toUpperCase()}';
                          final createdAt = (order['created_at'] ?? '').toString();
                          final timeStr = createdAt.length >= 16 ? createdAt.substring(11, 16) : '';

                          return _buildOrderCard(
                            orderId: orderId,
                            customerInfo: '${order['full_name']} · $timeStr',
                            price: '₹${order['total']}',
                            items: itemStrings,
                            status: order['status'] as String,
                            merchantOrderId: order['id'] as String,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, {String? count}) {
    bool isSelected = _selectedStatus == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF006D31) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.25) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String orderId,
    required String customerInfo,
    required String price,
    required List<String> items,
    required String status,
    required String merchantOrderId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(customerInfo, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Color(0xFF006D31), shape: BoxShape.circle),
                    ),
                    Expanded(child: Text(item, style: const TextStyle(color: Colors.black87, fontSize: 14))),
                  ],
                ),
              )).toList(),
            ),
          ),
          if (status == 'PLACED') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateOrderStatus(merchantOrderId, 'CANCELLED'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(merchantOrderId, 'ACCEPTED'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF006D31),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Accept order', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'ACCEPTED') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateOrderStatus(merchantOrderId, 'READY'),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text('Mark as Ready', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),
            ),
          ] else if (status == 'READY') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateOrderStatus(merchantOrderId, 'DELIVERED'),
                  icon: const Icon(Icons.done_all, color: Colors.white),
                  label: const Text('Mark as Completed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF006D31),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String merchantOrderId, String newStatus) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null) return;

    final result = await ApiService.updateMerchantOrderStatus(userId, merchantOrderId, newStatus);

    if (result.containsKey('error')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
    } else {
      // Refresh the orders list
      setState(() {
        _ordersFuture = ApiService.getMerchantOrders(userId);
      });
    }
  }
}
