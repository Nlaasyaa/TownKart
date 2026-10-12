import 'package:flutter/material.dart';

void main() {
  runApp(const TownKartMerchantApp());
}

class TownKartMerchantApp extends StatelessWidget {
  const TownKartMerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TownKart Merchant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006D31)),
        useMaterial3: true,
      ),
      home: const MerchantDashboardPlaceholder(),
    );
  }
}

class MerchantDashboardPlaceholder extends StatelessWidget {
  const MerchantDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text(
          'Welcome to TownKart Merchant Dashboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
