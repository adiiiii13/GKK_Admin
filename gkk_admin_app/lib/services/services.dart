import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';

export 'notification_service.dart';
export 'supabase_auth_service.dart';
export 'google_auth_service.dart';
export 'biometric_service.dart';
export '../models/app_models.dart';

// =======================
// SERVICES
// =======================

class LocalStorageService extends ChangeNotifier {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late SharedPreferences _prefs;

  // Admin Profile Data
  String _adminName = "Admin User";
  String _adminPhone = "";
  String? _adminEmail;
  String? _adminImage;

  String get adminName => _adminName;
  String get adminPhone => _adminPhone;
  String? get adminEmail => _adminEmail;
  String? get adminImage => _adminImage;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAdminProfile();
  }

  bool isLoggedIn() {
    return _prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool('isLoggedIn', value);
    notifyListeners();
  }

  void _loadAdminProfile() {
    _adminName = _prefs.getString('admin_name') ?? "Admin User";
    _adminPhone = _prefs.getString('admin_phone') ?? "";
    _adminEmail = _prefs.getString('admin_email');
    _adminImage = _prefs.getString('admin_image');
    notifyListeners();
  }

  Future<void> updateAdminProfile(
    String name,
    String phone,
    String? image, {
    String? email,
  }) async {
    _adminName = name;
    _adminPhone = phone;
    _adminEmail = email ?? _adminEmail;
    _adminImage = image;

    await _prefs.setString('admin_name', name);
    await _prefs.setString('admin_phone', phone);
    if (email != null) await _prefs.setString('admin_email', email);
    if (image != null) await _prefs.setString('admin_image', image);

    notifyListeners();
  }

  // Biometric Preferences
  bool get isBiometricEnabled => _prefs.getBool('biometric_enabled') ?? false;

  Future<void> setBiometricEnabled(bool value) async {
    await _prefs.setBool('biometric_enabled', value);
    notifyListeners();
  }
}

class MainDatabaseService extends ChangeNotifier {
  static final MainDatabaseService _instance = MainDatabaseService._internal();
  factory MainDatabaseService() => _instance;
  MainDatabaseService._internal();

  SupabaseClient? _client;

  bool get isInitialized => _client != null;

  /// Get the Supabase client for direct queries
  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'MainDatabaseService not initialized. Call init() first.',
      );
    }
    return _client!;
  }

  Future<void> init() async {
    // HARDCODED CREDENTIALS FOR DEBUGGING (GKK Basic - SAME KEY AS USER APP)
    const url = 'https://mwnpwuxrbaousgwgoyco.supabase.co';
    const key = 'sb_publishable_FKT03rJkxcGCSjXCV2xfeA_bX1jmJD8';

    try {
      _client = SupabaseClient(url, key);
      debugPrint(
        '✅ MainDatabaseService initialized with HARDCODED credentials',
      );
    } catch (e) {
      debugPrint('❌ MainDatabaseService init error: $e');
    }
  }

  // --- Users & Delivery Agents Fetching ---

  Future<List<UserModel>> fetchUsers({
    UserRole? role,
    VerificationStatus? status,
  }) async {
    if (_client == null) {
      debugPrint('❌ Client is null in fetchUsers');
      return [];
    }

    try {
      // Simple select from users table - IGNORING FILTERS FOR DEBUG
      final response = await _client!.from('users').select('*');

      debugPrint('✅ fetchUsers raw response count: ${response.length}');

      return (response as List).map((e) {
        try {
          return UserModel.fromJson(e);
        } catch (parseError) {
          debugPrint('❌ Parse Error for user ${e['id']}: $parseError');
          // Return a safe fallback user
          return UserModel(
            id: e['id'] ?? 'unknown',
            name: e['full_name'] ?? e['name'] ?? 'Parse Error',
            email: e['email'] ?? 'error',
            phone: '',
            role: UserRole.customer,
            dateApplied: DateTime.now(),
          );
        }
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching users: $e');
      return [];
    }
  }

  Future<void> updateUserStatus(
    String userId,
    VerificationStatus status,
  ) async {
    if (_client == null) return;

    try {
      await _client!
          .from('users')
          .update({
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user status: $e');
      rethrow;
    }
  }

  Future<void> addWarning(
    String userId,
    String message,
    String adminName,
  ) async {
    if (_client == null) return;

    try {
      // In a real schema, this might be a separate table 'user_warnings'
      // For now, we assume a JSONB column 'warnings' in users table or similar
      // Or we can create a separate table logic here.
      // Based on the dual-database plan, we will just simulate for now if tables don't exist
      // or assume a warnings table.

      // Let's assume a separate 'user_warnings' table exists in the main DB
      await _client!.from('user_warnings').insert({
        'user_id': userId,
        'message': message,
        'admin_name': adminName,
        'created_at': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding warning: $e');
    }
  }

  // --- Kitchen specific ---

  Future<void> toggleFoodItemStatus(
    String kitchenId,
    String foodItemId,
    bool isEnabled,
  ) async {
    if (_client == null) return;

    try {
      // Assuming 'menu_items' table
      await _client!
          .from('menu_items')
          .update({'is_enabled': isEnabled})
          .eq('id', foodItemId)
          .eq('kitchen_id', kitchenId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling food item: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    if (_client == null) return;

    try {
      await _client!.from('users').delete().eq('id', userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  /// Revoke user access - sets is_banned flag so User App can detect and logout
  Future<void> revokeUser(String userId) async {
    if (_client == null) return;

    try {
      await _client!
          .from('users')
          .update({
            'status': 'rejected',
            'is_banned': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error revoking user: $e');
      rethrow;
    }
  }

  /// Restore user access
  Future<void> restoreUser(String userId) async {
    if (_client == null) return;

    try {
      await _client!
          .from('users')
          .update({
            'status': 'verified',
            'is_banned': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error restoring user: $e');
      rethrow;
    }
  }
}
