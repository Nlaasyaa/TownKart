import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    // Android emulator uses 10.0.2.2 to access localhost
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static Future<Map<String, dynamic>> registerCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register-customer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> registerMerchant({
    required String ownerName,
    required String email,
    required String phone,
    required String gstNumber,
    required String shopName,
    required String shopAddress,
    required String password,
    required List<String> categories,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register-merchant'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ownerName': ownerName,
          'email': email,
          'phone': phone,
          'gstNumber': gstNumber,
          'shopName': shopName,
          'shopAddress': shopAddress,
          'password': password,
          'categories': categories,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String contact,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact': contact,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendOtp({
    required String contact,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact': contact,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/customer/categories'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to fetch categories (HTTP ${response.statusCode})'};
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> fetchCategoryDetails(String categoryId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/customer/categories/$categoryId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to fetch category details (HTTP ${response.statusCode})'};
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> fetchSellersForVariant(String variantId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/customer/master-variants/$variantId/sellers'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to fetch sellers (HTTP ${response.statusCode})'};
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMerchantDashboard(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/merchant/dashboard/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch dashboard data (HTTP ${response.statusCode})'};
      } catch (_) {
        return {'error': 'Failed to fetch dashboard data (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMerchantProducts(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/merchant/products/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch products (HTTP ${response.statusCode})'};
      } catch (_) {
        return {'error': 'Failed to fetch products (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMerchantOrders(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/merchant/orders/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch orders (HTTP ${response.statusCode})'};
      } catch (_) {
        return {'error': 'Failed to fetch orders (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMerchantSettings(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/merchant/settings/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch settings (HTTP ${response.statusCode})'};
      } catch (_) {
        return {'error': 'Failed to fetch settings (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMerchantCategories(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/merchant/categories/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch categories (HTTP ${response.statusCode})'};
      } catch (_) {
        return {'error': 'Failed to fetch categories (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> toggleMerchantCategory(String userId, int categoryId, bool isEnabled) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/merchant/categories/$userId/$categoryId/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isEnabled': isEnabled}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to toggle category'};
      } catch (_) {
        return {'error': 'Failed to toggle category'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMerchantSubcategories(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/merchant/subcategories/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch subcategories'};
      } catch (_) {
        return {'error': 'Failed to fetch subcategories'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMerchantMasterProducts(String userId, String subcategoryId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/merchant/master-products/$userId/$subcategoryId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch master products'};
      } catch (_) {
        return {'error': 'Failed to fetch master products'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> addMerchantProduct(String userId, Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/merchant/products/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productData),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to add product'};
      } catch (_) {
        return {'error': 'Failed to add product'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateMerchantProduct(
      String userId, String productId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/merchant/products/$userId/$productId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      try {
        return {'error': jsonDecode(response.body)['error'] ?? 'Failed to update product'};
      } catch (_) {
        return {'error': 'Failed to update product'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteMerchantProduct(
      String userId, String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/merchant/products/$userId/$productId'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      try {
        return {'error': jsonDecode(response.body)['error'] ?? 'Failed to delete product'};
      } catch (_) {
        return {'error': 'Failed to delete product'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> toggleMerchantProductStatus(
      String userId, String productId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/merchant/products/$userId/$productId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      try {
        return {'error': jsonDecode(response.body)['error'] ?? 'Failed to toggle status'};
      } catch (_) {
        return {'error': 'Failed to toggle status'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  // ================= ADMIN API =================

  static Future<Map<String, dynamic>> getAdminProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/profile/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to fetch profile'};
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAdminDashboard(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/dashboard/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch admin dashboard data (HTTP ${response.statusCode})'};
      } catch (_) {
        return {'error': 'Failed to fetch admin dashboard data (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAdminCustomers(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/customers/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to fetch customers'};
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAdminMerchants(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/merchants/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to fetch merchants'};
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateMerchantStatus(String userId, String merchantId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/merchants/$merchantId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'status': status,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Failed to update status'};
    }
  }

  static Future<Map<String, dynamic>> getAdminProducts(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/products/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to fetch products'};
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  // ================= CUSTOMER API =================

  static Future<Map<String, dynamic>> getCustomerProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/customer/products'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch products (HTTP ${response.statusCode})'};
      } catch (_) {
        return {'error': 'Failed to fetch products (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSellersForVariant(String variantId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/customer/master-variants/$variantId/sellers'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch sellers'};
      } catch (_) {
        return {'error': 'Failed to fetch sellers'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCustomerProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/customer/profile/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch profile'};
      } catch (_) {
        return {'error': 'Failed to fetch profile'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAddresses(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/customer/addresses/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch addresses'};
      } catch (_) {
        return {'error': 'Failed to fetch addresses'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> addAddress(String userId, Map<String, dynamic> addressData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer/addresses/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(addressData),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to add address'};
      } catch (_) {
        return {'error': 'Failed to add address'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getOrderHistory(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/customer/orders/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to fetch order history'};
      } catch (_) {
        return {'error': 'Failed to fetch order history'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer/order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      try {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['error'] ?? 'Failed to place order (HTTP ${response.statusCode})'};
      } catch (_) {
        return {'error': 'Failed to place order (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateMerchantOrderStatus(
      String userId, String merchantOrderId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/merchant/orders/$userId/$merchantOrderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      try {
        return {'error': jsonDecode(response.body)['error'] ?? 'Failed to update order status'};
      } catch (_) {
        return {'error': 'Failed to update order status'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server: $e'};
    }
  }
}
