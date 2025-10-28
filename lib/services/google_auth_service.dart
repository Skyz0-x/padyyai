import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/supabase_config.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  static final SupabaseClient _supabase = SupabaseConfig.client;

  /// Sign in with Google
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google auth tokens');
      }

      // Sign in to Supabase with Google provider
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      // Create or update user profile if sign in successful
      if (response.user != null) {
        await _createOrUpdateUserProfile(response.user!, googleUser);
      }
      
      return response;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  /// Create or update user profile in Supabase
  static Future<void> _createOrUpdateUserProfile(User user, GoogleSignInAccount googleUser) async {
    try {
      // Check if user profile already exists
      final existingProfile = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Create new user profile
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email ?? googleUser.email,
          'full_name': user.userMetadata?['full_name'] ?? googleUser.displayName,
          'role': 'farmer', // Default role for Google sign-in
          'status': 'approved',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('✅ Created user profile for Google sign-in: ${user.email}');
      } else {
        // Update existing profile with latest info
        await _supabase.from('users').update({
          'full_name': user.userMetadata?['full_name'] ?? googleUser.displayName,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
        print('✅ Updated user profile for Google sign-in: ${user.email}');
      }
    } catch (e) {
      print('❌ Error creating/updating user profile: $e');
      // Don't rethrow here as the auth was successful
    }
  }

  /// Sign out from Google and Supabase
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _supabase.auth.signOut(),
      ]);
      print('✅ Successfully signed out from Google and Supabase');
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }

  /// Check if user is currently signed in with Google
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      print('Error checking sign-in status: $e');
      return false;
    }
  }

  /// Get current Google user
  static GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }
}
