import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';

import '../utils/theme_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;
  bool _isTogglingBiometric = false;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  Future<void> _showLogoutDialog() async {
    final isDark = context.read<ThemeService>().isDarkMode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(isDark),
        title: Text(
          'Logout',
          style: TextStyle(color: AppTheme.getTextColor(isDark)),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppTheme.getTextColor(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = context.read<SupabaseAuthService>();
      await authService.logout();
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _toggleBiometricLock(bool enabled) async {
    if (_isTogglingBiometric) return;

    setState(() => _isTogglingBiometric = true);

    final biometricService = BiometricService();
    final success = await biometricService.setBiometricEnabled(enabled);

    if (mounted) {
      setState(() => _isTogglingBiometric = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled ? 'Biometric lock enabled' : 'Biometric lock disabled',
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      } else if (enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to enable biometric lock'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    final textColor = AppTheme.getTextColor(isDark);
    final cardColor = AppTheme.getCardColor(isDark);
    final biometricService = BiometricService();

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.getBackgroundColor(isDark),
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security Section
            const Text(
              'Security',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        biometricService.hasFingerprint
                            ? Icons.fingerprint
                            : Icons.face,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    title: Text(
                      'Biometric Lock',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      biometricService.canCheckBiometrics
                          ? 'Require ${biometricService.biometricTypeLabel} to open app'
                          : 'Not available on this device',
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: _isTogglingBiometric
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch(
                            value: biometricService.isBiometricEnabled,
                            onChanged: biometricService.canCheckBiometrics
                                ? _toggleBiometricLock
                                : null,
                            activeTrackColor: AppTheme.primaryGreen,
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // About Section
            const Text(
              'About',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    title: 'App Name',
                    value: _packageInfo?.appName ?? 'GKK Admin',
                    icon: Icons.apps,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    title: 'Version',
                    value: _packageInfo?.version ?? '-',
                    icon: Icons.info_outline,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    title: 'Build Number',
                    value: _packageInfo?.buildNumber ?? '-',
                    icon: Icons.build_circle_outlined,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    title: 'Package Name',
                    value: _packageInfo?.packageName ?? '-',
                    icon: Icons.code,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Section
            const Text(
              'Account',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    title: 'Sync',
                    value: 'Last synced: Now',
                    icon: Icons.sync,
                    isDark: isDark,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Syncing data...')),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout, color: Colors.red),
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: _showLogoutDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryGreen),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.getTextColor(isDark),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
    );
  }
}
