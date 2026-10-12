import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/cart_provider.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<Map<String, dynamic>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = ApiService.getCustomerProducts();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery in 12 minutes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Home - 14 Market Road, Pune', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 32),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF0C831F),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search "milk"',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF0C831F))),
                  );
                } else if (snapshot.hasError || (snapshot.data != null && snapshot.data!['error'] != null)) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(child: Text('Error: ${snapshot.error ?? snapshot.data!['error']}')),
                  );
                }

                final products = snapshot.data!['products'] as List<dynamic>? ?? [];

                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No products available right now.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Best sellers this week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          TextButton(
                            onPressed: () {},
                            child: const Text('See all', style: TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: product)),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2ED),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['product_name'] ?? 'Product',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(product['variant_name'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('₹${product['lowest_price']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                            Text('from ${product['shops_count']} shops', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
              },
              backgroundColor: const Color(0xFF0C831F),
              label: Text('View Cart ($cartCount item${cartCount > 1 ? 's' : ''})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
            )
          : null,
    );
  }
}
