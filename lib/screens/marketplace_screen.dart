import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MarketplaceScreen extends StatefulWidget {
  final String? diseaseFilter;
  
  const MarketplaceScreen({super.key, this.diseaseFilter});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _selectedCategory = 0;
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> categories = [
    'All Products',
    'Fungicides',
    'Bactericides',
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

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredProducts {
    List<Map<String, dynamic>> filtered = products;
    
    // Filter by category
    if (_selectedCategory != 0) {
      filtered = filtered.where((product) => 
        product['category'] == categories[_selectedCategory]).toList();
    }
    
    // Filter by search term
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((product) {
        // Check product name, supplier, description
        bool matchesBasic = product['name'].toLowerCase().contains(searchTerm) ||
            product['supplier'].toLowerCase().contains(searchTerm) ||
            product['description'].toLowerCase().contains(searchTerm);
        
        // Check if product is effective against the searched disease
        bool matchesDisease = false;
        if (product['diseases'] != null) {
          final diseases = product['diseases'] as List<dynamic>;
          matchesDisease = diseases.any((disease) => 
            disease.toString().toLowerCase().contains(searchTerm));
        }
        
        return matchesBasic || matchesDisease;
      }).toList();
    }
    
    // Sort products - put disease-specific products first if searching for disease
    if (widget.diseaseFilter != null) {
      filtered.sort((a, b) {
        final aDiseases = a['diseases'] as List<dynamic>? ?? [];
        final bDiseases = b['diseases'] as List<dynamic>? ?? [];
        
        bool aMatches = aDiseases.any((disease) => 
          disease.toString().toLowerCase().contains(widget.diseaseFilter!.toLowerCase()));
        bool bMatches = bDiseases.any((disease) => 
          disease.toString().toLowerCase().contains(widget.diseaseFilter!.toLowerCase()));
        
        if (aMatches && !bMatches) return -1;
        if (!aMatches && bMatches) return 1;
        return 0;
      });
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Marketplace',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Show cart
            },
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchAndFilter(),
            _buildCategories(),
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search products, suppliers...',
                prefixIcon: const Icon(Icons.search, color: primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear, color: primaryColor),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip('${products.length}', 'Products', Icons.inventory),
              _buildStatChip('${products.where((p) => p['inStock']).length}', 'In Stock', Icons.check_circle),
              _buildStatChip('${products.where((p) => p['discount'] > 0).length}', 'On Sale', Icons.local_offer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? primaryGradient : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: isSelected ? null : Border.all(color: primaryColor),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : primaryColor,
                    fontWeight: FontWeight.w600,
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
        childAspectRatio: 0.75,
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
    final hasDiscount = product['discount'] > 0;
    final discountedPrice = product['price'].replaceAll('RM ', '');
    final originalPrice = double.parse(discountedPrice);
    final finalPrice = originalPrice * (1 - product['discount'] / 100);
    
    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with badges
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      width: double.infinity,
                      color: primaryColor.withOpacity(0.1),
                      child: Icon(
                        _getCategoryIcon(product['category']),
                        size: 48,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  
                  // Discount badge
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${product['discount']}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Stock status
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product['inStock'] ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product['inStock'] ? 'In Stock' : 'Out of Stock',
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textDarkColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Supplier
                    Text(
                      product['supplier'],
                      style: captionStyle.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${product['rating']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          ' (${product['reviews']})',
                          style: captionStyle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Price
                    Row(
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            'RM ${originalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          hasDiscount 
                              ? 'RM ${finalPrice.toStringAsFixed(2)}'
                              : product['price'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
    final hasDiscount = product['discount'] > 0;
    final discountedPrice = product['price'].replaceAll('RM ', '');
    final originalPrice = double.parse(discountedPrice);
    final finalPrice = originalPrice * (1 - product['discount'] / 100);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(product['category']),
                          size: 40,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'],
                              style: headingStyle.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product['supplier'],
                              style: bodyStyle.copyWith(color: textLightColor),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '${product['rating']} (${product['reviews']} reviews)',
                                  style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Price section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: interactiveCardDecoration,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount) ...[
                              Text(
                                'RM ${originalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              hasDiscount 
                                  ? 'RM ${finalPrice.toStringAsFixed(2)}'
                                  : product['price'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Save ${product['discount']}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text(
                    'Description',
                    style: subHeadingStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['description'],
                    style: bodyStyle.copyWith(height: 1.5),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Features/Benefits
                  const Text(
                    'Key Benefits',
                    style: subHeadingStyle,
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem('✅ Proven effectiveness against target diseases'),
                  _buildBenefitItem('✅ Safe for environment when used as directed'),
                  _buildBenefitItem('✅ Trusted by thousands of farmers'),
                  _buildBenefitItem('✅ Easy application process'),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: product['inStock'] ? () {
                            // TODO: Add to cart
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product['name']} added to cart'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } : null,
                          icon: const Icon(Icons.shopping_cart),
                          label: Text(product['inStock'] ? 'Add to Cart' : 'Out of Stock'),
                          style: product['inStock'] ? primaryButtonStyle : 
                                 primaryButtonStyle.copyWith(
                                   backgroundColor: WidgetStateProperty.all(Colors.grey),
                                 ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Contact supplier
                        },
                        style: secondaryButtonStyle,
                        child: const Icon(Icons.message),
                      ),
                    ],
                  ),
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
