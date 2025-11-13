import 'package:flutter/material.dart';
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
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  supplier['full_name'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                subtitle: Text(
                  supplier['email'] ?? 'N/A',
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: Chip(
                  label: const Text('Pending', style: TextStyle(fontSize: 13)),
                  backgroundColor: scheme.tertiaryContainer,
                  labelStyle: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
              const SizedBox(height: 12),
              _infoRow('Company', supplier['company_name']),
              const SizedBox(height: 8),
              _infoRow('Phone', supplier['phone_number']),
              const SizedBox(height: 8),
              _infoRow('User ID', supplier['id']),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Close', style: TextStyle(fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.thumb_down, size: 18),
                      label: const Text('Reject', style: TextStyle(fontSize: 14)),
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
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.thumb_up, size: 18),
                      label: const Text('Approve', style: TextStyle(fontSize: 14)),
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

  Widget _infoRow(String label, dynamic value) {
    final v = (value ?? 'N/A').toString();
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            v.isEmpty ? 'N/A' : v,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
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
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final companyName = widget.supplier['company_name']?.toString().trim();
    final avatarChar = (companyName?.isNotEmpty == true ? companyName![0] : 'C').toUpperCase();

    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isExpanded ? scheme.primaryContainer.withOpacity(0.3) : null,
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  radius: 20,
                  child: Text(
                    avatarChar,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.supplier['full_name'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          widget.supplier['email'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _isExpanded = false);
                      widget.onReject();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _isExpanded = false);
                      widget.onApprove();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ],
              ),
            ],
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