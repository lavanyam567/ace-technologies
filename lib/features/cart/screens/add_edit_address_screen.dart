import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/address_provider.dart';
import '../../../models/order_model.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final String? addressId;

  const AddEditAddressScreen({super.key, this.addressId});

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  String _addressType = 'home';
  bool _isEdit = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.addressId != null && widget.addressId != 'new') {
      _isEdit = true;
      _loadAddress();
    }
  }

  void _loadAddress() {
    final addresses = ref.read(savedAddressesProvider);
    final matches = addresses.where((a) => a.id == widget.addressId);
    final address = matches.isEmpty ? null : matches.first;
    if (address != null) {
      _nameController.text = address.name;
      _phoneController.text = address.phone;
      _streetController.text = address.street ?? address.addressLine1;
      _cityController.text = address.city;
      _stateController.text = address.state;
      _pincodeController.text = address.pincode;
      _addressType = address.type ?? 'home';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(addressErrorProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          _isEdit ? 'Edit Address' : 'Add Address',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address Type
              const Text(
                'Address Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTypeOption('home', 'Home', Icons.home)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeOption('office', 'Office', Icons.business),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeOption(
                      'other',
                      'Other',
                      Icons.location_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                keyboardType: TextInputType.name,
                validator: (v) => (v ?? '').isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Phone
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),

              // Street Address
              _buildTextField(
                controller: _streetController,
                label: 'Street Address',
                hint: 'Enter street address',
                keyboardType: TextInputType.streetAddress,
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),

              // City
              _buildTextField(
                controller: _cityController,
                label: 'City',
                hint: 'Enter city',
                keyboardType: TextInputType.text,
                validator: (v) => (v ?? '').isEmpty ? 'City is required' : null,
              ),
              const SizedBox(height: 16),

              // State
              _buildTextField(
                controller: _stateController,
                label: 'State',
                hint: 'Enter state',
                keyboardType: TextInputType.text,
                validator: (v) =>
                    (v ?? '').isEmpty ? 'State is required' : null,
              ),
              const SizedBox(height: 16),

              // Pincode
              _buildTextField(
                controller: _pincodeController,
                label: 'Pincode',
                hint: 'Enter pincode',
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Pincode is required' : null,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAddress,
                  child: Text(
                    _isSaving
                        ? 'Saving...'
                        : _isEdit
                        ? 'Update Address'
                        : 'Save Address',
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error, style: const TextStyle(color: AppTheme.errorColor)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(String value, String label, IconData icon) {
    final isSelected = _addressType == value;
    return GestureDetector(
      onTap: () => setState(() => _addressType = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      final address = Address(
        id: _isEdit ? widget.addressId! : '',
        name: _nameController.text,
        phone: _phoneController.text,
        addressLine1: _streetController.text,
        street: _streetController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        type: _addressType,
        label: _addressType == 'home'
            ? 'Home'
            : _addressType == 'office'
            ? 'Office'
            : 'Other',
      );

      setState(() => _isSaving = true);
      try {
        if (_isEdit) {
          await ref
              .read(savedAddressesProvider.notifier)
              .updateAddress(address);
        } else {
          await ref.read(savedAddressesProvider.notifier).addAddress(address);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Address updated!' : 'Address saved!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }
}
