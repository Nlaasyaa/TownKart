import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class MerchantAddProductScreen extends ConsumerStatefulWidget {
  const MerchantAddProductScreen({super.key});

  @override
  ConsumerState<MerchantAddProductScreen> createState() => _MerchantAddProductScreenState();
}

class _MerchantAddProductScreenState extends ConsumerState<MerchantAddProductScreen> {
  bool _isLoadingSubcategories = true;
  bool _isLoadingProducts = false;
  bool _isSubmitting = false;

  List<dynamic> _subcategories = [];
  List<dynamic> _masterProducts = [];

  String? _selectedSubcategoryId;
  String? _selectedVariantId;

  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController(text: '5');

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubcategories();
  }

  @override
  void dispose() {
    _sellingPriceController.dispose();
    _mrpController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubcategories() async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null) return;

    setState(() {
      _isLoadingSubcategories = true;
      _errorMessage = null;
    });

    final result = await ApiService.getMerchantSubcategories(userId);
    
    if (mounted) {
      if (result.containsKey('error')) {
        setState(() {
          _errorMessage = result['error'];
          _isLoadingSubcategories = false;
        });
      } else {
        setState(() {
          _subcategories = result['subcategories'] ?? [];
          _isLoadingSubcategories = false;
        });
      }
    }
  }

  Future<void> _fetchMasterProducts(String subcategoryId) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null) return;

    setState(() {
      _isLoadingProducts = true;
      _selectedVariantId = null;
      _masterProducts = [];
    });

    final result = await ApiService.getMerchantMasterProducts(userId, subcategoryId);
    
    if (mounted) {
      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'])));
        setState(() {
          _isLoadingProducts = false;
        });
      } else {
        setState(() {
          _masterProducts = result['products'] ?? [];
          _isLoadingProducts = false;
        });
      }
    }
  }

  Future<void> _submitProduct() async {
    if (_selectedVariantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }
    
    if (_sellingPriceController.text.isEmpty || _mrpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter prices')));
      return;
    }

    final userId = ref.read(authUserIdProvider);
    if (userId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    final productData = {
      'variantId': _selectedVariantId,
      'sellingPrice': double.tryParse(_sellingPriceController.text) ?? 0,
      'mrp': double.tryParse(_mrpController.text) ?? 0,
      'minimumStock': int.tryParse(_minStockController.text) ?? 5,
    };

    final result = await ApiService.addMerchantProduct(userId, productData);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // true indicates success so previous screen can refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        elevation: 0,
      ),
      body: _isLoadingSubcategories
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF006D31)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. Select Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Choose a subcategory'),
                            value: _selectedSubcategoryId,
                            items: _subcategories.map<DropdownMenuItem<String>>((sub) {
                              return DropdownMenuItem<String>(
                                value: sub['id'].toString(),
                                child: Text('${sub['category_name']} > ${sub['name']}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null && value != _selectedSubcategoryId) {
                                setState(() {
                                  _selectedSubcategoryId = value;
                                });
                                _fetchMasterProducts(value);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      const Text('2. Select Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _isLoadingProducts
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF006D31)))),
                              )
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text(_selectedSubcategoryId == null ? 'Select category first' : 'Choose a product'),
                                  value: _selectedVariantId,
                                  items: _masterProducts.map<DropdownMenuItem<String>>((prod) {
                                    return DropdownMenuItem<String>(
                                      value: prod['variant_id'].toString(),
                                      child: Text('${prod['product_name']} - ${prod['variant_name']}'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedVariantId = value;
                                    });
                                  },
                                ),
                              ),
                      ),
                      
                      const SizedBox(height: 32),
                      const Text('3. Pricing & Stock Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Selling Price (₹)',
                              controller: _sellingPriceController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              label: 'MRP (₹)',
                              controller: _mrpController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Minimum Stock Alert Level',
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                      ),
                      
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006D31),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Add to Catalog', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF006D31), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
