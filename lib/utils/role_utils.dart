import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class RoleUtils {
  static final AuthService _authService = AuthService();

  /// Check if current user has the required role
  static Future<bool> hasRole(String requiredRole) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      Map<String, dynamic>? userProfile = await _authService.getCurrentUserProfile();
      if (userProfile == null) return false;

      String userRole = userProfile['role'] ?? '';
      return userRole == requiredRole;
    } catch (e) {
      print('❌ Error checking user role: $e');
      return false;
    }
  }

  /// Check if current user has any of the required roles
  static Future<bool> hasAnyRole(List<String> requiredRoles) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      Map<String, dynamic>? userProfile = await _authService.getCurrentUserProfile();
      if (userProfile == null) return false;

      String userRole = userProfile['role'] ?? '';
      return requiredRoles.contains(userRole);
    } catch (e) {
      print('❌ Error checking user roles: $e');
      return false;
    }
  }

  /// Get current user role
  static Future<String?> getCurrentUserRole() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      Map<String, dynamic>? userProfile = await _authService.getCurrentUserProfile();
      if (userProfile == null) return null;

      return userProfile['role'];
    } catch (e) {
      print('❌ Error getting user role: $e');
      return null;
    }
  }

  /// Check if current user is a farmer
  static Future<bool> isFarmer() async {
    return await hasRole('farmer');
  }

  /// Check if current user is a supplier
  static Future<bool> isSupplier() async {
    return await hasRole('supplier');
  }

  /// Check if current user is an admin
  static Future<bool> isAdmin() async {
    return await hasRole('admin');
  }

  /// Get redirect route for unauthorized access
  static Future<String> getRedirectRoute() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return '/login';

      Map<String, dynamic> result = await _authService.getUserProfileAndNavigationInfo(currentUser.uid);
      return result['navigationRoute'] ?? '/login';
    } catch (e) {
      print('❌ Error getting redirect route: $e');
      return '/login';
    }
  }
}