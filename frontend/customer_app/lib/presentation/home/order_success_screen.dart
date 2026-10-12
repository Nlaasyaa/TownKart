import 'package:flutter/material.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: Color(0xFF0C831F), size: 80),
              ),
              const SizedBox(height: 32),
              const Text('Order Placed Successfully!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text('Your order ID is\n$orderId', style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text('Delivery will be assigned to a driver soon.', style: TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C831F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
