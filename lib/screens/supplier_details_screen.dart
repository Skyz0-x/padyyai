import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SupplierDetailsScreen extends StatefulWidget {
  const SupplierDetailsScreen({super.key});

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  // Form controllers
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _productsController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _productsController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplierDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (mounted) {
          _authService.showToast(context, 'User not found. Please login again.', isError: true);
        }
        return;
      }

      Map<String, dynamic> updateData = {
        'business_name': _businessNameController.text.trim(),
        'business_address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'business_type': _businessTypeController.text.trim(),
        'business_description': _descriptionController.text.trim(),
        'products_offered': _productsController.text.trim(),
      };

      Map<String, dynamic> result = await _authService.updateSupplierDetails(
        currentUser.id,
        updateData,
      );

      if (result['success']) {
        if (mounted) {
          _authService.showToast(context, 'Supplier details saved successfully!');
          // Navigate to supplier pending screen since they need admin approval
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/supplier-pending',
            (route) => false, // Remove all previous routes
          );
        }
      } else {
        if (mounted) {
          _authService.showToast(context, result['message'], isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _authService.showToast(context, 'Failed to save details. Please try again.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Header
                _buildHeader(),
                
                const SizedBox(height: 30),
                
                // Form
                _buildDetailsForm(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            Icons.business,
            size: 50,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Complete Your Business Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Help farmers find and trust your products',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Business Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Business Name
            _buildTextField(
              controller: _businessNameController,
              label: 'Business Name',
              icon: Icons.business,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your business name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Business Type
            _buildTextField(
              controller: _businessTypeController,
              label: 'Business Type (e.g., Pesticide Supplier, Fertilizer Distributor)',
              icon: Icons.category,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your business type';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Address
            _buildTextField(
              controller: _addressController,
              label: 'Business Address',
              icon: Icons.location_on,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your business address';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Phone
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Business Description',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a business description';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Products
            _buildTextField(
              controller: _productsController,
              label: 'Products/Services (e.g., Organic pesticides, Bio-fertilizers)',
              icon: Icons.inventory,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your products or services';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade500),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveSupplierDetails,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: _isLoading
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Saving...'),
              ],
            )
          : const Text(
              'Complete Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}