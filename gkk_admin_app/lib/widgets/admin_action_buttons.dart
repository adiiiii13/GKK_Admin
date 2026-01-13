import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../utils/theme_constants.dart';

class AdminActionButtons extends StatelessWidget {
  final UserModel user;
  final bool isDark;

  const AdminActionButtons({
    super.key,
    required this.user,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (user.status == VerificationStatus.rejected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(top: 24),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.block, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Access Revoked',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This user has been banned from the platform.',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _restoreAccess(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Restore Access'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(isDark),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showWarningDialog(context),
                  icon: const Icon(Icons.warning_amber_rounded, size: 20),
                  label: const Text('Issue Warning'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRevokeDialog(context),
                  icon: const Icon(Icons.block, size: 20),
                  label: const Text('Revoke Access'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 24),
          if (user.warnings.isNotEmpty) ...[
            Text(
              'Admin Log',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(isDark),
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: user.warnings.length,
              reverse: true, // Show newest top
              itemBuilder: (context, index) {
                final warning = user.warnings[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Warning Issued',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          Text(
                            warning.date.toLocal().toString().split('.')[0],
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        warning.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.getTextColor(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By: ${warning.adminName}',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No prior warnings or administrative actions.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _restoreAccess(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(isDark),
        title: Text(
          'Restore Access?',
          style: TextStyle(color: AppTheme.getTextColor(isDark)),
        ),
        content: Text(
          'This will allow ${user.name} to login and use the app again.',
          style: TextStyle(
            color: isDark ? Colors.grey.shade300 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Provider.of<MainDatabaseService>(
        context,
        listen: false,
      ).restoreUser(user.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Restored Successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _showRevokeDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(isDark),
        title: const Text(
          'Revoke Access?',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          'Are you sure you want to revoke access for ${user.name}? They will be logged out immediately.',
          style: TextStyle(
            color: isDark ? Colors.grey.shade300 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Revoke Access',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Provider.of<MainDatabaseService>(
        context,
        listen: false,
      ).revokeUser(user.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User Access Revoked'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showWarningDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(isDark),
        title: Text(
          'Issue Warning',
          style: TextStyle(color: AppTheme.getTextColor(isDark)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send a formal warning to ${user.name}.',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: TextStyle(color: AppTheme.getTextColor(isDark)),
              decoration: InputDecoration(
                hintText: 'Enter warning message...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final adminName = Provider.of<LocalStorageService>(
                  context,
                  listen: false,
                ).adminName;

                await Provider.of<MainDatabaseService>(
                  context,
                  listen: false,
                ).addWarning(user.id, controller.text.trim(), adminName);

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Warning sent to ${user.name}'),
                      backgroundColor: Colors.orange.shade800,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            child: const Text(
              'Send Warning',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(isDark),
        title: const Text(
          'Delete User Permanently?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to PERMANENTLY delete ${user.name}?',
              style: TextStyle(
                color: isDark ? Colors.grey.shade300 : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone. All user data will be erased and they will need to create a new account to sign in.',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
            child: const Text(
              'Delete Forever',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );

        await Provider.of<MainDatabaseService>(
          context,
          listen: false,
        ).deleteUser(user.id);

        if (context.mounted) {
          // Pop loading dialog
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: Colors.red,
            ),
          );
          // Go back to list
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          // Pop loading dialog
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
