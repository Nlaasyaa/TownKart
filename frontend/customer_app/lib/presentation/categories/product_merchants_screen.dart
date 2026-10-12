import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/cart_provider.dart';

class ProductMerchantsScreen extends ConsumerStatefulWidget {
  final String variantId;
  final dynamic productData;

  const ProductMerchantsScreen({
    super.key,
    required this.variantId,
    required this.productData,
  });

  @override
  ConsumerState<ProductMerchantsScreen> createState() => _ProductMerchantsScreenState();
}

class _ProductMerchantsScreenState extends ConsumerState<ProductMerchantsScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _sellers = [];

  @override
  void initState() {
    super.initState();
    _fetchSellers();
  }

  Future<void> _fetchSellers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiService.fetchSellersForVariant(widget.variantId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.containsKey('error')) {
          _error = response['error'];
        } else {
          _sellers = response['sellers'] ?? [];
        }
      });
    }
  }

  void _addToCart(dynamic seller) {
    final product = widget.productData;
    final cartProduct = {
      'merchant_product_id': seller['merchant_product_id'].toString(),
      'product_name': product['product_name'],
      'variant_name': product['variant_name'],
      'selling_price': seller['selling_price'],
      'mrp': seller['mrp'],
      'seller_code': seller['seller_code'],
    };
    ref.read(cartProvider.notifier).addToCart(cartProduct);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['product_name']} added to cart!'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0C831F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.productData;
    final variantName = product['variant_name']?.toString() ?? '';

    // Derive lowest price and best seller dynamically from sellers list
    dynamic bestSeller;
    double? lowestPrice;
    if (_sellers.isNotEmpty) {
      bestSeller = _sellers.reduce((a, b) =>
          double.parse(a['selling_price'].toString()) < double.parse(b['selling_price'].toString()) ? a : b);
      lowestPrice = double.parse(bestSeller['selling_price'].toString());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['product_name'] ?? 'Product',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
            ),
            Text(
              _isLoading ? 'Loading...' : '${_sellers.length} merchants selling',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Product Header ──
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.image_outlined, color: Colors.grey, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['product_name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        // Show variant name (quantity) in the header
                        Text(
                          variantName.isNotEmpty ? variantName : 'Premium quality • locally sourced',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                lowestPrice != null ? '₹${lowestPrice.toStringAsFixed(2)} lowest' : '—',
                                style: const TextStyle(
                                  color: Color(0xFF0C831F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (bestSeller != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                'from Seller ${bestSeller['seller_code']}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Divider ──
          SliverToBoxAdapter(
            child: Container(height: 8, color: const Color(0xFFF0F0F0)),
          ),

          // ── "AVAILABLE AT" label ──
          if (!_isLoading && _error == null && _sellers.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'AVAILABLE AT',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

          // ── Sellers List ──
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _fetchSellers, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_sellers.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No sellers available for this product')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final seller = _sellers[index];
                  final sellerPrice = double.parse(seller['selling_price'].toString());
                  final isBest = lowestPrice != null && sellerPrice == lowestPrice;
                  final isLowStock = (seller['stock_quantity'] ?? 10) < 5;
                  final deliveryMin = 10 + (index * 4) + 2;

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Delivery time circle
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.green.shade200, width: 3),
                            ),
                            child: Center(
                              child: Text(
                                '$deliveryMin',
                                style: const TextStyle(
                                  color: Color(0xFF0C831F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Seller info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Seller ${seller['seller_code']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (isBest) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0C831F),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'BEST',
                                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Show variant name (e.g. "5 kg") instead of hardcoded "1 unit"
                                    Text(
                                      variantName.isNotEmpty ? variantName : '1 unit',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    Text(' · ', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                    Icon(Icons.timer_outlined, size: 11, color: Colors.grey.shade600),
                                    const SizedBox(width: 2),
                                    Text('$deliveryMin min', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: isLowStock ? Colors.orange : const Color(0xFF0C831F),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isLowStock ? 'Low stock' : 'In stock',
                                      style: TextStyle(
                                        color: isLowStock ? Colors.orange.shade700 : Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Price + Add/Quantity button
                          Builder(builder: (context) {
                            final cart = ref.watch(cartProvider);
                            final merchantProductId = seller['merchant_product_id'].toString();
                            final cartItem = cart.where((item) =>
                              item.product['merchant_product_id'] == merchantProductId
                            ).firstOrNull;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${seller['selling_price']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                if (cartItem == null)
                                  ElevatedButton.icon(
                                    onPressed: () => _addToCart(seller),
                                    icon: const Icon(Icons.add, size: 14),
                                    label: const Text('Add', style: TextStyle(fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0C831F),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      elevation: 0,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  )
                                else
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0C831F),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => ref.read(cartProvider.notifier).decrementQuantity(merchantProductId),
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Icon(Icons.remove, color: Colors.white, size: 14),
                                          ),
                                        ),
                                        Text(
                                          '${cartItem.quantity}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        InkWell(
                                          onTap: () => ref.read(cartProvider.notifier).incrementQuantity(merchantProductId),
                                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Icon(Icons.add, color: Colors.white, size: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _sellers.length,
              ),
            ),

          // ── Disclaimer footer ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: Color(0xFF0C831F), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Merchant names are hidden. Only seller codes are shown to keep browsing fair.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
