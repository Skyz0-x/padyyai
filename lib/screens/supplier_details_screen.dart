import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../l10n/app_locale.dart';
import 'package:flutter_localization/flutter_localization.dart';

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
  File? _certificateFile;
  String? _certificateFileName;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickCertificate() async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocale.selectCertificate.getString(context)),
          content: Text(AppLocale.chooseUploadSSM.getString(context)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
              child: Text(AppLocale.fromGallery.getString(context)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
              child: Text(AppLocale.takePhoto.getString(context)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        _authService.showToast(context, AppLocale.errorPickingFile.getString(context), isError: true);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _certificateFile = File(image.path);
          _certificateFileName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        _authService.showToast(context, AppLocale.errorSelectingImage.getString(context), isError: true);
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _certificateFile = File(image.path);
          _certificateFileName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        _authService.showToast(context, AppLocale.errorTakingPhoto.getString(context), isError: true);
      }
    }
  }

  Future<void> _saveSupplierDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if certificate is uploaded
    if (_certificateFile == null) {
      _authService.showToast(context, AppLocale.pleaseUploadSSMCertificate.getString(context), isError: true);
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
          _authService.showToast(context, AppLocale.userNotFound.getString(context), isError: true);
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
        certificateFile: _certificateFile,
      );

      if (result['success']) {
        if (mounted) {
          _authService.showToast(context, AppLocale.supplierDetailsSavedSuccessfully.getString(context));
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
        _authService.showToast(context, AppLocale.failedSaveDetails.getString(context), isError: true);
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
            colors: [primaryColor, backgroundColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        _buildDetailsForm(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocale.businessProfile.getString(context),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  AppLocale.updateBusinessInfo.getString(context),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            Text(
              AppLocale.businessInformation.getString(context),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Business Name
            _buildTextField(
              controller: _businessNameController,
              label: AppLocale.businessName.getString(context),
              icon: Icons.business,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocale.pleaseEnterBusinessName.getString(context);
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Business Type
            _buildTextField(
              controller: _businessTypeController,
              label: AppLocale.businessTypeHint.getString(context),
              icon: Icons.category,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocale.pleaseEnterBusinessType.getString(context);
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Address
            _buildTextField(
              controller: _addressController,
              label: AppLocale.businessAddress.getString(context),
              icon: Icons.location_on,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocale.pleaseEnterBusinessAddress.getString(context);
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Phone
            _buildTextField(
              controller: _phoneController,
              label: AppLocale.phone.getString(context),
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocale.pleaseEnterPhoneNumber.getString(context);
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            _buildTextField(
              controller: _descriptionController,
              label: AppLocale.businessDescription.getString(context),
              icon: Icons.description,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocale.pleaseEnterBusinessDescription.getString(context);
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Products
            _buildTextField(
              controller: _productsController,
              label: AppLocale.productsServicesHint.getString(context),
              icon: Icons.inventory,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocale.pleaseEnterProductsServices.getString(context);
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Certificate Upload
            _buildCertificateUpload(),
            
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
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildCertificateUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                AppLocale.ssmCertificateUpload.getString(context),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocale.ssmCertificateDesc.getString(context),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          if (_certificateFile != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _certificateFileName ?? AppLocale.certificateUploaded.getString(context),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _certificateFile = null;
                        _certificateFileName = null;
                      });
                    },
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _pickCertificate,
            icon: const Icon(Icons.upload_file),
            label: Text(_certificateFile == null ? AppLocale.uploadCertificate.getString(context) : AppLocale.changeCertificate.getString(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveSupplierDetails,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: _isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(AppLocale.saving.getString(context)),
              ],
            )
          : Text(
              AppLocale.completeProfile.getString(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}