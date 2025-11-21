import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../l10n/app_locale.dart';
import '../utils/constants.dart';
import '../services/products_service.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  final String? diseaseFilter;
  
  const MarketplaceScreen({super.key, this.diseaseFilter});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with TickerProviderStateMixin {
  final ProductsService _productsService = ProductsService();
  final CartService _cartService = CartService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _selectedCategory = 0;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  int _cartItemCount = 0;
  
  final List<String> categories = [
    'All Products',
    'Fungicides',
    'Bactericides',
    'Pesticides',
    'Fertilizers',
    'Seeds',
    'Tools',
    'Organic',
  ];

  final List<Map<String, dynamic>> products = [
    {
      'name': 'Copper Fungicide Pro',
      'supplier': 'AgriChem Solutions',
      'price': 'RM 45.00',
      'rating': 4.8,
      'reviews': 156,
      'category': 'Fungicides',
      'description': 'Effective against brown spot and blast disease',
      'image': 'https://placehold.co/300x300/4CAF50/FFFFFF?text=Fungicide',
      'inStock': true,
      'discount': 15,
      'diseases': ['brown_spot', 'blast'],
    },
    {
      'name': 'Tricyclazole 75% WP',
      'supplier': 'CropCare Industries',
      'price': 'RM 68.00',
      'rating': 4.9,
      'reviews': 203,
      'category': 'Fungicides',
      'description': 'Systemic fungicide specialized for blast disease control',
      'image': 'https://placehold.co/300x300/388E3C/FFFFFF?text=Tricyclazole',
      'inStock': true,
      'discount': 20,
      'diseases': ['blast'],
    },
    {
      'name': 'Mancozeb 75% WP',
      'supplier': 'Farm Nutrients Ltd',
      'price': 'RM 32.00',
      'rating': 4.6,
      'reviews': 89,
      'category': 'Fungicides',
      'description': 'Contact fungicide for brown spot and other fungal diseases',
      'image': 'https://placehold.co/300x300/689F38/FFFFFF?text=Mancozeb',
      'inStock': true,
      'discount': 10,
      'diseases': ['brown_spot'],
    },
    {
      'name': 'Copper Hydroxide 77% WP',
      'supplier': 'BacteriaShield Pro',
      'price': 'RM 52.00',
      'rating': 4.7,
      'reviews': 124,
      'category': 'Bactericides',
      'description': 'Copper-based bactericide effective against bacterial leaf blight',
      'image': 'https://placehold.co/300x300/2E7D32/FFFFFF?text=Cu+Hydroxide',
      'inStock': true,
      'discount': 5,
      'diseases': ['bacterial_leaf_blight'],
    },
    {
      'name': 'Streptomycin Sulfate 25% WP',
      'supplier': 'AgriBiotics Co.',
      'price': 'RM 68.00',
      'rating': 4.8,
      'reviews': 167,
      'category': 'Bactericides',
      'description': 'Antibiotic bactericide for bacterial diseases in rice',
      'image': 'https://placehold.co/300x300/66BB6A/FFFFFF?text=Streptomycin',
      'inStock': true,
      'discount': 15,
      'diseases': ['bacterial_leaf_blight'],
    },
    {
      'name': 'Propiconazole 25% EC',
      'supplier': 'Elite Crop Solutions',
      'price': 'RM 85.00',
      'rating': 4.9,
      'reviews': 89,
      'category': 'Fungicides',
      'description': 'Premium systemic fungicide for severe blast infections',
      'image': 'https://placehold.co/300x300/4CAF50/FFFFFF?text=Propiconazole',
      'inStock': true,
      'discount': 25,
      'diseases': ['blast'],
    },
    {
      'name': 'Organic Rice Seeds',
      'supplier': 'Green Harvest Co.',
      'price': 'RM 120.00',
      'rating': 4.9,
      'reviews': 203,
      'category': 'Seeds',
      'description': 'High-yield disease-resistant rice variety',
      'image': 'https://placehold.co/300x300/8BC34A/FFFFFF?text=Seeds',
      'inStock': true,
      'discount': 0,
      'diseases': [],
    },
    {
      'name': 'NPK Balanced Fertilizer',
      'supplier': 'Farm Nutrients Ltd',
      'price': 'RM 35.00',
      'rating': 4.6,
      'reviews': 89,
      'category': 'Fertilizers',
      'description': 'Balanced nutrition for healthy crop growth',
      'image': 'https://placehold.co/300x300/689F38/FFFFFF?text=Fertilizer',
      'inStock': true,
      'discount': 10,
      'diseases': [],
    },
    {
      'name': 'Smart Field Sprayer',
      'supplier': 'TechFarm Equipment',
      'price': 'RM 890.00',
      'rating': 4.7,
      'reviews': 45,
      'category': 'Tools',
      'description': 'Precision spraying for optimal coverage',
      'image': 'https://placehold.co/300x300/2E7D32/FFFFFF?text=Sprayer',
      'inStock': true,
      'discount': 20,
      'diseases': [],
    },
    {
      'name': 'Organic Neem Oil',
      'supplier': 'EcoFarm Solutions',
      'price': 'RM 28.00',
      'rating': 4.5,
      'reviews': 67,
      'category': 'Organic',
      'description': 'Natural pest control and disease prevention',
      'image': 'https://placehold.co/300x300/388E3C/FFFFFF?text=Neem+Oil',
      'inStock': false,
      'discount': 0,
      'diseases': ['brown_spot'],
    },
    {
      'name': 'Blast Shield Fungicide',
      'supplier': 'CropCare Industries',
      'price': 'RM 67.00',
      'rating': 4.8,
      'reviews': 134,
      'category': 'Fungicides',
      'description': 'Specialized treatment for blast disease',
      'image': 'https://placehold.co/300x300/66BB6A/FFFFFF?text=Blast+Shield',
      'inStock': true,
      'discount': 25,
      'diseases': ['blast'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProducts();
    _loadCartCount();
    _searchController.addListener(_onSearchChanged);
    
    // If a disease filter is provided, search for it
    if (widget.diseaseFilter != null) {
      _searchController.text = widget.diseaseFilter!;
      // Show filter for bactericides or fungicides based on disease
      if (widget.diseaseFilter!.toLowerCase().contains('bacterial')) {
        _selectedCategory = categories.indexOf('Bactericides');
      } else if (widget.diseaseFilter!.toLowerCase().contains('blast') || 
                 widget.diseaseFilter!.toLowerCase().contains('brown_spot')) {
        _selectedCategory = categories.indexOf('Fungicides');
      }
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      List<Map<String, dynamic>> products;
      
      if (widget.diseaseFilter != null) {
        products = await _productsService.getProductsForDisease(widget.diseaseFilter!);
      } else {
        products = await _productsService.getAllProducts();
      }
      
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _products = [];
        _filteredProducts = [];
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _filterProducts();
  }

  Future<void> _loadCartCount() async {
    final count = await _cartService.getCartItemCount();
    setState(() => _cartItemCount = count);
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final result = await _cartService.addToCart(
      productId: product['id'].toString(),
      productName: product['name'],
      productPrice: (product['price'] as num).toDouble(),
      productImage: product['image_url'],
      productCategory: product['category'],
      quantity: 1,
    );

    if (result['success']) {
      await _loadCartCount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                ).then((_) => _loadCartCount());
              },
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    final selectedCategory = categories[_selectedCategory];
    
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = query.isEmpty ||
            product['name']?.toLowerCase().contains(query) == true ||
            product['description']?.toLowerCase().contains(query) == true ||
            product['category']?.toLowerCase().contains(query) == true;
            
        final matchesCategory = selectedCategory == 'All Products' ||
            product['category'] == selectedCategory;
            
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredProducts {
    return _filteredProducts;
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
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Row(
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
                      AppLocale.marketplace.getString(context),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Find products for your farm',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      ).then((_) => _loadCartCount());
                    },
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
                    tooltip: 'Cart',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (_cartItemCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          _cartItemCount > 99 ? '99+' : _cartItemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading products...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildCategories(),
        Expanded(child: _buildProductGrid()),
      ],
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = index);
              _filterProducts();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : textDarkColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    final filtered = filteredProducts;
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or category filter',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildProductCard(filtered[index]);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    // For now, show 'Supplier' as placeholder since we're not joining with users table
    // This can be enhanced later once the foreign key relationship is fixed
    final supplierName = 'Supplier'; // Placeholder
    
    final price = product['price']?.toDouble() ?? 0.0;
    final imageUrl = product['image_url'];
    
    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                color: primaryColor.withOpacity(0.1),
                                child: Icon(
                                  _getCategoryIcon(product['category']),
                                  size: 48,
                                  color: primaryColor,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                            color: primaryColor.withOpacity(0.1),
                            child: Icon(
                              _getCategoryIcon(product['category']),
                              size: 48,
                              color: primaryColor,
                            ),
                          ),
                  ),
                  
                  // In stock badge
                  if (product['in_stock'] == true)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'In Stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product name
                    Text(
                      product['name'] ?? 'Unknown Product',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: textDarkColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Supplier
                    Text(
                      supplierName,
                      style: captionStyle.copyWith(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product['category'] ?? 'General',
                        style: TextStyle(
                          fontSize: 8,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Price
                    Text(
                      'RM ${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Fungicides':
        return Icons.medication;
      case 'Bactericides':
        return Icons.science;
      case 'Pesticides':
        return Icons.pest_control;
      case 'Fertilizers':
        return Icons.eco;
      case 'Seeds':
        return Icons.grass;
      case 'Tools':
        return Icons.build;
      case 'Organic':
        return Icons.nature;
      default:
        return Icons.inventory;
    }
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductDetailsModal(product),
    );
  }

  Widget _buildProductDetailsModal(Map<String, dynamic> product) {
    final price = product['price']?.toDouble() ?? 0.0;
    final imageUrl = product['image_url'];
    final inStock = product['in_stock'] ?? false;
    final description = product['description'] ?? 'No description available';
    final category = product['category'] ?? 'General';
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 250,
                                  color: primaryColor.withOpacity(0.1),
                                  child: Icon(
                                    _getCategoryIcon(category),
                                    size: 80,
                                    color: primaryColor,
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: double.infinity,
                              height: 250,
                              color: primaryColor.withOpacity(0.1),
                              child: Icon(
                                _getCategoryIcon(category),
                                size: 80,
                                color: primaryColor,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Product name
                  Text(
                    product['name'] ?? 'Unknown Product',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textDarkColor,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Category and Stock Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: inStock ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              inStock ? Icons.check_circle : Icons.remove_circle,
                              size: 14,
                              color: inStock ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              inStock ? 'In Stock' : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 12,
                                color: inStock ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Price section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'RM ${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: textLightColor,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Effective Against Diseases (if available)
                  if (product['diseases'] != null && (product['diseases'] as List).isNotEmpty) ...[
                    const Text(
                      'Effective Against',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDarkColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (product['diseases'] as List).map((disease) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              Text(
                                disease.toString().replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Key Benefits
                  const Text(
                    'Key Benefits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem('✅ Quality assured product'),
                  _buildBenefitItem('✅ Trusted by farmers'),
                  _buildBenefitItem('✅ Easy to use and apply'),
                  if (inStock)
                    _buildBenefitItem('✅ Available for immediate delivery'),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: inStock ? () async {
                            Navigator.pop(context);
                            await _addToCart(product);
                          } : null,
                          icon: const Icon(Icons.shopping_cart, size: 20),
                          label: Text(
                            inStock ? 'Add to Cart' : 'Out of Stock',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: inStock ? primaryColor : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: inStock ? 4 : 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contact supplier feature coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        child: const Icon(Icons.message, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: bodyStyle.copyWith(height: 1.4),
      ),
    );
  }
}
