import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF006D31),
              padding: const EdgeInsets.all(32.0),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.shopping_cart, color: Colors.white, size: 32),
                        SizedBox(width: 8),
                        Text('Town', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Everything in\nyour town,\ndelivered.',
                      style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, height: 1.1),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'A premium local marketplace connecting\nneighborhood shops with the people they\nserve.',
                      style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    const Row(
                      children: [
                        Icon(Icons.circle, color: Colors.white70, size: 8),
                        SizedBox(width: 8),
                        Text('Serving 240+ towns across India', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    )
                  ]
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HOW WOULD YOU LIKE TO CONTINUE?', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    context,
                    icon: Icons.shopping_basket,
                    title: 'Continue as Customer',
                    subtitle: 'Shop groceries, dairy, fruits from\nyour local stores.',
                    onTap: () => context.push('/customer-signup'),
                    iconColor: Colors.green,
                    iconBg: Colors.green.shade50,
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    context,
                    icon: Icons.storefront,
                    title: 'Continue as Merchant',
                    subtitle: 'Register your shop and start selling\nto your town today.',
                    onTap: () => context.push('/merchant-signup'),
                    iconColor: Colors.teal,
                    iconBg: Colors.teal.shade50,
                  ),
                  const Spacer(),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.push('/admin-login'),
                      icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.grey, size: 18),
                      label: const Text('Admin login', style: TextStyle(color: Colors.grey)),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.grey.shade300)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'By continuing you agree to TownKart\'s Terms & Privacy Policy.',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap, required Color iconColor, required Color iconBg}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
