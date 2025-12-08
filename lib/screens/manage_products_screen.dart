import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../config/supabase_config.dart';
import '../services/products_service.dart';
import '../utils/constants.dart';
import '../l10n/app_locale.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen>
    with TickerProviderStateMixin {
  final ProductsService _productsService = ProductsService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  String get currentUserId =>
      SupabaseConfig.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProducts();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products =
          await _productsService.getProductsBySupplier(currentUserId);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(AppLocale.failedToLoadProducts.getString(context));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getLocalizedCategory(String categoryKey) {
    switch (categoryKey) {
      case 'Fungicides':
        return AppLocale.fungicides.getString(context);
      case 'Herbicides':
        return AppLocale.herbicides.getString(context);
      case 'Pesticides':
        return AppLocale.pesticides.getString(context);
      case 'Fertilizers':
        return AppLocale.fertilizers.getString(context);
      case 'Seeds':
        return AppLocale.seeds.getString(context);
      case 'Tools':
        return AppLocale.tools.getString(context);
      case 'Organic':
        return AppLocale.organic.getString(context);
      default:
        return categoryKey;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              primaryColor,
              backgroundColor,
            ],
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
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildProductsHeader(),
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        primaryColor)))
                            : _buildProductsList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          AppLocale.addProduct.getString(context),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  AppLocale.manageProducts.getString(context),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  AppLocale.addEditRemoveProducts.getString(context),
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

  Widget _buildProductsHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.1), backgroundColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_products.length} ${AppLocale.products.getString(context)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Text(
                  AppLocale.tapProductToEdit.getString(context),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadProducts,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            return _buildProductCard(product);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocale.noProductsFound.getString(context),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocale.addProductsToStart.getString(context),
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddProductDialog(),
              icon: const Icon(Icons.add),
              label: Text(AppLocale.addProduct.getString(context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product['image_url'] != null
                  ? Image.network(
                      product['image_url'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: backgroundColor,
                          child: Icon(Icons.image_not_supported,
                              color: primaryColor),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: backgroundColor,
                      child: Icon(Icons.inventory,
                          color: primaryColor, size: 40),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? AppLocale.unknownProduct.getString(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${product["price"]?.toStringAsFixed(2) ?? "0.00"}',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product['category'] != null 
                          ? _getLocalizedCategory(product['category'])
                          : AppLocale.all.getString(context),
                      style: TextStyle(
                        fontSize: 11,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        product['in_stock'] == true
                            ? Icons.check_circle
                            : Icons.remove_circle,
                        size: 14,
                        color: product['in_stock'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product['in_stock'] == true
                            ? AppLocale.inStock.getString(context)
                            : AppLocale.outOfStock.getString(context),
                        style: TextStyle(
                          fontSize: 11,
                          color: product['in_stock'] == true
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditProductDialog(product);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(product);
                    break;
                  case 'toggle_stock':
                    _toggleProductStock(product);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text(AppLocale.edit.getString(context)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_stock',
                  child: Row(
                    children: [
                      Icon(
                        product['in_stock'] == true
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(product['in_stock'] == true
                          ? AppLocale.outOfStock.getString(context)
                          : AppLocale.inStock.getString(context)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text(AppLocale.delete.getString(context),
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    _showProductDialog();
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    _showProductDialog(product: product);
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    showDialog(
      context: context,
      builder: (context) => ProductDialog(
        product: product,
        onSaved: _loadProducts,
      ),
    );
  }

  Future<void> _toggleProductStock(Map<String, dynamic> product) async {
    final currentStock = product['in_stock'] ?? false;
    final result = await _productsService.updateProduct(
      productId: product['id'],
      inStock: !currentStock,
    );

    if (result['success']) {
      _showSuccessSnackBar(
          !currentStock
              ? AppLocale.markAsInStock.getString(context)
              : AppLocale.markAsOutOfStock.getString(context));
      _loadProducts();
    } else {
      _showErrorSnackBar('Failed to update product stock status');
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocale.deleteProduct.getString(context)),
        content: Text(AppLocale.deleteProductConfirm.getString(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocale.cancel.getString(context)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteProduct(product);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocale.delete.getString(context)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final result = await _productsService.deleteProduct(product['id']);

    if (result['success']) {
      _showSuccessSnackBar(AppLocale.productDeletedSuccessfully.getString(context));
      _loadProducts();
    } else {
      _showErrorSnackBar(AppLocale.failedToDeleteProduct.getString(context));
    }
  }
}

class ProductDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onSaved;

  const ProductDialog({
    super.key,
    this.product,
    required this.onSaved,
  });

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final ProductsService _productsService = ProductsService();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCategory = 'Fungicides';
  List<String> _selectedDiseases = [];
  List<String> _benefits = [];
  final TextEditingController _benefitController = TextEditingController();
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;

  final List<String> _categoryKeys = [
    'Fungicides',
    'Herbicides',
    'Fertilizers',
    'Seeds',
    'Tools',
    'Organic',
    'Pesticides',
  ];

  final List<String> _diseaseKeys = [
    'Brown Planthopper',
    'Brown Spot',
    'Leaf Blast',
    'Leaf Scald',
    'Rice Leafroller',
    'Rice Yellow Stem Borer',
    'Sheath Blight',
    'Other',
  ];

  String _getLocalizedCategory(String categoryKey) {
    switch (categoryKey) {
      case 'Fungicides':
        return AppLocale.fungicides.getString(context);
      case 'Herbicides':
        return AppLocale.herbicides.getString(context);
      case 'Pesticides':
        return AppLocale.pesticides.getString(context);
      case 'Fertilizers':
        return AppLocale.fertilizers.getString(context);
      case 'Seeds':
        return AppLocale.seeds.getString(context);
      case 'Tools':
        return AppLocale.tools.getString(context);
      case 'Organic':
        return AppLocale.organic.getString(context);
      default:
        return categoryKey;
    }
  }

  String _getLocalizedDisease(String diseaseKey) {
    switch (diseaseKey) {
      case 'Brown Planthopper':
        return AppLocale.brownPlanthopper.getString(context);
      case 'Brown Spot':
        return AppLocale.brownSpot.getString(context);
      case 'Leaf Blast':
        return AppLocale.leafBlast.getString(context);
      case 'Leaf Scald':
        return AppLocale.leafScald.getString(context);
      case 'Rice Leafroller':
        return AppLocale.riceLeafroller.getString(context);
      case 'Rice Yellow Stem Borer':
        return AppLocale.riceYellowStemBorer.getString(context);
      case 'Sheath Blight':
        return AppLocale.sheathBlight.getString(context);
      case 'Other':
        return AppLocale.other.getString(context);
      default:
        return diseaseKey;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _selectedCategory = widget.product!['category'] ?? 'Fungicides';
      _currentImageUrl = widget.product!['image_url'];

      if (widget.product!['diseases'] != null) {
        _selectedDiseases =
            List<String>.from(widget.product!['diseases']);
      }
      
      if (widget.product!['benefits'] != null) {
        _benefits = List<String>.from(widget.product!['benefits']);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _benefitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width > 600 ? 500.0 : screenSize.width * 0.9;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
            maxWidth: maxWidth, maxHeight: screenSize.height * 0.85),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product == null ? AppLocale.addProduct.getString(context) : AppLocale.editProduct.getString(context),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildImagePicker(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: AppLocale.productName.getString(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocale.pleaseEnterProductName.getString(context);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: AppLocale.description.getString(context),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocale.pleaseEnterProductDescription.getString(context);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _priceController,
                    label: AppLocale.priceRM.getString(context),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocale.pleaseEnterPrice.getString(context);
                      }
                      if (double.tryParse(value) == null) {
                        return AppLocale.pleaseEnterValidPrice.getString(context);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  _buildDiseaseSelection(),
                  const SizedBox(height: 16),
                  _buildBenefitsSection(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(AppLocale.cancel.getString(context)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.product == null
                                      ? AppLocale.addProduct.getString(context)
                                      : AppLocale.update.getString(context),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocale.productImage.getString(context),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: primaryColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : _currentImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          _currentImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        ),
                      )
                    : _buildImagePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 40, color: primaryColor),
        const SizedBox(height: 8),
        Text(
          AppLocale.tapToAddImage.getString(context),
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: backgroundColor,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocale.category.getString(context),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: backgroundColor,
          ),
          items: _categoryKeys.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(_getLocalizedCategory(category)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDiseaseSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocale.effectiveAgainstDiseasesPests.getString(context),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _diseaseKeys.map((disease) {
            final isSelected = _selectedDiseases.contains(disease);
            return FilterChip(
              label: Text(
                _getLocalizedDisease(disease),
                style: TextStyle(
                  color: isSelected ? Colors.white : primaryColor,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: primaryColor,
              backgroundColor: primaryColor.withOpacity(0.1),
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDiseases.add(disease);
                  } else {
                    _selectedDiseases.remove(disease);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocale.keyBenefits.getString(context),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        
        // Display existing benefits
        if (_benefits.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _benefits.map((benefit) {
              return Chip(
                label: Text(
                  benefit,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.green.shade50,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _benefits.remove(benefit);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        
        // Add new benefit
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _benefitController,
                decoration: InputDecoration(
                  hintText: AppLocale.addBenefitHint.getString(context),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onSubmitted: (value) => _addBenefit(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addBenefit,
              icon: const Icon(Icons.add_circle),
              color: primaryColor,
              tooltip: AppLocale.addBenefit.getString(context),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppLocale.addKeyBenefitsDescription.getString(context),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _addBenefit() {
    final benefit = _benefitController.text.trim();
    if (benefit.isNotEmpty && !_benefits.contains(benefit)) {
      setState(() {
        _benefits.add(benefit);
        _benefitController.clear();
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _currentImageUrl;

      if (_selectedImage != null) {
        final productId =
            widget.product?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await _productsService.uploadProductImage(
            _selectedImage!, productId);
      }

      final currentUserId =
          SupabaseConfig.client.auth.currentUser?.id ?? '';

      Map<String, dynamic> result;

      if (widget.product == null) {
        result = await _productsService.createProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _selectedCategory,
          supplierId: currentUserId,
          imageUrl: imageUrl,
          diseases: _selectedDiseases.isNotEmpty ? _selectedDiseases : null,
          benefits: _benefits.isNotEmpty ? _benefits : null,
        );
      } else {
        result = await _productsService.updateProduct(
          productId: widget.product!['id'],
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _selectedCategory,
          imageUrl: imageUrl,
          diseases: _selectedDiseases.isNotEmpty ? _selectedDiseases : null,
          benefits: _benefits.isNotEmpty ? _benefits : null,
        );
      }

      if (result['success']) {
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
