import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _subcategories = [];
  List<dynamic> _products = [];
  int _selectedSubcatId = 0; // 0 means 'All'

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiService.fetchCategoryDetails(widget.categoryId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.containsKey('error')) {
          _error = response['error'];
        } else {
          _subcategories = response['subcategories'] ?? [];
          _products = response['products'] ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedProducts = _selectedSubcatId == 0
        ? _products
        : _products.where((p) => p['subcategory_id'] == _selectedSubcatId).toList();

    return Scaffold(
      backgroundColor: Colors.white,
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
            Text(widget.categoryName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
            if (!_isLoading && _error == null)
              Text(
                '${_products.length} products · ${_products.isEmpty ? 0 : _products.map((e) => e['shops_count']).reduce((a, b) => a > b ? a : b)} shops nearby',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.filter_list, color: Colors.black, size: 18),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
                    ],
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Pane: Subcategories
                    Container(
                      width: 90,
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: ListView(
                        children: [
                          _buildSubcatTab('All', 0),
                          ..._subcategories.map((sc) => _buildSubcatTab(sc['name'], sc['id'])),
                        ],
                      ),
                    ),

                    // Right Pane: Products Grid
                    Expanded(
                      child: displayedProducts.isEmpty
                          ? const Center(child: Text('No products available'))
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.65,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: displayedProducts.length,
                              itemBuilder: (context, index) {
                                return _buildProductCard(displayedProducts[index]);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSubcatTab(String name, int id) {
    final isSelected = _selectedSubcatId == id;
    return InkWell(
      onTap: () => setState(() => _selectedSubcatId = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        color: isSelected ? Colors.green.shade50.withOpacity(0.5) : Colors.transparent,
        child: Text(
          name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF0C831F) : Colors.black87,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final variantName = product['variant_name']?.toString() ?? '';

    return InkWell(
      onTap: () => context.push('/product/${product['variant_id']}', extra: product),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with Add button
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: double.infinity,
                    child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => context.push('/product/${product['variant_id']}', extra: product),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0C831F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text area
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['product_name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (variantName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      variantName,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('from', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(
                            '₹${product['lowest_price']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${product['shops_count']} shops',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
