import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../utils/theme_constants.dart';
import '../widgets/widgets.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<UserModel> _pendingUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() => _isLoading = true);
    final mainDb = Provider.of<MainDatabaseService>(context, listen: false);
    final users = await mainDb.fetchUsers(status: VerificationStatus.pending);

    if (mounted) {
      setState(() {
        _pendingUsers = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text(
          'Authentication Console',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingUsers,
          ),
          Builder(
            builder: (buttonContext) {
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  final box = buttonContext.findRenderObject() as RenderBox;
                  final position = box.localToGlobal(
                    Offset(box.size.width / 2, box.size.height / 2),
                  );
                  ThemeSwitcher.of(context).toggleTheme(position);
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.secondaryGold,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Delivery Agents'),
            Tab(text: 'Cloud Kitchens'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPendingUsers,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_pendingUsers, UserRole.delivery, isDark),
                  _buildList(_pendingUsers, UserRole.kitchen, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildList(List<UserModel> users, UserRole role, bool isDark) {
    final filtered = users.where((u) => u.role == role).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              role == UserRole.delivery
                  ? Icons.delivery_dining
                  : Icons.restaurant,
              size: 80,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              role == UserRole.delivery
                  ? 'No pending delivery agent requests'
                  : 'No pending kitchen requests',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final user = filtered[index];
        return _buildListItem(user, role, isDark);
      },
    );
  }

  // Compact list item - tap to open full profile
  Widget _buildListItem(UserModel user, UserRole role, bool isDark) {
    final isDelivery = role == UserRole.delivery;

    return Card(
      elevation: 0, // Flat elegant look with border
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      color: AppTheme.getCardColor(isDark),
      child: InkWell(
        onTap: () => _showProfileBottomSheet(user, role, isDark),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ProfileAvatar(
                imageUrl: user.profileImage,
                size: 50,
                heroTag: 'auth_list_${user.id}',
                fallbackIcon: isDelivery
                    ? Icons.delivery_dining
                    : Icons.restaurant,
                showGlow: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusBadge(
                label: 'PENDING',
                type: StatusType.pending,
                showPulse: true,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileBottomSheet(UserModel user, UserRole role, bool isDark) {
    final isDelivery = role == UserRole.delivery;

    final gradient = isDelivery
        ? AppTheme.greenGradient
        : AppTheme.goldGradient;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header with avatar
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ProfileAvatar(
                        imageUrl: user.profileImage,
                        size: 80,
                        heroTag: 'auth_modal_${user.id}',
                        showGlow: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const StatusBadge(
                        label: 'PENDING VERIFICATION',
                        type: StatusType.pending,
                        showPulse: true,
                      ),
                    ],
                  ),
                ),

                // Info section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.email_outlined,
                        'Email',
                        user.email,
                        isDark,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.phone_outlined,
                        'Phone',
                        user.phone,
                        isDark,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.calendar_today_outlined,
                        'Applied On',
                        user.dateApplied.toLocal().toString().split(' ')[0],
                        isDark,
                      ),

                      if (isDelivery && user.deliveryDetails != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1F2937)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFBBF7D0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vehicle Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailItem(
                                Icons.directions_bike,
                                'Vehicle No.',
                                user.deliveryDetails!.vehicleNumber,
                                isDark,
                              ),
                              const SizedBox(height: 8),
                              _buildDetailItem(
                                Icons.badge_outlined,
                                'License ID',
                                user.deliveryDetails!.licenseId,
                                isDark,
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (!isDelivery && user.kitchenDetails != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2D2410)
                                : const Color(0xFFFEFCE8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF4A3D1A)
                                  : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kitchen Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFFCD34D)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailItem(
                                Icons.location_on,
                                'Address',
                                user.kitchenDetails!.address,
                                isDark,
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _updateStatus(
                                  user.id,
                                  VerificationStatus.rejected,
                                );
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE63946),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _updateStatus(
                                  user.id,
                                  VerificationStatus.verified,
                                );
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2DA832),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryGreen),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextColor(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(String id, VerificationStatus status) async {
    try {
      await Provider.of<MainDatabaseService>(
        context,
        listen: false,
      ).updateUserStatus(id, status);

      // Refresh list to remove the item
      _loadPendingUsers();

      final isApproved = status == VerificationStatus.verified;
      final color = isApproved
          ? const Color(0xFF2DA832)
          : const Color(0xFFE63946);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isApproved ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  isApproved ? 'User approved successfully' : 'User rejected',
                ),
              ],
            ),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
