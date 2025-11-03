import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _pendingSuppliers = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadPendingSuppliers();
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 22),
            tooltip: 'Logout',
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: scheme.surfaceContainerHighest,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? _ShimmerList()
                : RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _isRefreshing = true;
                      });
                      await _loadPendingSuppliers();
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
                  ),
          ),
        ],
      ),
      floatingActionButton: _filtered.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                setState(() {
                  _isRefreshing = true;
                });
                await _loadPendingSuppliers();
              },
              icon: const Icon(Icons.sync),
              label: const Text('Sync'),
            )
          : null,
    );
  }
}

class _SupplierTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fullName = supplier['full_name']?.toString().trim();
    final avatarChar = (fullName?.isNotEmpty == true ? fullName![0] : 'S').toUpperCase();

    return InkWell(
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            avatarChar,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          supplier['full_name'] ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              supplier['email'] ?? 'N/A',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              supplier['company_name'] ?? 'N/A',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 6,
          children: [
            OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: const Size(70, 40),
              ),
              child: const Text('Reject', style: TextStyle(fontSize: 13)),
            ),
            FilledButton(
              onPressed: onApprove,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: const Size(80, 40),
              ),
              child: const Text('Approve', style: TextStyle(fontSize: 13)),
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