import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  late Future<Map<String, dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      _ordersFuture = ApiService.getOrderHistory(userId);
    } else {
      _ordersFuture = Future.value({'error': 'User not logged in'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0C831F)));
          }

          if (snapshot.hasError || (snapshot.data != null && snapshot.data!['error'] != null)) {
            return Center(child: Text('Error: ${snapshot.error ?? snapshot.data!['error']}'));
          }

          final orders = (snapshot.data!['orders'] as List<dynamic>?) ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text('No orders yet', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final items = (order['items'] as List<dynamic>?) ?? [];
              
              String dateStr = order['created_at'] ?? '';
              try {
                final date = DateTime.parse(dateStr).toLocal();
                final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
                final amPm = date.hour >= 12 ? 'PM' : 'AM';
                final min = date.minute.toString().padLeft(2, '0');
                dateStr = '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}, $hour:$min $amPm';
              } catch (_) {}

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order['order_id']?.toString().substring(0, 8) ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '₹${order['grand_total']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0C831F)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('${item['quantity']}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item['product_name']} ${item['variant_name'] != null ? ' - ${item['variant_name']}' : ''}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Sold by ${item['shop_name']}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${item['total_price']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: order['payment_status'] == 'PAID' ? Colors.green.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${order['payment_method']} · ${items.isNotEmpty ? (items[0]['order_status'] ?? 'PENDING').toString().toUpperCase() : 'PENDING'}',
                            style: TextStyle(
                              color: order['payment_status'] == 'PAID' ? Colors.green.shade700 : Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: View details or reorder
                          },
                          child: const Text('View Details', style: TextStyle(color: Color(0xFF0C831F))),
                        )
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
