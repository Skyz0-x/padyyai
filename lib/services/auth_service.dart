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