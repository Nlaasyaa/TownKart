import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import 'merchant_add_product_screen.dart';

class MerchantProductsScreen extends ConsumerStatefulWidget {
  const MerchantProductsScreen({super.key});

  @override
  ConsumerState<MerchantProductsScreen> createState() => _MerchantProductsScreenState();
}

class _MerchantProductsScreenState extends ConsumerState<MerchantProductsScreen> {
  String _selectedFilter = 'All';
  late Future<Map<String, dynamic>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      _productsFuture = ApiService.getMerchantProducts(userId);
    } else {
      _productsFuture = Future.value({'error': 'User ID not found'});
    }
  }

  void _refresh() {
    setState(() {
      _loadProducts();
    });
  }

  Future<void> _showEditDialog(Map<String, dynamic> product) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null) return;

    final priceCtrl = TextEditingController(text: '${product['selling_price'] ?? ''}');
    final mrpCtrl = TextEditingController(text: '${product['mrp'] ?? ''}');
    final stockCtrl = TextEditingController(text: '${product['stock_quantity'] ?? 0}');
    final minStockCtrl = TextEditingController(text: '${product['minimum_stock'] ?? 5}');
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Edit Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Text(
                '${product['product_name']} · ${product['variant_name'] ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _editField('Selling Price (₹)', priceCtrl, TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _editField('MRP (₹)', mrpCtrl, TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _editField('Stock Quantity', stockCtrl, TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _editField('Min. Stock Alert', minStockCtrl, TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setModalState(() => isSaving = true);
                          final result = await ApiService.updateMerchantProduct(
                            userId,
                            product['merchant_product_id'],
                            {
                              'sellingPrice': double.tryParse(priceCtrl.text) ?? 0,
                              'mrp': double.tryParse(mrpCtrl.text) ?? 0,
                              'minimumStock': int.tryParse(minStockCtrl.text) ?? 5,
                              'stockQuantity': int.tryParse(stockCtrl.text) ?? 0,
                            },
                          );
                          
                          if (!mounted) return;

                          if (result.containsKey('error')) {
                            setModalState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
                            );
                          } else {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Product updated!'), backgroundColor: Colors.green),
                            );
                            _refresh();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D31),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    priceCtrl.dispose();
    mrpCtrl.dispose();
    stockCtrl.dispose();
    minStockCtrl.dispose();
  }

  Widget _editField(String label, TextEditingController ctrl, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF006D31), width: 2)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> product) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Product', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Remove "${product['product_name']}" from your catalog? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await ApiService.deleteMerchantProduct(userId, product['merchant_product_id']);
      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product removed'), backgroundColor: Colors.green));
        _refresh();
      }
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> product) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null) return;

    final currentStatus = product['status'] ?? 'AVAILABLE';
    final newStatus = currentStatus == 'AVAILABLE' ? 'HIDDEN' : 'AVAILABLE';

    final result = await ApiService.toggleMerchantProductStatus(userId, product['merchant_product_id'], newStatus);
    if (mounted) {
      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      } else {
        _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Products', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MerchantAddProductScreen()),
                );
                if (result == true) _refresh();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D31),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: ['All', 'Available', 'Unavailable', 'Out of Stock']
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedFilter = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedFilter == f ? const Color(0xFF006D31) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: _selectedFilter == f ? Colors.white : Colors.grey.shade700,
                                  fontWeight: _selectedFilter == f ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF006D31)));
                } else if (snapshot.hasError || (snapshot.data != null && snapshot.data!['error'] != null)) {
                  return Center(child: Text('Error: ${snapshot.error ?? snapshot.data!['error']}'));
                }

                final allProducts = snapshot.data!['products'] as List<dynamic>? ?? [];

                // Apply filter
                final products = allProducts.where((p) {
                  final status = p['status'] ?? 'AVAILABLE';
                  final stock = p['stock_quantity'] ?? 0;
                  if (_selectedFilter == 'Available') return status == 'AVAILABLE';
                  if (_selectedFilter == 'Unavailable') return status == 'HIDDEN' || status == 'DISCONTINUED';
                  if (_selectedFilter == 'Out of Stock') return stock == 0;
                  return true;
                }).toList();

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No products found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final stock = product['stock_quantity'] ?? 0;
                    final isActive = (product['status'] ?? 'AVAILABLE') == 'AVAILABLE';
                    final mrp = product['mrp'];

                    Color stockColor = const Color(0xFFE8F5E9);
                    Color stockTextColor = const Color(0xFF006D31);
                    if (stock == 0) {
                      stockColor = const Color(0xFFFFEBEE);
                      stockTextColor = Colors.red;
                    } else if (stock < 10) {
                      stockColor = Colors.orange.shade50;
                      stockTextColor = Colors.orange.shade800;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? Colors.grey.shade200 : Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFFF0FDF4) : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.inventory_2, color: isActive ? const Color(0xFF006D31) : Colors.grey, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${product['product_name'] ?? 'Product'} · ${product['variant_name'] ?? ''}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isActive ? Colors.black : Colors.grey),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(product['category_name'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              // Toggle switch: ON = Available, OFF = Unavailable
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Switch(
                                    value: isActive,
                                    onChanged: (_) => _toggleStatus(product),
                                    activeColor: Colors.white,
                                    activeTrackColor: const Color(0xFF006D31),
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: Colors.grey.shade400,
                                  ),
                                  Text(
                                    isActive ? 'Available' : 'Unavailable',
                                    style: TextStyle(fontSize: 10, color: isActive ? const Color(0xFF006D31) : Colors.grey, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text('₹${product['selling_price']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                              if (mrp != null && mrp != product['selling_price']) ...[
                                const SizedBox(width: 8),
                                Text('MRP ₹$mrp', style: const TextStyle(color: Colors.grey, fontSize: 13, decoration: TextDecoration.lineThrough)),
                              ],
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: stockColor, borderRadius: BorderRadius.circular(12)),
                                child: Text('$stock in stock', style: TextStyle(color: stockTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const Spacer(),
                              // Edit button
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                color: Colors.blueGrey,
                                tooltip: 'Edit',
                                onPressed: () => _showEditDialog(product),
                              ),
                              // Delete button
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                color: Colors.red,
                                tooltip: 'Remove',
                                onPressed: () => _confirmDelete(product),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
