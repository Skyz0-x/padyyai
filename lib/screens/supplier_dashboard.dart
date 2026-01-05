import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../services/auth_service.dart';
import '../services/products_service.dart';
import '../services/supplier_orders_service.dart';
import '../widgets/loading_screen.dart';
import 'manage_products_screen.dart';
import '../l10n/app_locale.dart';
import '../utils/constants.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  final AuthService _authService = AuthService();
  final ProductsService _productsService = ProductsService();
  final SupplierOrdersService _ordersService = SupplierOrdersService();
  Map<String, dynamic>? userProfile;
  int _productCount = 0;
  int _activeOrders = 0;
  double _monthlySales = 0.0;
  int _customersCount = 0;
  bool isLoading = true;
  String userStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final authService = AuthService();
      Map<String, dynamic>? profile = await authService.getCurrentUserProfile();
      
      if (profile != null) {
        setState(() {
          userProfile = profile;
          userStatus = profile['status'] ?? 'pending';
          isLoading = false;
        });
        
        // Load products and stats if supplier is approved
        if (userStatus == 'approved') {
          _loadProducts();
          _loadDashboardStats();
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        final products = await _productsService.getProductsBySupplier(userId);
        setState(() {
          _productCount = products.length;
        });
      }
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await _ordersService.getDashboardStats();
      setState(() {
        _activeOrders = stats['activeOrders'] ?? 0;
        _monthlySales = (stats['monthlySales'] ?? 0.0).toDouble();
        _customersCount = stats['customers'] ?? 0;
      });
    } catch (e) {
      print('Error loading dashboard stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingScreen();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade600,
              Colors.green.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with status
              _buildHeader(),
              
              // Main content based on status
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business,
                  size: 32,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile?['businessName'] ?? 'Your Business',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      userProfile?['email'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  await _authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                color: Colors.white,
                tooltip: AppLocale.logout.getString(context),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Status indicator
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (userStatus.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = AppLocale.approved.getString(context);
        statusDescription = AppLocale.accountActiveReady.getString(context);
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = AppLocale.rejected.getString(context);
        statusDescription = AppLocale.applicationRejected.getString(context);
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'PENDING APPROVAL';
        statusDescription = 'Your account is under review by our admin team.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  statusDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (userStatus.toLowerCase()) {
      case 'approved':
        return _buildApprovedContent();
      case 'rejected':
        return _buildRejectedContent();
      case 'pending':
      default:
        return _buildPendingContent();
    }
  }

  Widget _buildApprovedContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocale.businessDashboard.getString(context),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Quick stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppLocale.totalProducts.getString(context), 
                  '$_productCount', 
                  Icons.inventory, 
                  Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageProductsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  AppLocale.activeOrders.getString(context), 
                  '$_activeOrders', 
                  Icons.shopping_cart, 
                  Colors.blue,
                  onTap: () {
                    Navigator.pushNamed(context, '/supplier-orders');
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppLocale.monthlySales.getString(context), 
                  'RM ${_monthlySales.toStringAsFixed(2)}', 
                  Icons.trending_up, 
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  AppLocale.customers.getString(context), 
                  '$_customersCount', 
                  Icons.people, 
                  Colors.purple,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Action buttons
          Text(
            AppLocale.quickActions.getString(context),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildActionButton(
            AppLocale.manageProducts.getString(context),
            AppLocale.addEditRemoveProducts.getString(context),
            Icons.inventory_2,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageProductsScreen(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildActionButton(
            AppLocale.viewOrders.getString(context),
            AppLocale.checkManageCustomerOrders.getString(context),
            Icons.list_alt,
            () {
              Navigator.pushNamed(context, '/supplier-orders');
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildActionButton(
            AppLocale.businessProfile.getString(context),
            AppLocale.updateBusinessInformation.getString(context),
            Icons.business,
            () {
              Navigator.pushNamed(context, '/supplier-details');
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildActionButton(
            AppLocale.settings.getString(context),
            AppLocale.manageAppPreferences.getString(context),
            Icons.settings,
            () {
              Navigator.pushNamed(context, '/supplier-settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 80,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocale.accountUnderReviewTitle.getString(context),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocale.accountUnderReviewSupplier.getString(context),
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadUserProfile,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocale.refreshStatus.getString(context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cancel,
              size: 80,
              color: Colors.red.withOpacity(0.8),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocale.applicationRejectedTitle.getString(context),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocale.applicationNotApproved.getString(context),
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Contact support
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocale.contactSupport.getString(context))),
                    );
                  },
                  icon: const Icon(Icons.support_agent),
                  label: Text(AppLocale.contactSupport.getString(context)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/supplier-details');
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(AppLocale.updateProfile.getString(context)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}