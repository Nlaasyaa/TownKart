import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/api_service.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  late Future<Map<String, dynamic>> _productsFuture;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      _productsFuture = ApiService.getAdminProducts(userId);
    } else {
      _productsFuture = Future.value({'error': 'User ID not found'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF006D31)));
        } else if (snapshot.hasError || (snapshot.data != null && snapshot.data!['error'] != null)) {
          return Center(child: Text('Error: ${snapshot.error ?? snapshot.data!['error']}'));
        }

        final products = snapshot.data!['products'] as List<dynamic>? ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Products', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text('${products.length} live listings • 3 flagged for review', style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
                    products.isEmpty 
                      ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No products found', style: TextStyle(color: Colors.grey))))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingTextStyle: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            columns: const [
                              DataColumn(label: Text('PRODUCT')),
                              DataColumn(label: Text('CATEGORY')),
                              DataColumn(label: Text('SELLER')),
                              DataColumn(label: Text('PRICE')),
                              DataColumn(label: Text('STOCK')),
                              DataColumn(label: Text('')),
                            ],
                            rows: products.map((p) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(radius: 12, backgroundColor: Colors.grey.shade100),
                                        const SizedBox(width: 8),
                                        Text(p['product_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(p['category_name'] ?? '-', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text('Various', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text('-', style: const TextStyle(fontSize: 12))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('Live', style: TextStyle(color: Color(0xFF006D31), fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ),
                                  DataCell(
                                    TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.red.shade200)),
                                      ),
                                      child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
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
}
