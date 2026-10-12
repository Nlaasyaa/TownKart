import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';

class MerchantSignupScreen extends StatefulWidget {
  const MerchantSignupScreen({super.key});

  @override
  State<MerchantSignupScreen> createState() => _MerchantSignupScreenState();
}

class _MerchantSignupScreenState extends State<MerchantSignupScreen> {
  bool _isLoading = false;
  String? _sellerCode;
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final List<String> _selectedCategories = [];

  Future<void> _handleSubmit() async {
    if (_ownerNameController.text.isEmpty || 
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields including password')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await ApiService.registerMerchant(
      ownerName: _ownerNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      gstNumber: _gstController.text,
      shopName: _shopNameController.text,
      shopAddress: _shopAddressController.text,
      password: _passwordController.text,
      categories: _selectedCategories,
    );

    setState(() {
      _isLoading = false;
    });

    if (response['error'] != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['error'])));
      }
    } else {
      if (mounted) {
        setState(() {
          _sellerCode = response['sellerCode'] ?? _sellerCode;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop registration submitted successfully!')));
        // Typically route to merchant dashboard here
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 24.0),
            child: Center(child: Text('Step 2 of 3', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Open your shop', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            const Text('Tell us about your business — takes under 2 minutes.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildTextField('OWNER NAME', 'Enter owner name', _ownerNameController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField('EMAIL', 'Enter email address', _emailController),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField('PHONE', 'Enter 10-digit number', _phoneController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PASSWORD', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          filled: false,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField('GST NUMBER', 'Enter GST Number', _gstController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField('SHOP NAME', 'Enter shop name', _shopNameController),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('SHOP ADDRESS', 'Enter full shop address', _shopAddressController),
            const SizedBox(height: 24),
            const Text('CHOOSE CATEGORIES', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip('Dairy', 'A'),
                _buildChip('Groceries', 'B'),
                _buildChip('Stationery', 'C'),
                _buildChip('Fruits', 'D'),
                _buildChip('Vegetables', 'E'),
              ],
            ),
            const SizedBox(height: 32),
            if (_sellerCode != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  border: Border.all(color: const Color(0xFF006D31).withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF006D31), size: 16),
                        SizedBox(width: 8),
                        Text('SELLER CODE GENERATED', style: TextStyle(color: Color(0xFF006D31), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_sellerCode!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black)),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                        children: [
                          TextSpan(text: _sellerCode!.substring(0, 4), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          const TextSpan(text: ' - unique id  ·  '),
                          TextSpan(text: _sellerCode!.substring(4), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          const TextSpan(text: ' - Initializing'),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            if (_sellerCode == null)
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D31),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit for approval', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            if (_sellerCode != null)
              ElevatedButton(
                onPressed: () => context.go('/main'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D31),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('Continue to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: false,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, String letter) {
    final isSelected = _selectedCategories.contains(label);
    
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategories.remove(label);
          } else {
            _selectedCategories.add(label);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF006D31) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF006D31) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Text(letter, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey)),
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
