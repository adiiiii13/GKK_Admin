import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../utils/theme_constants.dart';
import '../../widgets/widgets.dart';

class KitchenDetailScreen extends StatefulWidget {
  final UserModel user;
  const KitchenDetailScreen({super.key, required this.user});

  @override
  State<KitchenDetailScreen> createState() => _KitchenDetailScreenState();
}

class _KitchenDetailScreenState extends State<KitchenDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: AppTheme.primaryGreen,
              actions: [
                Builder(
                  builder: (buttonContext) {
                    return IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        final box =
                            buttonContext.findRenderObject() as RenderBox;
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
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 60),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.user.profileImage != null)
                      Image.network(
                        widget.user.profileImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildFallbackHeader(isDark),
                      )
                    else
                      _buildFallbackHeader(isDark),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(
                  widget.user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.secondaryGold,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Menu'),
                  Tab(text: 'Orders'),
                  Tab(text: 'Info'),
                ],
              ),
            ),
          ];
        },
        body: Builder(
          builder: (context) {
            // Use widget.user directly since we fetch fresh data in lists
            // If real-time updates are needed, we would need a stream here
            final freshUser = widget.user;

            return TabBarView(
              controller: _tabController,
              children: [
                _buildMenuTab(freshUser, isDark),
                _buildOrdersTab(freshUser, isDark),
                _buildInfoTab(freshUser, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFallbackHeader(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1F2937) : AppTheme.primaryGreen,
      child: const Center(
        child: Icon(Icons.restaurant, size: 80, color: Colors.white24),
      ),
    );
  }

  Widget _buildMenuTab(UserModel user, bool isDark) {
    final items = user.kitchenDetails?.menuItems ?? [];

    if (items.isEmpty) {
      return _buildEmptyState(
        Icons.restaurant_menu,
        'No menu items found',
        isDark,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildMenuItemCard(items[index], user.id, isDark);
      },
    );
  }

  Widget _buildMenuItemCard(FoodItem item, String kitchenId, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              color: isDark ? Colors.black26 : Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.fastfood, color: Colors.grey),
                    )
                  : const Icon(Icons.fastfood, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(isDark),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Switch(
                        value: item.isEnabled,
                        onChanged: (val) {
                          setState(() {
                            item.isEnabled = val;
                          });
                          Provider.of<MainDatabaseService>(
                            context,
                            listen: false,
                          ).toggleFoodItemStatus(kitchenId, item.id, val);
                        },
                        activeThumbColor: AppTheme.primaryGreen,
                      ),
                    ],
                  ),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryGold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.isEnabled
                          ? const Color(0xFF2DA832).withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.isEnabled ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.isEnabled
                            ? const Color(0xFF2DA832)
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(UserModel user, bool isDark) {
    final orders = user.kitchenDetails?.orderHistory ?? [];

    if (orders.isEmpty) {
      return _buildEmptyState(Icons.receipt_long, 'No order history', isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          color: AppTheme.getCardColor(isDark),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              child: Text(
                '#${order.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
            title: Text(
              '₹${order.amount}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(isDark),
              ),
            ),
            subtitle: Text(
              order.date.toLocal().toString().split(' ')[0],
              style: TextStyle(color: Colors.grey.shade500),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(UserModel user, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Contact Info',
            children: [
              _buildInfoRow(Icons.email_outlined, 'Email', user.email, isDark),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.phone_outlined, 'Phone', user.phone, isDark),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.location_on_outlined,
                'Address',
                user.kitchenDetails?.address ?? 'N/A',
                isDark,
              ),
            ],
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            title: 'Performance',
            children: [
              _buildInfoRow(
                Icons.star_outline,
                'Rating',
                '${user.kitchenDetails?.rating ?? 0.0} / 5.0',
                isDark,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.calendar_today_outlined,
                'Joined',
                user.dateApplied.toLocal().toString().split(' ')[0],
                isDark,
              ),
            ],
            isDark: isDark,
          ),
          AdminActionButtons(user: user, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade400),
        const SizedBox(width: 12),
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

  Widget _buildEmptyState(IconData icon, String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
