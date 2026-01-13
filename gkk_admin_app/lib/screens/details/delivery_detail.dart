import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../utils/theme_constants.dart';
import '../../widgets/widgets.dart';

class DeliveryDetailScreen extends StatelessWidget {
  final UserModel user;
  const DeliveryDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text('Delivery Agent Profile'),
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
            _buildVehicleInfo(user.deliveryDetails, isDark),
            const SizedBox(height: 24),
            _buildDeliveryLog(
              user.deliveryDetails?.deliveriesCompleted ?? [],
              isDark,
            ),
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
            heroTag: 'delivery_avatar_${user.id}',
            showGlow: true,
            fallbackIcon: Icons.delivery_dining,
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (user.deliveryDetails?.isOnline ?? false)
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: (user.deliveryDetails?.isOnline ?? false)
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  (user.deliveryDetails?.isOnline ?? false)
                      ? 'ONLINE'
                      : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: (user.deliveryDetails?.isOnline ?? false)
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfo(DeliveryDetails? details, bool isDark) {
    if (details == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFFB923C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.directions_bike, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Vehicle Details',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Vehicle Number',
            details.vehicleNumber,
            Colors.white,
            Colors.white70,
          ),
          const Divider(color: Colors.white24, height: 24),
          _buildInfoRow(
            'License ID',
            details.licenseId,
            Colors.white,
            Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    Color valueColor,
    Color labelColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryLog(List<Order> deliveries, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Delivery Log',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(isDark),
            ),
          ),
        ),
        if (deliveries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No deliveries completed yet',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
            ),
          )
        else
          ...deliveries.map((order) => _buildDeliveryCard(order, isDark)),
      ],
    );
  }

  Widget _buildDeliveryCard(Order order, bool isDark) {
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.green, size: 18),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'COMPLETED',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
