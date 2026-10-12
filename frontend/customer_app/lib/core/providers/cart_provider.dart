import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final Map<String, dynamic> product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Map<String, dynamic> product) {
    final existingItemIndex = state.indexWhere(
        (item) => item.product['merchant_product_id'] == product['merchant_product_id']);
        
    if (existingItemIndex >= 0) {
      final newState = [...state];
      newState[existingItemIndex].quantity++;
      state = newState;
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeFromCart(String merchantProductId) {
    state = state.where((item) => item.product['merchant_product_id'] != merchantProductId).toList();
  }

  void incrementQuantity(String merchantProductId) {
    final existingItemIndex = state.indexWhere(
        (item) => item.product['merchant_product_id'] == merchantProductId);
        
    if (existingItemIndex >= 0) {
      final newState = [...state];
      newState[existingItemIndex].quantity++;
      state = newState;
    }
  }

  void decrementQuantity(String merchantProductId) {
    final existingItemIndex = state.indexWhere(
        (item) => item.product['merchant_product_id'] == merchantProductId);
        
    if (existingItemIndex >= 0) {
      final newState = [...state];
      if (newState[existingItemIndex].quantity > 1) {
        newState[existingItemIndex].quantity--;
        state = newState;
      } else {
        removeFromCart(merchantProductId);
      }
    }
  }

  void clearCart() {
    state = [];
  }

  double get subtotal {
    double total = 0;
    for (var item in state) {
      total += double.parse(item.product['selling_price'].toString()) * item.quantity;
    }
    return total;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
