import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/cart_provider.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  late Future<Map<String, dynamic>> _sellersFuture;

  @override
  void initState() {
    super.initState();
    _sellersFuture = ApiService.getSellersForVariant(widget.product['variant_id'].toString());
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product['product_name']?.toString() ?? 'Product',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${widget.product['shops_count'] ?? 0} merchants selling',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _sellersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0C831F)));
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data;
          if (data == null || data['error'] != null) {
            return Center(child: Text('Error: ${data?['error'] ?? 'Failed to load sellers'}'));
          }

          final sellers = (data['sellers'] as List<dynamic>?) ?? [];
          final lowestSeller = sellers.isNotEmpty ? sellers.first : null;
          final lowestSellerCode = lowestSeller?['seller_code']?.toString() ?? 'Unknown';

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ── Top Master Product Card ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.product['product_name'] ?? ''}\n${widget.product['variant_name'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.product['description']?.toString() ?? 'Premium quality · sourced from local mills',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '₹${widget.product['lowest_price'] ?? '0'} lowest',
                                  style: const TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('from $lowestSellerCode', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Section Title ──
              const Text('AVAILABLE AT', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              // ── Sellers List ──
              if (sellers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(child: Text('No sellers found for this product', style: TextStyle(color: Colors.grey))),
                ),
              
              for (int i = 0; i < sellers.length; i++)
                _buildSellerCard(sellers[i], i == 0, cartItems, cartNotifier),

              const SizedBox(height: 16),

              // ── Footer Note ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Color(0xFF0C831F), size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Merchant names are hidden. Only seller codes are shown to keep browsing fair.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSellerCard(Map<String, dynamic> seller, bool isBest, List<CartItem> cartItems, CartNotifier cartNotifier) {
    final merchantProductId = seller['merchant_product_id']?.toString() ?? '';
    final cartItemIdx = cartItems.indexWhere((i) => i.product['merchant_product_id']?.toString() == merchantProductId);
    final int quantityInCart = cartItemIdx >= 0 ? cartItems[cartItemIdx].quantity : 0;
    final stockQty = (seller['stock_quantity'] is int) ? seller['stock_quantity'] as int : int.tryParse(seller['stock_quantity']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Seller Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2ED),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.store, color: Color(0xFF0C831F), size: 22),
            ),
          ),
          const SizedBox(width: 16),
          // Seller Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        seller['seller_code']?.toString() ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isBest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C831F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('BEST', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.product['variant_name'] ?? ''} · ⏱ 12 min',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: stockQty > 5 ? const Color(0xFF0C831F) : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stockQty > 5 ? 'In stock' : 'Low stock',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Price + Add Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₹${seller['selling_price'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              if (quantityInCart == 0)
                ElevatedButton(
                  onPressed: () {
                    final cartProduct = {
                      'merchant_product_id': merchantProductId,
                      'product_name': widget.product['product_name'],
                      'variant_name': widget.product['variant_name'],
                      'shop_name': seller['seller_code']?.toString() ?? 'Unknown',
                      'selling_price': seller['selling_price'],
                    };
                    cartNotifier.addToCart(cartProduct);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C831F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16),
                      SizedBox(width: 4),
                      Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                )
              else
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C831F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => cartNotifier.decrementQuantity(merchantProductId),
                      ),
                      Text('$quantityInCart', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => cartNotifier.incrementQuantity(merchantProductId),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
