import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  List<dynamic> _categories = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiService.fetchCategories();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.containsKey('error')) {
          _error = response['error'];
        } else {
          _categories = response['categories'] ?? [];
        }
      });
    }
  }

  // Maps backend category name to an IconData and background color
  Map<String, dynamic> _getCategoryStyle(String name) {
    final n = name.toLowerCase();
    if (n.contains('grocer')) {
      return {'icon': Icons.shopping_cart, 'color': Colors.blue.shade50, 'iconColor': Colors.blue};
    } else if (n.contains('stationery')) {
      return {'icon': Icons.edit, 'color': Colors.orange.shade50, 'iconColor': Colors.orange};
    } else if (n.contains('dairy')) {
      return {'icon': Icons.local_drink, 'color': Colors.lightBlue.shade50, 'iconColor': Colors.lightBlue};
    } else if (n.contains('fruit')) {
      return {'icon': Icons.apple, 'color': Colors.red.shade50, 'iconColor': Colors.red};
    } else if (n.contains('veg')) {
      return {'icon': Icons.eco, 'color': Colors.green.shade50, 'iconColor': Colors.green};
    }
    return {'icon': Icons.category, 'color': Colors.grey.shade100, 'iconColor': Colors.grey};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search across categories...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        ),
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
                      ElevatedButton(
                        onPressed: _fetchCategories,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : _categories.isEmpty
                  ? const Center(child: Text('No categories found'))
                  : RefreshIndicator(
                      onRefresh: _fetchCategories,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final style = _getCategoryStyle(cat['name']);
                          
                          return InkWell(
                            onTap: () {
                              context.push('/category/${cat['id']}', extra: cat['name']);
                            },
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
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: style['color'],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(style['icon'], color: style['iconColor'], size: 32),
                                  ),
                                  const Spacer(),
                                  Text(
                                    cat['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${cat['product_count']} products',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
