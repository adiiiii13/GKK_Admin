import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../utils/theme_constants.dart';
import '../../widgets/widgets.dart';

class UserDetailScreen extends StatelessWidget {
  final UserModel user;
  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text('User Profile'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(user, isDark),
            const SizedBox(height: 24),
            _buildTokenCard(user.userDetails, isDark),
            const SizedBox(height: 24),
            _buildOrderHistory(user.userDetails?.orderHistory ?? [], isDark),
            AdminActionButtons(user: user, isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          ProfileAvatar(
            imageUrl: user.profileImage,
            size: 100,
            heroTag: 'user_avatar_${user.id}',
            showGlow: true,
            fallbackIcon: Icons.person,
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.phone,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCard(UserDetails? details, bool isDark) {
    if (details == null) return const SizedBox();

    return GradientCard(
      gradient: const LinearGradient(
        colors: [Color(0xFFC2941B), Color(0xFFE5B84B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: null, // Just for display
      enableHoverEffect: false,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.token, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Token Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${details.tokenBalance}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (details.tokenHistory.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...details.tokenHistory
                        .take(3)
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    t.description,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "${t.amount > 0 ? '+' : ''}${t.amount}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistory(List<Order> orders, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Order History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(isDark),
            ),
          ),
        ),
        if (orders.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No orders placed yet',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
            ),
          )
        else
          ...orders.map((order) => _buildOrderCard(order, isDark)),
      ],
    );
  }

  Widget _buildOrderCard(Order order, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(isDark),
                  ),
                ),
                Text(
                  order.date.toLocal().toString().split(' ')[0],
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${order.amount}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(isDark),
                ),
              ),
              Text(
                order.status,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
