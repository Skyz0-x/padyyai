import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Register new user with email and password
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    try {
      print('🔐 Starting user registration for: $email with role: $selectedRole');
      
      // Use Firebase Authentication to create a new user with email and password
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        print('✅ Firebase Auth registration successful for UID: ${user.uid}');
        
        // Create a new document in the 'users' collection in Cloud Firestore
        // The document ID should be the new user's UID (user.uid)
        Map<String, dynamic> userData = {
          'email': email,
          'role': selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Include 'status' as 'pending' if the role is 'supplier'
        if (selectedRole == 'supplier') {
          userData['status'] = 'pending';
          print('📋 Added pending status for supplier');
        }

        // Save user profile to Firestore
        await _firestore.collection('users').doc(user.uid).set(userData);
        print('✅ User document created in Firestore successfully');

        return {
          'success': true,
          'user': user,
          'role': selectedRole,
          'message': 'Registration successful!'
        };
      } else {
        throw Exception('User creation failed - user is null');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password is too weak. Please use at least 6 characters.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        default:
          errorMessage = 'Registration failed: ${e.message}';
      }
      return {
        'success': false,
        'message': errorMessage
      };
    } catch (e) {
      print('❌ Unexpected error during registration: $e');
      return {
        'success': false,
        'message': 'Registration failed. Please try again.'
      };
    }
  }

  // Update supplier profile with business details
  Future<Map<String, dynamic>> updateSupplierDetails({
    required String businessName,
    required String address,
    required String contactInfo,
    String? description,
  }) async {
    try {
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'User not logged in'
        };
      }

      print('📝 Updating supplier details for UID: ${currentUser.uid}');

      // Update the existing user document in the 'users' collection in Cloud Firestore
      // Add or update fields like 'businessName', 'address', 'contactInfo', etc.
      // The 'status' field should remain 'pending' at this stage
      Map<String, dynamic> updateData = {
        'businessName': businessName,
        'address': address,
        'contactInfo': contactInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (description != null && description.isNotEmpty) {
        updateData['description'] = description;
      }

      await _firestore.collection('users').doc(currentUser.uid).update(updateData);
      print('✅ Supplier details updated successfully');

      return {
        'success': true,
        'message': 'Business details updated successfully!'
      };
    } catch (e) {
      print('❌ Error updating supplier details: $e');
      return {
        'success': false,
        'message': 'Failed to update details. Please try again.'
      };
    }
  }

  // Login user with email and password
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Starting login for: $email');
      
      // Use Firebase Authentication to sign in the user with email and password
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        print('✅ Firebase Auth login successful for UID: ${user.uid}');
        
        // Fetch user profile and determine navigation
        Map<String, dynamic> profileResult = await getUserProfileAndNavigationInfo(user.uid);
        
        return {
          'success': true,
          'user': user,
          'profile': profileResult['profile'],
          'navigationRoute': profileResult['navigationRoute'],
          'message': 'Login successful!'
        };
      } else {
        throw Exception('Login failed - user is null');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }
      return {
        'success': false,
        'message': errorMessage
      };
    } catch (e) {
      print('❌ Unexpected error during login: $e');
      return {
        'success': false,
        'message': 'Login failed. Please try again.'
      };
    }
  }

  // Fetch user profile and determine navigation route
  Future<Map<String, dynamic>> getUserProfileAndNavigationInfo(String uid) async {
    try {
      print('📋 Fetching user profile for UID: $uid');
      
      // Fetch the user's profile document from the 'users' collection in Cloud Firestore using user.uid
      DocumentSnapshot docSnapshot = await _firestore.collection('users').doc(uid).get();
      
      if (docSnapshot.exists) {
        Map<String, dynamic> userData = docSnapshot.data() as Map<String, dynamic>;
        String role = userData['role'] ?? '';
        String status = userData['status'] ?? '';
        
        print('📋 User profile loaded - Role: $role, Status: $status');
        
        // Implement conditional navigation logic:
        String navigationRoute;
        
        if (role == 'admin') {
          // If role is 'admin', go to Admin Dashboard
          navigationRoute = '/admin-dashboard';
        } else if (role == 'farmer') {
          // If role is 'farmer', go to Main App (home with all features: detect, marketplace, profile)
          navigationRoute = '/home';
        } else if (role == 'supplier') {
          if (status == 'approved') {
            // If role is 'supplier' and status is 'approved', go to Supplier Dashboard
            navigationRoute = '/supplier-dashboard';
          } else if (status == 'pending') {
            // If role is 'supplier' and status is 'pending', go to Supplier Pending Approval screen
            navigationRoute = '/supplier-pending';
          } else if (status == 'rejected') {
            // If role is 'supplier' and status is 'rejected', go to Supplier Dashboard to see rejection
            navigationRoute = '/supplier-dashboard';
          } else {
            // If supplier but no details filled or unknown status, go to details form
            navigationRoute = '/supplier-details';
          }
        } else {
          // Default fallback - send to main app
          navigationRoute = '/home';
        }
        
        return {
          'profile': userData,
          'navigationRoute': navigationRoute
        };
      } else {
        print('❌ User document not found in Firestore');
        throw Exception('User profile not found');
      }
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      throw Exception('Failed to load user profile');
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) return null;
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user profile: $e');
      return null;
    }
  }

  // Logout user
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      throw Exception('Failed to sign out');
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _firebaseAuth.currentUser != null;
  }

  // Admin functions for supplier management
  Future<List<Map<String, dynamic>>> getPendingSuppliers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'supplier')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting pending suppliers: $e');
      throw Exception('Failed to load pending suppliers');
    }
  }

  Future<Map<String, dynamic>> updateSupplierStatus({
    required String supplierUid,
    required String status, // 'approved' or 'rejected'
    String? adminNote,
  }) async {
    try {
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'Admin not logged in'
        };
      }

      print('🔐 Attempting status update with admin: ${currentUser.uid}');

      // Verify admin has admin role
      Map<String, dynamic>? adminProfile = await getCurrentUserProfile();
      if (adminProfile == null || adminProfile['role'] != 'admin') {
        return {
          'success': false,
          'message': 'Insufficient permissions - admin role required'
        };
      }

      print('✅ Admin verification passed: ${adminProfile['email']}');

      // Prepare update data
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedBy': currentUser.uid,
        'reviewedByEmail': adminProfile['email'],
        'reviewedAt': FieldValue.serverTimestamp(),
      };

      if (adminNote != null && adminNote.isNotEmpty) {
        updateData['adminNote'] = adminNote;
      }

      print('📝 Updating supplier $supplierUid with data: $updateData');

      // Try to update with admin privileges
      try {
        await _firestore.collection('users').doc(supplierUid).update(updateData);
        print('✅ Direct Firestore update successful');
      } catch (firestoreError) {
        print('⚠️ Direct update failed: $firestoreError');
        
        // If direct update fails due to permissions, try alternative approach
        if (firestoreError.toString().contains('permission')) {
          print('🔄 Trying admin-privileged update...');
          
          // Alternative: Use admin SDK approach by getting the document first
          DocumentSnapshot supplierDoc = await _firestore.collection('users').doc(supplierUid).get();
          
          if (!supplierDoc.exists) {
            throw Exception('Supplier document not found');
          }
          
          // Try batch write or transaction
          WriteBatch batch = _firestore.batch();
          batch.update(_firestore.collection('users').doc(supplierUid), updateData);
          await batch.commit();
          
          print('✅ Batch update successful');
        } else {
          rethrow;
        }
      }

      print('✅ Supplier status updated to: $status');
      return {
        'success': true,
        'message': 'Supplier status updated successfully'
      };
    } catch (e) {
      print('❌ Error updating supplier status: $e');
      
      // Provide specific error messages
      String errorMessage = 'Failed to update supplier status';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check Firestore security rules for admin access.';
      } else if (e.toString().contains('not-found')) {
        errorMessage = 'Supplier not found in database.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      
      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString()
      };
    }
  }

  // Alternative update method using admin's own document write permissions
  Future<Map<String, dynamic>> updateSupplierStatusAlternative({
    required String supplierUid,
    required String status,
    String? adminNote,
  }) async {
    try {
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'Admin not logged in'
        };
      }

      // Verify admin role
      Map<String, dynamic>? adminProfile = await getCurrentUserProfile();
      if (adminProfile == null || adminProfile['role'] != 'admin') {
        return {
          'success': false,
          'message': 'Insufficient permissions - admin role required'
        };
      }

      // Create admin action record that triggers supplier update
      String adminActionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await _firestore.collection('admin_actions').doc(adminActionId).set({
        'action': 'update_supplier_status',
        'supplierUid': supplierUid,
        'newStatus': status,
        'adminUid': currentUser.uid,
        'adminEmail': adminProfile['email'],
        'adminNote': adminNote,
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,
      });

      // Also try direct update (this might work if rules allow admin)
      try {
        await _firestore.collection('users').doc(supplierUid).update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
          'reviewedBy': currentUser.uid,
          'reviewedByEmail': adminProfile['email'],
          'reviewedAt': FieldValue.serverTimestamp(),
          'adminNote': adminNote,
        });
        
        // Mark admin action as processed
        await _firestore.collection('admin_actions').doc(adminActionId).update({
          'processed': true,
          'processedAt': FieldValue.serverTimestamp(),
        });
        
        return {
          'success': true,
          'message': 'Supplier status updated successfully'
        };
      } catch (directUpdateError) {
        print('⚠️ Direct update failed, admin action recorded: $directUpdateError');
        return {
          'success': false,
          'message': 'Admin action recorded but direct update failed. Please check Firestore security rules.',
          'requiresManualAction': true,
          'adminActionId': adminActionId,
        };
      }
    } catch (e) {
      print('❌ Error in alternative update method: $e');
      return {
        'success': false,
        'message': 'Failed to process admin action: ${e.toString()}'
      };
    }
  }

  // Method to provide Firestore rules guidance
  String getFirestoreRulesGuidance() {
    return '''
To allow admin users to approve/reject suppliers, add these Firestore security rules:

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow admin users to read/write any user document
      allow read, write: if request.auth != null && 
        get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.role == 'admin';
    }
    
    // Allow admin actions collection for admins
    match /admin_actions/{actionId} {
      allow read, write: if request.auth != null && 
        get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.role == 'admin';
    }
  }
}
''';
  }

  Future<Map<String, dynamic>> getSupplierStats() async {
    try {
      // Get counts for each supplier status
      QuerySnapshot pendingSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'supplier')
          .where('status', isEqualTo: 'pending')
          .get();

      QuerySnapshot approvedSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'supplier')
          .where('status', isEqualTo: 'approved')
          .get();

      QuerySnapshot rejectedSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'supplier')
          .where('status', isEqualTo: 'rejected')
          .get();

      return {
        'pending': pendingSnapshot.docs.length,
        'approved': approvedSnapshot.docs.length,
        'rejected': rejectedSnapshot.docs.length,
        'total': pendingSnapshot.docs.length + approvedSnapshot.docs.length + rejectedSnapshot.docs.length,
      };
    } catch (e) {
      print('❌ Error getting supplier stats: $e');
      return {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'total': 0,
      };
    }
  }

  // Show toast message
  static void showToast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}