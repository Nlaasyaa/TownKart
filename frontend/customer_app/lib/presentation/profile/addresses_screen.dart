import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  late Future<Map<String, dynamic>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    final userId = ref.read(authUserIdProvider);
    if (userId != null) {
      setState(() {
        _addressesFuture = ApiService.getAddresses(userId);
      });
    } else {
      setState(() {
        _addressesFuture = Future.value({'error': 'User not logged in'});
      });
    }
  }

  void _showAddAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _AddAddressForm(),
    ).then((added) {
      if (added == true) {
        _loadAddresses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0C831F)));
          }

          if (snapshot.hasError || (snapshot.data != null && snapshot.data!['error'] != null)) {
            return Center(child: Text('Error: ${snapshot.error ?? snapshot.data!['error']}'));
          }

          final addresses = (snapshot.data!['addresses'] as List<dynamic>?) ?? [];

          if (addresses.isEmpty) {
            return const Center(
              child: Text('No addresses saved yet', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      address['address_type'] == 'HOME' ? Icons.home : (address['address_type'] == 'WORK' ? Icons.work : Icons.location_on),
                      color: const Color(0xFF0C831F),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                address['address_type'] ?? 'OTHER',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (address['is_default'] == 1 || address['is_default'] == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0C831F).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('DEFAULT', style: TextStyle(color: Color(0xFF0C831F), fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                              ]
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${address['address_line1']}${address['address_line2'] != null ? ', ${address['address_line2']}' : ''}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${address['city']}, ${address['state']} ${address['pincode']}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _showAddAddressSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C831F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('+ Add New Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _AddAddressForm extends ConsumerStatefulWidget {
  const _AddAddressForm();

  @override
  ConsumerState<_AddAddressForm> createState() => _AddAddressFormState();
}

class _AddAddressFormState extends ConsumerState<_AddAddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _addressType = 'HOME';
  bool _isDefault = false;
  bool _isSubmitting = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final userId = ref.read(authUserIdProvider);
    if (userId == null) return;

    final response = await ApiService.addAddress(userId, {
      'addressType': _addressType,
      'addressLine1': _line1Controller.text,
      'addressLine2': _line2Controller.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'pincode': _pincodeController.text,
      'isDefault': _isDefault,
    });

    setState(() {
      _isSubmitting = false;
    });

    if (response['error'] != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['error'])));
    } else if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'HOME', icon: Icon(Icons.home), label: Text('Home')),
                  ButtonSegment(value: 'WORK', icon: Icon(Icons.work), label: Text('Work')),
                  ButtonSegment(value: 'OTHER', icon: Icon(Icons.location_on), label: Text('Other')),
                ],
                selected: {_addressType},
                onSelectionChanged: (set) {
                  setState(() => _addressType = set.first);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _line1Controller,
                decoration: const InputDecoration(labelText: 'Address Line 1 *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _line2Controller,
                decoration: const InputDecoration(labelText: 'Address Line 2 (Optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City *', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State *', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode *', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default address'),
                value: _isDefault,
                onChanged: (val) {
                  setState(() => _isDefault = val ?? false);
                },
                activeColor: const Color(0xFF0C831F),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C831F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Address'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
