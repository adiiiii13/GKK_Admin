import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/services.dart';

import 'utils/theme_constants.dart';
import 'widgets/widgets.dart';
import 'screens/login.dart';
import 'screens/admin_verification_screen.dart';
import 'screens/dashboard.dart';
import 'screens/auth_screen.dart';
import 'screens/details_screens.dart';
import 'screens/notifier_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/banner_manager_screen.dart';
import 'screens/support_monitor_screen.dart';
import 'screens/agent_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Services
  final storageService = LocalStorageService();
  await storageService.init();

  final themeService = ThemeService();
  await themeService.init();

  final notificationService = NotificationService();

  final authService = SupabaseAuthService();
  await authService.init();

  final mainDbService = MainDatabaseService();
  mainDbService.init();

  // Initialize Biometric Service
  final biometricService = BiometricService();
  await biometricService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => storageService),
        ChangeNotifierProvider(create: (_) => themeService),
        ChangeNotifierProvider(create: (_) => notificationService),
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => mainDbService),
        ChangeNotifierProvider(create: (_) => biometricService),
      ],
      child: const GkkAdminApp(),
    ),
  );
}

class GkkAdminApp extends StatefulWidget {
  const GkkAdminApp({super.key});

  @override
  State<GkkAdminApp> createState() => _GkkAdminAppState();
}

class _GkkAdminAppState extends State<GkkAdminApp> with WidgetsBindingObserver {
  bool _showSplash = true;
  bool _needsBiometricAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reset biometric auth when app goes to background
    if (state == AppLifecycleState.paused) {
      final biometricService = BiometricService();
      biometricService.resetAuthState();
      if (biometricService.isBiometricEnabled) {
        setState(() => _needsBiometricAuth = true);
      }
    }
  }

  void _onSplashComplete() {
    final biometricService = BiometricService();
    setState(() {
      _showSplash = false;
      _needsBiometricAuth = biometricService.requiresAuthentication;
    });
  }

  Future<void> _authenticateBiometric() async {
    final biometricService = BiometricService();
    final authenticated = await biometricService.authenticate();
    if (authenticated) {
      setState(() => _needsBiometricAuth = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AnimatedSplashScreen(onAnimationComplete: _onSplashComplete),
      );
    }

    return Consumer2<SupabaseAuthService, ThemeService>(
      builder: (context, authService, themeService, _) {
        // Determine if user is logged in
        final isLoggedIn =
            authService.isLoggedIn || authService.checkLocalLogin();

        // Determine home screen
        Widget homeScreen;
        if (!isLoggedIn) {
          homeScreen = const AdminVerificationScreen();
        } else if (_needsBiometricAuth) {
          homeScreen = BiometricLockScreen(
            onAuthenticate: _authenticateBiometric,
          );
        } else {
          homeScreen = const DashboardScreen();
        }

        return ThemeSwitcher(
          child: MaterialApp(
            title: 'GKK Admin',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(
                ThemeData.light().textTheme,
              ),
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(
                ThemeData.dark().textTheme,
              ),
            ),
            themeMode: themeService.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: homeScreen,
            routes: {
              '/verification': (context) => const AdminVerificationScreen(),
              '/login': (context) => const LoginScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/auth': (context) => const AuthenticationScreen(),
              '/kitchens': (context) => const KitchensListScreen(),
              '/users': (context) => const UsersListScreen(),
              '/delivery': (context) => const DeliveryListScreen(),
              '/notifier': (context) => const NotifierScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/banners': (context) => const BannerManagerScreen(),
              '/support_monitor': (context) => const SupportMonitorScreen(),
              '/agent_management': (context) => const AgentManagementScreen(),
            },
          ),
        );
      },
    );
  }
}

/// Biometric Lock Screen - shown when app requires biometric authentication
class BiometricLockScreen extends StatelessWidget {
  final VoidCallback onAuthenticate;

  const BiometricLockScreen({Key? key, required this.onAuthenticate})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final biometricService = BiometricService();

    // Auto-trigger authentication on build
    WidgetsBinding.instance.addPostFrameCallback((_) => onAuthenticate());

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6ED),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2da832).withValues(alpha: 0.1),
              ),
              child: Icon(
                biometricService.hasFingerprint
                    ? Icons.fingerprint
                    : Icons.face,
                size: 80,
                color: const Color(0xFF2da832),
              ),
            ),
            const SizedBox(height: 40),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF2da832), Color(0xFFc2941b)],
              ).createShader(bounds),
              child: const Text(
                'GKK Admin',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Authenticate to continue',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: onAuthenticate,
              icon: Icon(
                biometricService.hasFingerprint
                    ? Icons.fingerprint
                    : Icons.face,
              ),
              label: Text('Unlock with ${biometricService.biometricTypeLabel}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2da832),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
