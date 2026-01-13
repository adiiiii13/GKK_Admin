import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_constants.dart';
import '../widgets/widgets.dart';
import '../services/services.dart';

/// Admin Verification Gate Screen
/// Candidates must enter their Admin ID and Password (received from Super Admin)
/// After verification, validates that login email matches registration email
/// before they can access the login/signup screen.
class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _adminIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _checkBiometricAutoLogin();
  }

  Future<void> _checkBiometricAutoLogin() async {
    // Small delay to let UI settle
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final storage = Provider.of<LocalStorageService>(context, listen: false);
    if (storage.isBiometricEnabled) {
      _attemptBiometricUnlock();
    }
  }

  Future<void> _attemptBiometricUnlock() async {
    final authenticated = await BiometricService().authenticate();
    if (authenticated && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  void dispose() {
    _adminIdController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _verifyCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<SupabaseAuthService>(
        context,
        listen: false,
      );

      // Use the login function directly with Admin ID and Password
      // The login function now supports both phone and Admin ID formats
      final result = await authService.login(
        phone: _adminIdController.text.trim(), // Admin ID goes here
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        if (result.success) {
          // Check if Google Sign-In is required
          // For now, we assume ALL admins must verify with Google
          // In future, we can check a flag 'google_verified' in user profile

          await _handleGoogleVerification(authService.currentAdmin?.email);
        } else {
          _showErrorSnackBar(result.message);
        }
      }
    } catch (e) {
      debugPrint('Verification Error: $e');
      _showErrorSnackBar('Verification failed. Please try again.');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleVerification(String? adminEmail) async {
    // 1. Show info dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Google Verification Required'),
        content: const Text(
          'To ensure security, please verify your identity with Google.\n'
          'The email must match your registered Admin email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // 2. Trigger Google Sign-In
    final googleResult = await GoogleAuthService().signInWithGoogle();

    if (!mounted) return;

    if (!googleResult.success) {
      _showErrorSnackBar('Google verification failed: ${googleResult.message}');
      return;
    }

    // 3. Verify Emails match
    final googleEmail = googleResult.user?.email;
    final registeredEmail =
        adminEmail ??
        Provider.of<LocalStorageService>(context, listen: false).adminEmail;

    if (googleEmail == null || registeredEmail == null) {
      _showErrorSnackBar('Could not verify email addresses.');
      return;
    }

    if (googleEmail.toLowerCase() != registeredEmail.toLowerCase()) {
      _showErrorSnackBar(
        'Email mismatch!\nGoogle: $googleEmail\nRegistered: $registeredEmail',
      );
      // Sign out context
      await GoogleAuthService().signOut();
      return;
    }

    // 4. Success - Proceed
    // Enroll biometric if needed
    await _handleBiometricEnrollment();
  }

  Future<void> _handleBiometricEnrollment() async {
    final storage = Provider.of<LocalStorageService>(context, listen: false);
    if (!storage.isBiometricEnabled) {
      final canCheck = BiometricService().isDeviceSupported;
      if (canCheck && mounted) {
        // Show enrollment dialog
        final enable = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enable Biometric Unlock?'),
            content: const Text(
              'Would you like to use your fingerprint or face to unlock the app next time?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );

        if (enable == true) {
          await storage.setBiometricEnabled(true);
        }
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE63946),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF1F2544),
                  ]
                : [
                    const Color(0xFF2da832).withValues(alpha: 0.1),
                    const Color(0xFFFAF6ED),
                    const Color(0xFFc2941b).withValues(alpha: 0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogoSection(isDark),
                      const SizedBox(height: 48),
                      _buildVerificationCard(isDark),
                      const SizedBox(height: 24),
                      _buildInfoSection(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2da832), Color(0xFF4DBF55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2da832).withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.verified_user, size: 64, color: Colors.white),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF2da832), Color(0xFFc2941b)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'GKK Admin',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Admin Verification',
          style: TextStyle(
            fontSize: 16,
            color: isDark
                ? Colors.grey.shade400
                : Colors.black.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCard(bool isDark) {
    return GradientCard(
      color: AppTheme.getCardColor(isDark),
      padding: const EdgeInsets.all(28),
      onTap: null,
      enableHoverEffect: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2da832).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2da832).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF2da832),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enter the Admin ID and Password provided by Super Admin',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade300 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Admin ID field
            _buildTextField(
              controller: _adminIdController,
              label: 'Admin ID',
              hint: 'e.g., admin:gkk:042',
              icon: Icons.badge_outlined,
              isDark: isDark,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Admin ID is required';
                if (!value!.startsWith('admin:gkk:')) {
                  return 'Invalid Admin ID format';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password field
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'e.g., Ab123@',
              icon: Icons.lock_outline,
              isDark: isDark,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF2da832),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Password is required';
                if (value!.length < 6) return 'Invalid password';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Verify button
            AnimatedButton(
              text: 'Verify & Continue',
              onPressed: _verifyCredentials,
              isLoading: _isLoading,
              icon: Icons.arrow_forward,
            ),

            // Biometric Unlock Button
            Consumer<LocalStorageService>(
              builder: (context, storage, _) {
                if (storage.isBiometricEnabled) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton.icon(
                      onPressed: _attemptBiometricUnlock,
                      icon: const Icon(
                        Icons.fingerprint,
                        color: Color(0xFF2da832),
                      ),
                      label: const Text(
                        'Unlock with Biometrics',
                        style: TextStyle(color: Color(0xFF2da832)),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(fontSize: 16, color: AppTheme.getTextColor(isDark)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2da832)),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: isDark
              ? Colors.grey.shade400
              : Colors.black.withValues(alpha: 0.6),
        ),
        hintStyle: TextStyle(
          color: isDark
              ? Colors.grey.shade600
              : Colors.black.withValues(alpha: 0.3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.grey.shade700
                : Colors.black.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2da832), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE63946), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE63946), width: 2),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF111827) : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildInfoSection(bool isDark) {
    return Column(
      children: [
        Text(
          "Don't have Admin credentials?",
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? Colors.grey.shade400
                : Colors.black.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Apply at admin.gkk.com',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF2da832),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
