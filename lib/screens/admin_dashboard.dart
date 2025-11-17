import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/products_service.dart';
import '../utils/constants.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  final ProductsService _productsService = ProductsService();
  List<Map<String, dynamic>> _pendingSuppliers = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _query = '';
  int _totalProducts = 0;
  int _inStock = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingSuppliers();
    _loadProductStats();
  }

  Future<void> _loadProductStats() async {
    try {
      final products = await _productsService.getAllProducts();
      setState(() {
        _totalProducts = products.length;
        _inStock = products.where((p) => p['in_stock'] == true).length;
      });
    } catch (e) {
      print('Error loading product stats: $e');
    }
  }

  Future<void> _loadPendingSuppliers() async {
    try {
      if (!_isRefreshing) {
        setState(() {
          _isLoading = true;
        });
      }
      final suppliers = await _authService.getPendingSuppliers();
      setState(() {
        _pendingSuppliers = suppliers;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suppliers: $e')),
        );
      }
    }
  }

  Future<void> _confirmAndUpdate(String userId, String status) async {
    final isApprove = status == 'approved';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isApprove ? 'Approve supplier?' : 'Reject supplier?'),
          content: Text(
            isApprove
                ? 'Are you sure you want to approve this supplier?'
                : 'Are you sure you want to reject this supplier?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: isApprove ? Colors.green : Colors.red,
              ),
              child: Text(isApprove ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _updateSupplierStatus(userId, status);
  }

  Future<void> _updateSupplierStatus(String userId, String status) async {
    try {
      if (status == 'approved') {
        await _authService.approveSupplier(userId);
      } else {
        await _authService.rejectSupplier(userId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Supplier $status successfully')),
        );
      }
      _loadPendingSuppliers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating supplier: $e')),
        );
      }
    }
  }

  void _openSupplierSheet(Map<String, dynamic> supplier) {
    final scheme = Theme.of(context).colorScheme;
    
    // Debug: Print supplier data
    print('📋 Supplier Data:');
    supplier.forEach((key, value) {
      print('  $key: $value');
    });
    
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Avatar and Status
              Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      (supplier['full_name'] ?? 'N/A')
                          .toString()
                          .trim()
                          .isNotEmpty
                          ? supplier['full_name'].toString().trim()[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier['full_name'] ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                supplier['email'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Pending Approval',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              
              // Business Information Section
              _buildSectionHeader(Icons.business, 'Business Information', scheme),
              const SizedBox(height: 12),
              if (supplier['business_name'] != null && supplier['business_name'].toString().isNotEmpty)
                Column(
                  children: [
                    _buildDetailCard(
                      icon: Icons.store,
                      label: 'Company Name',
                      value: supplier['business_name'],
                      scheme: scheme,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              if (supplier['business_type'] != null && supplier['business_type'].toString().isNotEmpty)
                Column(
                  children: [
                    _buildDetailCard(
                      icon: Icons.category,
                      label: 'Business Type',
                      value: supplier['business_type'],
                      scheme: scheme,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              if (supplier['business_address'] != null && supplier['business_address'].toString().isNotEmpty)
                Column(
                  children: [
                    _buildDetailCard(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: supplier['business_address'],
                      scheme: scheme,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              _buildDetailCard(
                icon: Icons.phone,
                label: 'Phone Number',
                value: supplier['phone'] ?? 'N/A',
                scheme: scheme,
              ),
              if (supplier['gst_number'] != null && supplier['gst_number'].toString().isNotEmpty)
                Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildDetailCard(
                      icon: Icons.receipt_long,
                      label: 'GST Number',
                      value: supplier['gst_number'],
                      scheme: scheme,
                    ),
                  ],
                ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Products & Services Section
              _buildSectionHeader(Icons.inventory, 'Products & Services', scheme),
              const SizedBox(height: 12),
              if (supplier['products_offered'] != null && supplier['products_offered'].toString().isNotEmpty)
                Column(
                  children: [
                    _buildDetailCard(
                      icon: Icons.shopping_bag,
                      label: 'Products Offered',
                      value: supplier['products_offered'],
                      scheme: scheme,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              if (supplier['business_description'] != null && supplier['business_description'].toString().isNotEmpty)
                _buildDetailCard(
                  icon: Icons.description,
                  label: 'Business Description',
                  value: supplier['business_description'],
                  scheme: scheme,
                  maxLines: 4,
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No products or business description provided yet',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Certificate Section
              _buildSectionHeader(Icons.verified, 'SSM Certificate', scheme),
              const SizedBox(height: 12),
              if (supplier['certificate_url'] != null && supplier['certificate_url'].toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Certificate uploaded and ready for verification',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _viewCertificate(supplier['certificate_url']);
                          },
                          icon: const Icon(Icons.open_in_new, size: 20),
                          label: const Text('View Certificate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No SSM certificate uploaded - Cannot approve without certificate',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              
              // System Information
              _buildSectionHeader(Icons.info_outline, 'System Information', scheme),
              const SizedBox(height: 12),
              _buildDetailCard(
                icon: Icons.fingerprint,
                label: 'User ID',
                value: supplier['id'] ?? 'N/A',
                scheme: scheme,
              ),
              const SizedBox(height: 8),
              _buildDetailCard(
                icon: Icons.calendar_today,
                label: 'Registration Date',
                value: supplier['created_at'] != null 
                    ? _formatDate(supplier['created_at'])
                    : 'N/A',
                scheme: scheme,
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmAndUpdate(supplier['id'], 'rejected');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.cancel, size: 20),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmAndUpdate(supplier['id'], 'approved');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, ColorScheme scheme) {
    return Row(
      children: [
        Icon(icon, color: scheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme scheme,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _viewCertificate(String certificateUrl) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              // Image viewer
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      certificateUrl,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red.shade700),
                              const SizedBox(height: 16),
                              const Text(
                                'Failed to load certificate',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error: ${error.toString()}',
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Download/Open externally button
              Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  onPressed: () async {
                    final Uri url = Uri.parse(certificateUrl);
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open certificate'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _pendingSuppliers;
    return _pendingSuppliers.where((s) {
      return (s['email'] ?? '').toString().toLowerCase().contains(q) ||
          (s['full_name'] ?? '').toString().toLowerCase().contains(q) ||
          (s['company_name'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
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
              _buildHeader(context),
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
                      _buildSearchBar(context),
                      Expanded(child: _buildSuppliersList(context)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  size: 32,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Manage suppliers & products',
                      style: TextStyle(
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
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
                icon: const Icon(Icons.logout),
                color: Colors.white,
                tooltip: 'Logout',
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Products',
                  _totalProducts.toString(),
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'In Stock',
                  _inStock.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  _pendingSuppliers.length.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      height: 105,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              leading: const Icon(Icons.search, size: 20),
              hintText: 'Search suppliers...',
              hintStyle: const WidgetStatePropertyAll(
                TextStyle(fontSize: 14),
              ),
              textStyle: const WidgetStatePropertyAll(
                TextStyle(fontSize: 14),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: () async {
              setState(() {
                _isRefreshing = true;
              });
              await _loadPendingSuppliers();
              await _loadProductStats();
            },
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersList(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return _ShimmerList();
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isRefreshing = true;
        });
        await _loadPendingSuppliers();
        await _loadProductStats();
      },
      child: _filtered.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Icon(Icons.inbox_outlined, size: 80, color: scheme.outline),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'No pending supplier requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Pull down to refresh or adjust your search.',
                    style: TextStyle(color: scheme.outline, fontSize: 14),
                  ),
                ),
              ],
            )
          : ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final supplier = _filtered[index];
                return _SupplierTile(
                  supplier: supplier,
                  onTap: () => _openSupplierSheet(supplier),
                  onApprove: () => _confirmAndUpdate(supplier['id'], 'approved'),
                  onReject: () => _confirmAndUpdate(supplier['id'], 'rejected'),
                );
              },
            ),
    );
  }
}

class _SupplierTile extends StatefulWidget {
  final Map<String, dynamic> supplier;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _SupplierTile({
    required this.supplier,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_SupplierTile> createState() => _SupplierTileState();
}

class _SupplierTileState extends State<_SupplierTile> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    // Get display name - prioritize full_name, then business_name, then email
    String displayName = 'Unknown Supplier';
    if (widget.supplier['full_name']?.toString().trim().isNotEmpty ?? false) {
      displayName = widget.supplier['full_name'].toString().trim();
    } else if (widget.supplier['business_name']?.toString().trim().isNotEmpty ?? false) {
      displayName = widget.supplier['business_name'].toString().trim();
    } else if (widget.supplier['email']?.toString().trim().isNotEmpty ?? false) {
      displayName = widget.supplier['email'].toString().trim().split('@')[0];
    }
    
    final avatarChar = displayName[0].toUpperCase();
    final email = widget.supplier['email']?.toString() ?? 'No email';
    final hasCertificate = widget.supplier['certificate_url']?.toString().isNotEmpty ?? false;

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: hasCertificate ? Colors.green.shade100 : Colors.orange.shade100,
              child: Text(
                avatarChar,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: hasCertificate ? Colors.green.shade800 : Colors.orange.shade800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasCertificate)
                        Icon(Icons.verified, color: Colors.green.shade700, size: 20)
                      else
                        Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasCertificate ? 'Certificate uploaded • Tap to review' : 'No certificate • Tap to view details',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasCertificate ? Colors.green.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    final highlight = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.1, 0.3, 0.6],
            ),
          ),
        );
      },
    );
  }
}