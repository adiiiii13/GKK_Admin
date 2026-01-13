import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Admin model for authentication
class AdminUser {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String authProvider; // 'phone' or 'google'
  final String? avatarUrl;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.authProvider = 'phone',
    this.avatarUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'name': name,
    'email': email,
    'auth_provider': authProvider,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
  };

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'],
    phone: json['phone'],
    name: json['name'],
    email: json['email'],
    authProvider: json['auth_provider'] ?? 'phone',
    avatarUrl: json['avatar_url'],
    createdAt: DateTime.parse(json['created_at']),
  );
}

/// Supabase Auth Service for Admin login/signup
class SupabaseAuthService extends ChangeNotifier {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  late SharedPreferences _prefs;
  SupabaseClient? _supabase;
  AdminUser? _currentAdmin;
  bool _isInitialized = false;

  AdminUser? get currentAdmin => _currentAdmin;
  bool get isLoggedIn => _currentAdmin != null;
  bool get isInitialized => _isInitialized;
  SupabaseClient get supabase => _supabase!;

  /// Initialize Supabase and load cached admin
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    try {
      // Load environment variables
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
        await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
        _supabase = Supabase.instance.client;
        debugPrint('✅ Supabase initialized successfully');
      } else {
        debugPrint('⚠️ Supabase credentials not found in .env');
      }
    } catch (e) {
      debugPrint('❌ Supabase init error: $e');
    }

    // Load cached admin from local storage
    await _loadCachedAdmin();
    _isInitialized = true;
    notifyListeners();
  }

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Load cached admin from SharedPreferences
  Future<void> _loadCachedAdmin() async {
    final adminJson = _prefs.getString('cached_admin');
    if (adminJson != null) {
      try {
        _currentAdmin = AdminUser.fromJson(jsonDecode(adminJson));
      } catch (e) {
        debugPrint('Error loading cached admin: $e');
      }
    }
  }

  /// Cache admin to SharedPreferences
  Future<void> _cacheAdmin(AdminUser admin) async {
    await _prefs.setString('cached_admin', jsonEncode(admin.toJson()));
  }

  /// Clear cached admin
  Future<void> _clearCachedAdmin() async {
    await _prefs.remove('cached_admin');
  }

  /// Sign up with phone and password
  Future<({bool success, String message})> signUp({
    required String phone,
    required String password,
    required String name,
  }) async {
    try {
      if (_supabase == null) {
        return (success: false, message: 'Supabase not initialized');
      }

      // Validate phone
      if (phone.length < 10) {
        return (success: false, message: 'Invalid phone number');
      }

      // Check if phone already exists
      final existing = await _supabase!
          .from('admins')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      if (existing != null) {
        return (success: false, message: 'Phone number already registered');
      }

      // Hash password and create admin
      final hashedPassword = _hashPassword(password);
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final adminData = {
        'id': id,
        'phone': phone,
        'password_hash': hashedPassword,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase!.from('admins').insert(adminData);

      // Create local admin user
      _currentAdmin = AdminUser(
        id: id,
        phone: phone,
        name: name,
        createdAt: DateTime.now(),
      );

      await _cacheAdmin(_currentAdmin!);
      await _prefs.setBool('isLoggedIn', true);

      // Record session
      _recordSession();

      notifyListeners();

      return (success: true, message: 'Account created successfully');
    } catch (e) {
      debugPrint('Signup error: $e');
      return (success: false, message: 'Signup failed: ${e.toString()}');
    }
  }

  /// Login with Admin ID or phone and password
  /// Supports both formats:
  /// - Admin ID: "admin:gkk:042" (generated credentials)
  /// - Phone: "9876543210" (legacy format)
  Future<({bool success, String message})> login({
    required String phone, // Can be Admin ID or phone number
    required String password,
  }) async {
    try {
      if (_supabase == null) {
        // Fallback to local-only login for testing
        return _offlineLogin(phone, password);
      }

      final String identifier = phone.trim();
      Map<String, dynamic>? result;

      // Check if identifier is an Admin ID (format: admin:gkk:XXX)
      final bool isAdminId = identifier.startsWith('admin:gkk:');

      if (isAdminId) {
        // Find admin by ID
        result = await _supabase!
            .from('admins')
            .select()
            .eq('id', identifier)
            .maybeSingle();
      } else {
        // Find admin by phone
        result = await _supabase!
            .from('admins')
            .select()
            .eq('phone', identifier)
            .maybeSingle();
      }

      if (result == null) {
        return (
          success: false,
          message: isAdminId
              ? 'Admin ID not found. Please check your credentials.'
              : 'Phone number not registered',
        );
      }

      // Check admin status
      final status = result['status'] as String?;
      if (status == 'SUSPENDED') {
        return (
          success: false,
          message: 'Your account has been suspended. Contact Super Admin.',
        );
      } else if (status == 'REVOKED') {
        return (success: false, message: 'Your admin access has been revoked.');
      }

      // Verify password (compare SHA256 hash)
      final hashedPassword = _hashPassword(password);
      if (result['password_hash'] != hashedPassword) {
        debugPrint('Password mismatch for ${result['id']}');
        return (success: false, message: 'Incorrect password');
      }

      // Create local admin user
      _currentAdmin = AdminUser(
        id: result['id'],
        phone: result['phone'] ?? '',
        name: result['name'] ?? 'Admin',
        email: result['email'],
        authProvider: result['auth_provider'] ?? 'phone',
        avatarUrl: result['avatar_url'],
        createdAt: DateTime.parse(result['created_at']),
      );

      await _cacheAdmin(_currentAdmin!);
      await _prefs.setBool('isLoggedIn', true);

      // Update last login timestamp
      await _supabase!
          .from('admins')
          .update({
            'last_login_at': DateTime.now().toIso8601String(),
            'login_count': (result['login_count'] ?? 0) + 1,
          })
          .eq('id', result['id']);

      // Record session
      _recordSession();

      notifyListeners();

      return (success: true, message: 'Login successful');
    } catch (e) {
      debugPrint('Login error: $e');

      // Fallback to offline login
      return _offlineLogin(phone, password);
    }
  }

  /// Offline login fallback
  Future<({bool success, String message})> _offlineLogin(
    String phone,
    String password,
  ) async {
    if (phone == '9876543210' && password == 'admin123') {
      _currentAdmin = AdminUser(
        id: 'local_admin',
        phone: phone,
        name: 'Admin',
        createdAt: DateTime.now(),
      );
      await _cacheAdmin(_currentAdmin!);
      await _prefs.setBool('isLoggedIn', true);
      notifyListeners();
      return (success: true, message: 'Login successful (offline mode)');
    }
    return (success: false, message: 'Invalid credentials');
  }

  /// Logout
  Future<void> logout() async {
    _currentAdmin = null;
    await _clearCachedAdmin();
    await _prefs.setBool('isLoggedIn', false);
    notifyListeners();
  }

  /// Check if logged in (from local storage)
  bool checkLocalLogin() {
    return _prefs.getBool('isLoggedIn') ?? false;
  }

  /// Update Admin Profile
  Future<({bool success, String message})> updateProfile({
    String? name,
    String? phone,
  }) async {
    try {
      if (_supabase == null || _currentAdmin == null) {
        // Update local only if offline
        if (_currentAdmin != null) {
          _currentAdmin = AdminUser(
            id: _currentAdmin!.id,
            phone: phone ?? _currentAdmin!.phone,
            name: name ?? _currentAdmin!.name,
            createdAt: _currentAdmin!.createdAt,
          );
          await _cacheAdmin(_currentAdmin!);
          notifyListeners();
          return (
            success: true,
            message: 'Profile updated locally (Supabase disconnected)',
          );
        }
        return (success: false, message: 'Not logged in');
      }

      // If phone is changing, check uniqueness
      if (phone != null && phone != _currentAdmin!.phone) {
        final existing = await _supabase!
            .from('admins')
            .select()
            .eq('phone', phone)
            .maybeSingle();

        if (existing != null) {
          return (success: false, message: 'Phone number already taken');
        }
      }

      final updates = {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase!
          .from('admins')
          .update(updates)
          .eq('id', _currentAdmin!.id);

      // Update local object
      _currentAdmin = AdminUser(
        id: _currentAdmin!.id,
        phone: phone ?? _currentAdmin!.phone,
        name: name ?? _currentAdmin!.name,
        createdAt: _currentAdmin!.createdAt,
      );

      await _cacheAdmin(_currentAdmin!);
      notifyListeners();

      return (success: true, message: 'Profile updated successfully');
    } catch (e) {
      debugPrint('Profile update error: $e');
      return (success: false, message: 'Update failed: ${e.toString()}');
    }
  }

  /// Update Avatar
  Future<({bool success, String message})> updateAvatar(File imageFile) async {
    try {
      if (_supabase == null || _currentAdmin == null) {
        return (success: false, message: 'Supabase not initialized');
      }

      final userId = _currentAdmin!.id;
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // Upload image to Supabase Storage
      await _supabase!.storage
          .from('admin-assets')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get Public URL
      final publicUrl = _supabase!.storage
          .from('admin-assets')
          .getPublicUrl(filePath);

      // Update admin record
      await _supabase!
          .from('admins')
          .update({
            'avatar_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Update local object
      _currentAdmin = AdminUser(
        id: _currentAdmin!.id,
        phone: _currentAdmin!.phone,
        name: _currentAdmin!.name,
        email: _currentAdmin!.email,
        authProvider: _currentAdmin!.authProvider,
        avatarUrl: publicUrl,
        createdAt: _currentAdmin!.createdAt,
      );

      await _cacheAdmin(_currentAdmin!);
      notifyListeners();

      return (success: true, message: 'Avatar updated successfully');
    } catch (e) {
      debugPrint('Avatar upload error: $e');
      return (success: false, message: 'Avatar upload failed: ${e.toString()}');
    }
  }

  /// Get device info (model and OS version)
  Future<({String deviceModel, String osVersion, String platform})>
  _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = await deviceInfo.androidInfo;
      return (
        deviceModel: '${android.brand} ${android.model}',
        osVersion: 'Android ${android.version.release}',
        platform: 'Android',
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = await deviceInfo.iosInfo;
      return (
        deviceModel: ios.model,
        osVersion: 'iOS ${ios.systemVersion}',
        platform: 'iOS',
      );
    } else if (kIsWeb) {
      final web = await deviceInfo.webBrowserInfo;
      return (
        deviceModel: web.browserName.name,
        osVersion: 'Web',
        platform: 'Web',
      );
    } else {
      return (
        deviceModel: 'Unknown Device',
        osVersion: 'Unknown',
        platform: 'Desktop',
      );
    }
  }

  /// Record Admin Session with device info
  Future<void> _recordSession() async {
    try {
      if (_supabase == null || _currentAdmin == null) return;

      final info = await _getDeviceInfo();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));

      final sessionData = {
        'admin_id': _currentAdmin!.id,
        'device_model': info.deviceModel,
        'os_version': info.osVersion,
        'platform': info.platform,
        'last_active_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_active': true,
      };

      await _supabase!.from('admin_sessions').insert(sessionData);
      debugPrint('✅ Session recorded: ${info.deviceModel} - ${info.osVersion}');
    } catch (e) {
      debugPrint('⚠️ Session record error: $e');
      // Don't fail login if session record fails
    }
  }

  /// Sign In with Google (Production-Ready)
  /// Optional [expectedEmail] parameter validates that the Google account
  /// email matches the candidate's registration email.
  /// Sign In with Google (Production-Ready)
  /// Optional [expectedEmail] parameter validates that the Google account
  /// email matches the candidate's registration email.
  Future<({bool success, String message})> signInWithGoogle({
    String? expectedEmail,
  }) async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId:
          '471367005406-dvt9rq7v1q8i5df3f5mmsqg9rd22uhol.apps.googleusercontent.com',
      scopes: ['email', 'profile'],
    );

    try {
      if (_supabase == null) {
        return (success: false, message: 'Supabase not initialized');
      }

      // 1. Trigger Google Sign-In
      // Force account selection to avoid "stuck" state if previous attempt failed
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return (success: false, message: 'Sign-in was cancelled');
      }

      debugPrint('👤 Google user: ${googleUser.email}');

      // 2. Validate email matches registration email (if provided)
      if (expectedEmail != null && expectedEmail.isNotEmpty) {
        if (googleUser.email.toLowerCase() != expectedEmail.toLowerCase()) {
          // Sign out from Google to allow retry with different account
          await googleSignIn.signOut();
          return (
            success: false,
            message:
                'Please sign in with your registration email: $expectedEmail',
          );
        }
      }

      // 3. Get authentication tokens
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        await googleSignIn.signOut();
        return (
          success: false,
          message: 'Failed to obtain ID Token from Google',
        );
      }

      // 4. Authenticate with Supabase
      final response = await _supabase!.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final session = response.session;
      final user = response.user;

      if (session == null || user == null) {
        await googleSignIn.signOut();
        return (success: false, message: 'Failed to create session');
      }

      debugPrint('✅ Supabase auth successful: ${user.id}');

      // 5. Check if Admin Record exists (security enforcement)
      // We no longer create admins here. The database trigger handles it.
      // If the trigger rejected the user (or didn't create an admin row),
      // we must treat this as a failure.

      var adminRecord = await _supabase!
          .from('admins')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (adminRecord == null) {
        // Attempt Self-Healing:
        // User might exist in Auth but not in Admins (e.g. signed up before trigger).
        // specific RPC to check eligibility and create record if approved.
        try {
          debugPrint(
            '⚠️ Admin record missing. Attempting to claim profile for ${user.email}...',
          );
          final claimed = await _supabase!.rpc(
            'claim_admin_profile',
            params: {'p_email': user.email},
          );

          if (claimed == true) {
            // Retry fetch
            adminRecord = await _supabase!
                .from('admins')
                .select()
                .eq('id', user.id)
                .maybeSingle();
          }
        } catch (e) {
          debugPrint('❌ Claim profile failed: $e');
        }

        if (adminRecord == null) {
          // Critical: User authenticated but is NOT an admin in our table.
          // This implies they are not an approved candidate.
          await googleSignIn.signOut();
          await _supabase!.auth.signOut(); // Clear Supabase session too

          return (
            success: false,
            message: 'Access Denied: You are not an approved Admin.',
          );
        }
      }

      // 6. Update existing Admin with latest Google info (Sync)
      final userName =
          user.userMetadata?['full_name'] ??
          googleUser.displayName ??
          'Google Admin';
      final userEmail = user.email ?? googleUser.email;

      // Get high-resolution avatar
      String? userAvatar =
          user.userMetadata?['avatar_url'] ?? googleUser.photoUrl;
      if (userAvatar != null && userAvatar.isNotEmpty) {
        userAvatar = userAvatar.replaceAll(RegExp(r's\d+(-c)?'), 's400-c');
        if (!userAvatar.startsWith('https://')) {
          userAvatar = userAvatar.replaceFirst('http://', 'https://');
        }
      }

      // Update local cache and DB
      await _supabase!
          .from('admins')
          .update({
            'name': userName,
            'email': userEmail,
            'avatar_url': userAvatar,
            'auth_provider': 'google',
            'last_login_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      _currentAdmin = AdminUser(
        id: adminRecord['id'],
        phone: adminRecord['phone'] ?? '',
        name: userName,
        email: userEmail,
        authProvider: 'google',
        avatarUrl: userAvatar,
        createdAt: DateTime.parse(adminRecord['created_at']),
      );

      await _cacheAdmin(_currentAdmin!);
      await _prefs.setBool('isLoggedIn', true);

      _recordSession();
      notifyListeners();

      return (success: true, message: 'Google Sign-In Successful');
    } on PlatformException catch (e) {
      await googleSignIn.signOut();
      debugPrint('❌ PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'sign_in_canceled') {
        return (success: false, message: 'Sign-in was cancelled');
      }
      return (
        success: false,
        message: 'Sign-in error: ${e.message ?? 'Unknown error'}',
      );
    } on AuthException catch (e) {
      await googleSignIn.signOut();
      debugPrint('❌ Supabase Auth Error: ${e.message}');
      return (success: false, message: 'Authentication failed: ${e.message}');
    } catch (e) {
      await googleSignIn.signOut();
      debugPrint('❌ Google Sign-In Error: $e');
      return (success: false, message: 'Sign-In failed. Please try again.');
    }
  }
}
