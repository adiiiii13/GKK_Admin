import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Biometric Authentication Service for GKK Admin App
///
/// Provides fingerprint/face unlock functionality with:
/// - Enable/disable biometric lock
/// - Authenticate on app open
/// - Graceful fallback when biometrics unavailable
/// - Web platform is not supported (graceful fallback)
class BiometricService extends ChangeNotifier {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  SharedPreferences? _prefs;

  bool _isInitialized = false;
  bool _isBiometricEnabled = false;
  bool _canCheckBiometrics = false;
  bool _isDeviceSupported = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isAuthenticated = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get canCheckBiometrics => _canCheckBiometrics;
  bool get isDeviceSupported => _isDeviceSupported;
  bool get isAuthenticated => _isAuthenticated;
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  bool get hasFaceId => _availableBiometrics.contains(BiometricType.face);
  bool get hasFingerprint =>
      _availableBiometrics.contains(BiometricType.fingerprint);
  bool get hasStrongBiometrics =>
      _availableBiometrics.contains(BiometricType.strong);

  String get biometricTypeLabel {
    if (hasFaceId) return 'Face ID';
    if (hasFingerprint) return 'Fingerprint';
    if (hasStrongBiometrics) return 'Biometric';
    return 'Biometric Lock';
  }

  /// Initialize the biometric service
  Future<void> init() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Biometric features are not supported on web platform
    if (kIsWeb) {
      debugPrint('⚠️ BiometricService: Web platform detected - biometrics not supported');
      _isDeviceSupported = false;
      _canCheckBiometrics = false;
      _isBiometricEnabled = false;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      // Check if device supports biometrics
      _isDeviceSupported = await _localAuth.isDeviceSupported();

      // Check if biometrics can be checked (enrolled)
      _canCheckBiometrics = await _localAuth.canCheckBiometrics;

      // Get available biometric types
      _availableBiometrics = await _localAuth.getAvailableBiometrics();

      // Load saved preference
      _isBiometricEnabled = _prefs?.getBool('biometric_lock_enabled') ?? false;

      debugPrint('✅ BiometricService initialized:');
      debugPrint('   Device supported: $_isDeviceSupported');
      debugPrint('   Can check biometrics: $_canCheckBiometrics');
      debugPrint('   Available: $_availableBiometrics');
      debugPrint('   Enabled: $_isBiometricEnabled');
    } on PlatformException catch (e) {
      debugPrint('❌ BiometricService init error: $e');
      _isDeviceSupported = false;
      _canCheckBiometrics = false;
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Enable or disable biometric lock
  Future<bool> setBiometricEnabled(bool enabled) async {
    // Web platform does not support biometrics
    if (kIsWeb) {
      debugPrint('⚠️ Cannot enable biometrics - web platform not supported');
      return false;
    }
    
    if (enabled && !_canCheckBiometrics) {
      debugPrint('⚠️ Cannot enable biometrics - not available');
      return false;
    }

    if (enabled) {
      // Verify user can authenticate before enabling
      final authenticated = await authenticate(
        reason: 'Verify your identity to enable biometric lock',
      );

      if (!authenticated) {
        debugPrint('⚠️ Biometric verification failed - not enabling');
        return false;
      }
    }

    _isBiometricEnabled = enabled;
    await _prefs?.setBool('biometric_lock_enabled', enabled);

    if (enabled) {
      _isAuthenticated = true; // Already authenticated when enabling
    }

    debugPrint('✅ Biometric lock ${enabled ? 'enabled' : 'disabled'}');
    notifyListeners();
    return true;
  }

  /// Authenticate using biometrics
  ///
  /// Returns true if authenticated successfully, false otherwise.
  /// If biometrics are not enabled, returns true (no lock).
  Future<bool> authenticate({
    String reason = 'Authenticate to access GKK Admin',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    // Web platform does not support biometrics
    if (kIsWeb) {
      debugPrint('⚠️ Biometrics not supported on web');
      return false;
    }
    
    // We enforce availability check, but NOT the enabled check.
    // If the caller calls this, they WANT authentication (even if enabling).
    if (!_canCheckBiometrics || !_isDeviceSupported) {
      debugPrint('⚠️ Biometrics not available, skipping auth');
      return false; // Fail safe if hardware not available
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          useErrorDialogs: useErrorDialogs,
          biometricOnly: true,
        ),
      );

      // Only update state if authenticated (don't set to false if cancelled, let caller decide)
      if (authenticated) {
        _isAuthenticated = true;
        notifyListeners();
      }

      debugPrint(
        authenticated
            ? '✅ Biometric authentication successful'
            : '❌ Biometric authentication failed',
      );

      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('❌ Biometric auth error: ${e.message}');

      // Handle specific errors
      if (e.code == 'NotAvailable') {
        // Biometrics not available anymore (e.g., user disabled)
        _isBiometricEnabled = false;
        await _prefs?.setBool('biometric_lock_enabled', false);
        notifyListeners();
      }

      return false;
    }
  }

  /// Reset authentication state (call on app pause/minimize)
  void resetAuthState() {
    if (_isBiometricEnabled) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  /// Check if biometric authentication is required
  bool get requiresAuthentication => _isBiometricEnabled && !_isAuthenticated;

  /// Mark as authenticated (for use after successful biometric check)
  void markAuthenticated() {
    _isAuthenticated = true;
    notifyListeners();
  }
}
