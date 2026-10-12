import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/api_service.dart';

class MerchantCategoriesScreen extends ConsumerStatefulWidget {
  const MerchantCategoriesScreen({super.key});

  @override
  ConsumerState<MerchantCategoriesScreen> createState() => _MerchantCategoriesScreenState();
}

class _MerchantCategoriesScreenState extends ConsumerState<MerchantCategoriesScreen> {
  late Future<Map<String, dynamic>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      _categoriesFuture = ApiService.getMerchantCategories(userId);
    } else {
      _categoriesFuture = Future.value({'error': 'User ID not found'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF006D31)));
        } 
        
        if (snapshot.hasError || (snapshot.data != null && snapshot.data!['error'] != null)) {
          final error = snapshot.error ?? snapshot.data!['error'];
          if (error == 'User ID not found') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Session expired. Please log in again.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
                    child: const Text('Go to Login'),
                  )
                ],
              ),
            );
          }
          return Center(child: Text('Error: $error'));
        }

        final categories = snapshot.data!['categories'] as List<dynamic>? ?? [];
        final sellerCode = snapshot.data!['sellerCode'] ?? 'Unknown';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Categories', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text('Toggle which categories your shop is listed under.', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),
              
              if (categories.isEmpty)
                const Center(child: Text('No categories found', style: TextStyle(color: Colors.grey)))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isEnabled = category['is_enabled'] == 1 || category['is_enabled'] == true;
                    final productsCount = category['products_count'] ?? 0;
                    final code = category['code'] ?? 'C';
                    final name = category['name'] ?? 'Unknown';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0FDF4),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(color: Color(0xFF006D31), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEnabled ? '$productsCount products listed' : 'Not enabled',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isEnabled,
                            onChanged: (value) async {
                              final userId = ref.read(authUserIdProvider);
                              if (userId != null) {
                                final response = await ApiService.toggleMerchantCategory(userId, category['id'], value);
                                if (response['error'] != null) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['error'])));
                                  }
                                } else {
                                  setState(() {
                                    _categoriesFuture = ApiService.getMerchantCategories(userId);
                                  });
                                }
                              }
                            },
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF006D31),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey.shade300,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                    children: [
                      const TextSpan(text: 'Your seller code updates automatically when categories change. Current code: '),
                      TextSpan(text: sellerCode, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }
}
