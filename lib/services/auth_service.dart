import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      // Clean and validate email
      final cleanEmail = email.trim().toLowerCase();
      
      // Validate email format before sending to Supabase
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(cleanEmail)) {
        return {
          'success': false,
          'error': 'Invalid email format: $cleanEmail',
        };
      }
      
      print('🔐 Starting user registration for: $cleanEmail with role: ${metadata['role']}');
      print('📧 Original email: "$email"');
      print('📧 Clean email: "$cleanEmail"');
      print('📧 Email length: ${cleanEmail.length}');
      print('📧 Email validation: ${emailRegex.hasMatch(cleanEmail)}');
      
      // Test email before sending to Supabase
      if (cleanEmail == 'farmer1@gmail.com') {
        print('🧪 Testing specific email: farmer1@gmail.com');
        print('🧪 Character codes: ${cleanEmail.codeUnits}');
      }
      
      final response = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: metadata,
      );
      
      if (response.user != null) {
        print('✅ Supabase Auth registration successful for ID: ${response.user!.id}');
        
        // Create user profile in users table
        await _client.from('users').insert({
          'id': response.user!.id,
          'email': cleanEmail,
          'full_name': metadata['full_name'],
          'phone': metadata['phone'],
          'role': metadata['role'],
          'business_name': metadata['business_name'],
          'business_address': metadata['business_address'],
          'business_type': metadata['business_type'],
          'gst_number': metadata['gst_number'],
          'status': metadata['role'] == 'supplier' ? 'pending' : 'approved',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        print('📊 User profile created in database');
        
        return {
          'success': true,
          'user': response.user,
          'message': 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Registration failed - no user returned',
        };
      }
    } catch (e) {
      print('❌ Registration failed: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting sign in for: $email');
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        print('✅ Sign in successful for ID: ${response.user!.id}');
        
        // Get user profile and navigation info
        Map<String, dynamic> navInfo = await getUserProfileAndNavigationInfo(response.user!.id);
        
        return {
          'success': true,
          'user': response.user,
          'message': 'Sign in successful',
          'navigationRoute': navInfo['navigationRoute'],
          'profile': navInfo['userProfile'],
          'role': navInfo['role'],
          'status': navInfo['status'],
        };
      } else {
        return {
          'success': false,
          'message': 'Sign in failed - no user returned',
        };
      }
    } catch (e) {
      print('❌ Sign in failed: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Sign out failed: $e');
      rethrow;
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return {
        'success': true,
        'message': 'Password reset email sent',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get user profile and navigation info
  Future<Map<String, dynamic>> getUserProfileAndNavigationInfo(String userId) async {
    try {
      print('🔍 Getting user profile for ID: $userId');
      
      // Try to get user profile with error handling for RLS issues
      Map<String, dynamic>? response;
      try {
        final result = await _client
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();
        response = result;
      } catch (e) {
        print('❌ Error getting user profile: $e');
        // If RLS policy issue, create a basic profile entry
        if (e.toString().contains('infinite recursion') || e.toString().contains('policy')) {
          print('🔧 Attempting to create basic user profile...');
          try {
            await _client.from('users').upsert({
              'id': userId,
              'role': 'farmer', // Default role
              'status': 'approved',
              'created_at': DateTime.now().toIso8601String(),
            });
            
            // Try to fetch again
            final result = await _client
                .from('users')
                .select()
                .eq('id', userId)
                .maybeSingle();
            response = result;
          } catch (upsertError) {
            print('❌ Failed to create user profile: $upsertError');
            // Return default values if all else fails
            response = {
              'id': userId,
              'role': 'farmer',
              'status': 'approved',
            };
          }
        } else {
          rethrow;
        }
      }
      
      if (response == null) {
        print('⚠️ No user profile found, using defaults');
        response = {
          'id': userId,
          'role': 'farmer',
          'status': 'approved',
        };
      }
      
      String role = response['role'] ?? 'farmer';
      String status = response['status'] ?? 'approved';
      
      String navigationRoute;
      switch (role) {
        case 'admin':
          navigationRoute = '/admin-dashboard';
          break;
        case 'supplier':
          if (status == 'approved') {
            navigationRoute = '/supplier-dashboard';
          } else if (status == 'pending') {
            navigationRoute = '/supplier-pending';
          } else {
            navigationRoute = '/supplier-details'; // For rejected or incomplete profiles
          }
          break;
        case 'farmer':
        default:
          navigationRoute = '/home';
          break;
      }
      
      print('📊 User profile found - Role: $role, Status: $status, Route: $navigationRoute');
      
      return {
        'userProfile': response,
        'navigationRoute': navigationRoute,
        'role': role,
        'status': status,
      };
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return {
        'userProfile': null,
        'navigationRoute': '/login',
        'role': 'farmer',
        'status': 'pending',
      };
    }
  }

  // Register user (backward compatibility method)
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    return await signUp(
      email: email,
      password: password,
      metadata: {
        'role': selectedRole,
        'full_name': '',
        'phone': '',
        'business_name': '',
        'business_address': '',
        'business_type': '',
        'gst_number': '',
      },
    );
  }

  // Authenticate user (backward compatibility method)
  Future<Map<String, dynamic>> authenticateUser({
    required String email,
    required String password,
  }) async {
    return await signIn(email: email, password: password);
  }

  // Login user (backward compatibility method)
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    return await signIn(email: email, password: password);
  }

  // Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        final response = await _client
            .from('users')
            .select()
            .eq('id', currentUser.id)
            .single();
        return response;
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user profile: $e');
      return null;
    }
  }

  // Show toast message
  void showToast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Update supplier details
  Future<Map<String, dynamic>> updateSupplierDetails(String userId, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      
      await _client
          .from('users')
          .update(data)
          .eq('id', userId);
      
      return {
        'success': true,
        'message': 'Supplier details updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get pending suppliers (for admin dashboard)
  Future<List<Map<String, dynamic>>> getPendingSuppliers() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('role', 'supplier')
          .eq('status', 'pending');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting pending suppliers: $e');
      return [];
    }
  }

  // Approve supplier
  Future<Map<String, dynamic>> approveSupplier(String supplierId) async {
    try {
      await _client
          .from('users')
          .update({'status': 'approved', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', supplierId);
      
      return {
        'success': true,
        'message': 'Supplier approved successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Reject supplier
  Future<Map<String, dynamic>> rejectSupplier(String supplierId) async {
    try {
      await _client
          .from('users')
          .update({'status': 'rejected', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', supplierId);
      
      return {
        'success': true,
        'message': 'Supplier rejected',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}