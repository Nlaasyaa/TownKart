import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import 'order_success_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    if (cartItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Add items from Categories to get started', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final subtotal = cartNotifier.subtotal;
    final deliveryFee = 40.0;
    final grandTotal = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
            Text('${cartItems.length} item${cartItems.length == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final merchantProductId = item.product['merchant_product_id'].toString();
                final itemTotal = double.parse(item.product['selling_price'].toString()) * item.quantity;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image_outlined, color: Colors.grey),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product['product_name'] ?? 'Product',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              if ((item.product['variant_name'] ?? '').toString().isNotEmpty)
                                Text(item.product['variant_name'].toString(),
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('₹${item.product['selling_price']} each',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${itemTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C831F),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => cartNotifier.decrementQuantity(merchantProductId),
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Icon(Icons.remove, color: Colors.white, size: 14),
                                    ),
                                  ),
                                  Text('${item.quantity}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  InkWell(
                                    onTap: () => cartNotifier.incrementQuantity(merchantProductId),
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Icon(Icons.add, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bill summary + Place Order button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: TextStyle(color: Colors.grey.shade600)),
                    Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Delivery Fee', style: TextStyle(color: Colors.grey.shade600)),
                    Text('₹${deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Divider(height: 24, color: Colors.grey.shade200),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('₹${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0C831F))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _onPlaceOrderTapped(context, ref, cartItems, cartNotifier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C831F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Proceed to Place Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPlaceOrderTapped(
    BuildContext context,
    WidgetRef ref,
    List<CartItem> cartItems,
    CartNotifier cartNotifier,
  ) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to place an order')));
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final addressesResponse = await ApiService.getAddresses(userId);
    Navigator.pop(context); // close loading

    if (addressesResponse['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to fetch addresses')));
      return;
    }

    final addresses = (addressesResponse['addresses'] as List<dynamic>?) ?? [];
    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add a delivery address in your Profile first'),
        duration: Duration(seconds: 4),
      ));
      return;
    }

    // Show address selection bottom sheet
    if (!context.mounted) return;
    final selectedAddressId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressSelectionSheet(addresses: addresses),
    );

    if (selectedAddressId == null) return; // user dismissed without selecting

    // Place order
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final orderData = {
      'customerId': userId,
      'addressId': selectedAddressId,
      'items': cartItems.map((item) => {
        'merchant_product_id': item.product['merchant_product_id'],
        'quantity': item.quantity,
      }).toList(),
    };

    final result = await ApiService.placeOrder(orderData);
    if (!context.mounted) return;
    Navigator.pop(context); // close loading

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
      );
    } else {
      cartNotifier.clearCart();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OrderSuccessScreen(orderId: result['orderId'])),
      );
    }
  }
}

class _AddressSelectionSheet extends StatefulWidget {
  final List<dynamic> addresses;
  const _AddressSelectionSheet({required this.addresses});

  @override
  State<_AddressSelectionSheet> createState() => _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends State<_AddressSelectionSheet> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    // Pre-select default address or first one
    final defaultAddr = widget.addresses.firstWhere(
      (a) => a['is_default'] == 1 || a['is_default'] == true,
      orElse: () => widget.addresses[0],
    );
    _selectedId = defaultAddr['id'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Select Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('Choose where you\'d like your order delivered', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 20),

          // Address list
          ...widget.addresses.map((addr) {
            final addrId = addr['id'].toString();
            final isSelected = _selectedId == addrId;
            final label = addr['address_label'] ?? 'Address';
            final line1 = addr['address_line1'] ?? '';
            final line2 = addr['address_line2'] ?? '';
            final city = addr['city'] ?? '';
            final pincode = addr['pincode'] ?? '';

            return GestureDetector(
              onTap: () => setState(() => _selectedId = addrId),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0C831F) : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0C831F) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        label.toLowerCase().contains('home') ? Icons.home_outlined : Icons.location_on_outlined,
                        color: isSelected ? Colors.white : Colors.grey,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              if (addr['is_default'] == 1 || addr['is_default'] == true) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('DEFAULT', style: TextStyle(color: Color(0xFF0C831F), fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [line1, line2, city, pincode].where((s) => s.isNotEmpty).join(', '),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: addrId,
                      groupValue: _selectedId,
                      onChanged: (val) => setState(() => _selectedId = val!),
                      activeColor: const Color(0xFF0C831F),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C831F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Confirm & Place Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
