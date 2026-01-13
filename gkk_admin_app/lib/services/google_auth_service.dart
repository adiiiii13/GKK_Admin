import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result type for authentication operations
typedef AuthResult = ({bool success, String message, User? user});

/// Production-ready Google Authentication Service for Gharkakhana.app
///
/// Uses native ID Token flow with Supabase integration.
/// Redirect URL: io.supabase.gharkakhana://login-callback
class GoogleAuthService {
  // Singleton pattern
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // Web Client ID for Google Sign-In (OAuth 2.0 handshake)
  static const String _webClientId =
      '471367005406-dvt9rq7v1q8i5df3f5mmsqg9rd22uhol.apps.googleusercontent.com';

  // Supabase Redirect URL scheme
  static const String redirectScheme = 'io.supabase.gharkakhana';
  static const String redirectHost = 'login-callback';
  static const String redirectUrl = '$redirectScheme://$redirectHost';

  // Google Sign-In instance configured with server client ID
  late final GoogleSignIn _googleSignIn;

  // Supabase client reference
  SupabaseClient get _supabase => Supabase.instance.client;

  // Current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Initialize the service
  void initialize() {
    _googleSignIn = GoogleSignIn(
      serverClientId: _webClientId,
      scopes: ['email', 'profile'],
    );
    debugPrint('✅ GoogleAuthService initialized');
  }

  /// Sign in with Google using native ID Token flow
  ///
  /// This method:
  /// 1. Initiates Google Sign-In
  /// 2. Obtains ID Token and Access Token
  /// 3. Authenticates with Supabase using signInWithIdToken
  ///
  /// Returns [AuthResult] with success status, message, and optional user
  Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Google Sign-In...');

      // Step 1: Trigger native Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in flow
      if (googleUser == null) {
        debugPrint('⚠️ User cancelled Google Sign-In');
        return (
          success: false,
          message: 'Sign-in was cancelled by user',
          user: null,
        );
      }

      debugPrint('👤 Google user: ${googleUser.email}');

      // Step 2: Obtain authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      // Validate ID Token (required for Supabase)
      if (idToken == null) {
        debugPrint('❌ No ID Token received from Google');
        return (
          success: false,
          message: 'Failed to obtain ID Token from Google. Please try again.',
          user: null,
        );
      }

      debugPrint('🎫 ID Token obtained successfully');
      debugPrint(
        '🎫 Access Token: ${accessToken != null ? 'Present' : 'Not present'}',
      );

      // Step 3: Authenticate with Supabase using ID Token
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken:
            accessToken, // Optional but recommended for full token exchange
      );

      final Session? session = response.session;
      final User? user = response.user;

      // Validate Supabase session
      if (session == null || user == null) {
        debugPrint('❌ Supabase session creation failed');
        return (
          success: false,
          message: 'Failed to create session. Please try again.',
          user: null,
        );
      }

      debugPrint('✅ Supabase authentication successful');
      debugPrint('👤 User ID: ${user.id}');
      debugPrint('📧 Email: ${user.email}');

      return (
        success: true,
        message: 'Successfully signed in with Google',
        user: user,
      );
    } on PlatformException catch (e) {
      // Handle platform-specific errors
      return _handlePlatformException(e);
    } on AuthException catch (e) {
      // Handle Supabase authentication errors
      debugPrint('❌ Supabase Auth Error: ${e.message}');
      return (
        success: false,
        message: 'Authentication failed: ${e.message}',
        user: null,
      );
    } catch (e, stackTrace) {
      // Handle any other unexpected errors
      debugPrint('❌ Unexpected error during Google Sign-In: $e');
      debugPrint('📜 Stack trace: $stackTrace');
      return (
        success: false,
        message: 'An unexpected error occurred. Please try again.',
        user: null,
      );
    }
  }

  /// Handle PlatformException with specific error codes
  AuthResult _handlePlatformException(PlatformException e) {
    debugPrint('❌ PlatformException: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'sign_in_canceled':
        return (success: false, message: 'Sign-in was cancelled', user: null);

      case 'sign_in_failed':
        // Check for developer configuration errors
        if (e.message?.contains('DEVELOPER_ERROR') == true ||
            e.message?.contains('developer error') == true) {
          return (
            success: false,
            message:
                'Configuration error: Please verify SHA-1/SHA-256 fingerprints and package name in Google Cloud Console.',
            user: null,
          );
        }
        return (
          success: false,
          message: 'Sign-in failed. Please check your internet connection.',
          user: null,
        );

      case 'network_error':
        return (
          success: false,
          message:
              'Network error. Please check your internet connection and try again.',
          user: null,
        );

      case 'popup_closed_by_user':
        return (
          success: false,
          message: 'Sign-in popup was closed',
          user: null,
        );

      case 'access_denied':
        return (
          success: false,
          message: 'Access was denied. Please grant the necessary permissions.',
          user: null,
        );

      case 'invalid_client':
        return (
          success: false,
          message: 'Invalid client configuration. Please contact support.',
          user: null,
        );

      default:
        return (
          success: false,
          message: 'Sign-in error: ${e.message ?? 'Unknown error'}',
          user: null,
        );
    }
  }

  /// Sign out from both Google and Supabase
  Future<AuthResult> signOut() async {
    try {
      debugPrint('🚪 Signing out...');

      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Supabase
      await _supabase.auth.signOut();

      debugPrint('✅ Successfully signed out');

      return (success: true, message: 'Successfully signed out', user: null);
    } on PlatformException catch (e) {
      debugPrint('❌ Sign out PlatformException: ${e.message}');
      return (
        success: false,
        message: 'Failed to sign out: ${e.message}',
        user: null,
      );
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      return (
        success: false,
        message: 'Failed to sign out. Please try again.',
        user: null,
      );
    }
  }

  /// Disconnect Google account (revokes access)
  ///
  /// Use this when user wants to completely remove the connection.
  /// This will require re-authorization on next sign-in.
  Future<AuthResult> disconnect() async {
    try {
      debugPrint('🔌 Disconnecting Google account...');

      // Disconnect from Google (revokes tokens)
      await _googleSignIn.disconnect();

      // Sign out from Supabase
      await _supabase.auth.signOut();

      debugPrint('✅ Successfully disconnected');

      return (
        success: true,
        message: 'Successfully disconnected Google account',
        user: null,
      );
    } catch (e) {
      debugPrint('❌ Disconnect error: $e');
      return (
        success: false,
        message: 'Failed to disconnect. Please try again.',
        user: null,
      );
    }
  }

  /// Check if user is currently signed in to Google
  Future<bool> isGoogleSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Silently sign in if already authenticated
  ///
  /// Returns the current user if a valid session exists.
  /// This is useful for restoring sessions on app startup.
  Future<AuthResult> signInSilently() async {
    try {
      debugPrint('🔄 Attempting silent sign-in...');

      // Check Supabase session first
      final Session? session = _supabase.auth.currentSession;
      if (session != null) {
        debugPrint('✅ Existing Supabase session found');
        return (success: true, message: 'Session restored', user: currentUser);
      }

      // Try Google silent sign-in
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signInSilently();

      if (googleUser == null) {
        debugPrint('ℹ️ No cached Google credentials');
        return (
          success: false,
          message: 'No cached credentials found',
          user: null,
        );
      }

      // If we have Google credentials, do full sign-in
      return signInWithGoogle();
    } catch (e) {
      debugPrint('❌ Silent sign-in error: $e');
      return (success: false, message: 'Silent sign-in failed', user: null);
    }
  }

  /// Listen to authentication state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Get the current user's metadata
  Map<String, dynamic>? get userMetadata => currentUser?.userMetadata;

  /// Get user's email
  String? get userEmail => currentUser?.email;

  /// Get user's display name from metadata
  String? get userName =>
      userMetadata?['full_name'] ?? userMetadata?['name'] ?? currentUser?.email;

  /// Get user's avatar URL from metadata
  String? get userAvatarUrl =>
      userMetadata?['avatar_url'] ?? userMetadata?['picture'];
}
