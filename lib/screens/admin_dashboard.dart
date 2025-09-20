import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> pendingSuppliers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingSuppliers();
  }

  Future<void> _loadPendingSuppliers() async {
    try {
      print('🔍 Loading pending suppliers from database...');
      
      // Get current user to verify admin permissions
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }
      
      print('👤 Current user: ${currentUser.email}');
      
      // Try the most basic query first - just get all users
      QuerySnapshot allUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
          
      print('📊 Total users accessible: ${allUsersSnapshot.docs.length}');
      
      if (allUsersSnapshot.docs.isEmpty) {
        throw Exception('No users found in database - check Firestore permissions');
      }
      
      // Filter for suppliers manually
      List<Map<String, dynamic>> allSuppliers = [];
      List<Map<String, dynamic>> pendingSuppliersOnly = [];
      
      for (var doc in allUsersSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        
        print('📋 User: ${data['email']} | Role: ${data['role']} | Status: ${data['status']}');
        
        if (data['role'] == 'supplier') {
          allSuppliers.add(data);
          if (data['status'] == 'pending') {
            pendingSuppliersOnly.add(data);
          }
        }
      }
      
      print('📊 Total suppliers found: ${allSuppliers.length}');
      print('📊 Pending suppliers found: ${pendingSuppliersOnly.length}');

      setState(() {
        pendingSuppliers = pendingSuppliersOnly;
        
        // Sort manually by createdAt if available
        pendingSuppliers.sort((a, b) {
          if (a['createdAt'] != null && b['createdAt'] != null) {
            return b['createdAt'].compareTo(a['createdAt']);
          }
          return 0;
        });
        
        isLoading = false;
      });
      
      print('✅ Successfully loaded ${pendingSuppliers.length} pending suppliers');
      
      if (pendingSuppliers.isEmpty && allSuppliers.isNotEmpty) {
        // Show message that there are suppliers but none pending
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${allSuppliers.length} suppliers, but none are pending approval'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      
    } catch (e) {
      print('❌ Error loading pending suppliers: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      
      setState(() {
        isLoading = false;
      });
      
      // Show user-friendly error message
      if (mounted) {
        String errorMessage = 'Database access error: $e';
        if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please check Firestore security rules for admin access.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _debugDatabaseQuery() async {
    try {
      print('🔍 DEBUG: Starting comprehensive database check...');
      
      // Get all users to see what's in the database
      QuerySnapshot allUsers = await FirebaseFirestore.instance
          .collection('users')
          .get();
          
      print('📊 Total users in database: ${allUsers.docs.length}');
      
      Map<String, int> roleCount = {};
      Map<String, int> statusCount = {};
      
      for (var doc in allUsers.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'unknown';
        String status = data['status'] ?? 'unknown';
        
        roleCount[role] = (roleCount[role] ?? 0) + 1;
        statusCount[status] = (statusCount[status] ?? 0) + 1;
        
        print('👤 User ${doc.id}: email=${data['email']}, role=$role, status=$status');
      }
      
      print('📈 Role breakdown: $roleCount');
      print('📈 Status breakdown: $statusCount');
      
      // Show results in a dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Database Debug Results'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total Users: ${allUsers.docs.length}'),
                    const SizedBox(height: 8),
                    const Text('Roles:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...roleCount.entries.map((e) => Text('  ${e.key}: ${e.value}')),
                    const SizedBox(height: 8),
                    const Text('Statuses:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...statusCount.entries.map((e) => Text('  ${e.key}: ${e.value}')),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('❌ Debug query failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateSupplierStatus(String uid, String status, String businessName) async {
    try {
      print('🔄 Admin updating supplier status: $uid -> $status');
      
      // Verify admin authentication
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Admin not authenticated');
      }
      
      // Get admin profile to verify role
      Map<String, dynamic>? adminProfile = await _authService.getCurrentUserProfile();
      if (adminProfile == null || adminProfile['role'] != 'admin') {
        throw Exception('Insufficient permissions - admin role required');
      }
      
      print('👤 Admin verified: ${adminProfile['email']}');
      
      // Now that Firestore rules are updated, use direct update method
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedBy': currentUser.uid,
        'reviewedByEmail': adminProfile['email'],
        'reviewedAt': FieldValue.serverTimestamp(),
        'adminNote': 'Status updated by admin: ${adminProfile['email']}',
      });

      print('✅ Supplier status updated successfully via Firestore');
      
      // Remove from pending list
      setState(() {
        pendingSuppliers.removeWhere((supplier) => supplier['uid'] == uid);
      });

      // Show success message
      String message = status == 'approved' 
          ? '✅ Supplier "$businessName" has been approved!'
          : '❌ Supplier "$businessName" has been rejected.';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  status == 'approved' ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Refresh the supplier list to get updated counts
      _loadPendingSuppliers();
      
    } catch (e) {
      print('❌ Error updating supplier status: $e');
      
      String errorMessage = 'Failed to update supplier status.';
      String technicalDetails = '';
      
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please verify Firestore rules are correctly set.';
        technicalDetails = 'The admin user needs write access to the users collection.';
      } else if (e.toString().contains('admin role required')) {
        errorMessage = 'Only admin users can approve/reject suppliers.';
        technicalDetails = 'Current user does not have admin role.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
        technicalDetails = 'Unable to connect to Firestore database.';
      } else if (e.toString().contains('not-found')) {
        errorMessage = 'Supplier not found in database.';
        technicalDetails = 'The supplier document may have been deleted.';
      } else {
        technicalDetails = e.toString();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                if (technicalDetails.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(technicalDetails, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _updateSupplierStatus(uid, status, businessName),
            ),
          ),
        );
      }
    }
  }



  void _showSupplierDetails(Map<String, dynamic> supplier) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(supplier['businessName'] ?? 'Supplier Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', supplier['email'] ?? 'N/A'),
                _buildDetailRow('Business Name', supplier['businessName'] ?? 'N/A'),
                _buildDetailRow('Address', supplier['address'] ?? 'N/A'),
                _buildDetailRow('Contact Info', supplier['contactInfo'] ?? 'N/A'),
                _buildDetailRow('Description', supplier['description'] ?? 'No description provided'),
                const SizedBox(height: 8),
                Text(
                  'Registration Date: ${_formatDate(supplier['createdAt'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _updateSupplierStatus(supplier['uid'], 'rejected', supplier['businessName'] ?? 'Unknown');
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _updateSupplierStatus(supplier['uid'], 'approved', supplier['businessName'] ?? 'Unknown');
              },
              icon: const Icon(Icons.check),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      if (timestamp is Timestamp) {
        DateTime date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
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
              Colors.indigo.shade600,
              Colors.indigo.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.admin_panel_settings,
              size: 32,
              color: Colors.indigo.shade600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Manage Supplier Applications',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
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
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Loading pending suppliers...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (pendingSuppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Pending Applications Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Checking database for supplier applications...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _loadPendingSuppliers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _debugDatabaseQuery,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Debug Database'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Statistics
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pending_actions,
                color: Colors.orange.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${pendingSuppliers.length} Pending Application${pendingSuppliers.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Supplier list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: pendingSuppliers.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> supplier = pendingSuppliers[index];
              return _buildSupplierCard(supplier);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> supplier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showSupplierDetails(supplier),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business,
                        color: Colors.orange.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier['businessName'] ?? 'Unknown Business',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            supplier['email'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'PENDING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                if (supplier['address'] != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          supplier['address'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Applied: ${_formatDate(supplier['createdAt'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showSupplierDetails(supplier),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Review'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.indigo.shade600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateSupplierStatus(
                          supplier['uid'], 
                          'rejected', 
                          supplier['businessName'] ?? 'Unknown'
                        ),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateSupplierStatus(
                          supplier['uid'], 
                          'approved', 
                          supplier['businessName'] ?? 'Unknown'
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
    );
  }
}