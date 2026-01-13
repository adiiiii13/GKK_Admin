import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../utils/theme_constants.dart';
import '../../widgets/widgets.dart';
import '../details/kitchen_detail.dart';

class KitchensListScreen extends StatefulWidget {
  const KitchensListScreen({super.key});

  @override
  State<KitchensListScreen> createState() => _KitchensListScreenState();
}

class _KitchensListScreenState extends State<KitchensListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<UserModel> _kitchens = [];

  @override
  void initState() {
    super.initState();
    _loadKitchens();
  }

  Future<void> _loadKitchens() async {
    setState(() => _isLoading = true);
    final mainDb = Provider.of<MainDatabaseService>(context, listen: false);
    final kitchens = await mainDb.fetchUsers(role: UserRole.kitchen);

    if (mounted) {
      setState(() {
        _kitchens = kitchens;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Cloud Kitchens',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadKitchens),
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
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search kitchens...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
                      final kitchens = _kitchens.where((u) {
                        final isKitchen = u.role == UserRole.kitchen;
                        final matchesSearch =
                            u.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            (u.kitchenDetails?.address ?? '')
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase());
                        return isKitchen && matchesSearch;
                      }).toList();

                      if (kitchens.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store_mall_directory_outlined,
                                size: 80,
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No kitchens found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _loadKitchens,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: kitchens.length,
                          itemBuilder: (context, index) {
                            final kitchen = kitchens[index];
                            return _buildKitchenCard(kitchen, isDark);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKitchenCard(UserModel kitchen, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GradientCard(
        color: AppTheme.getCardColor(isDark),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1F2937), const Color(0xFF111827)]
              : [Colors.white, const Color(0xFFFAFAFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => KitchenDetailScreen(user: kitchen)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ProfileAvatar(
                imageUrl: kitchen.profileImage,
                size: 60,
                heroTag: 'kitchen_avatar_${kitchen.id}',
                fallbackIcon: Icons.restaurant,
                showGlow: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kitchen.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            kitchen.kitchenDetails?.address ?? 'No address',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatBadge(
                          Icons.star,
                          '${kitchen.kitchenDetails?.rating ?? 0.0}',
                          const Color(0xFFE5B84B),
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildStatBadge(
                          Icons.restaurant_menu,
                          '${kitchen.kitchenDetails?.menuItems.length ?? 0} items',
                          const Color(0xFF2DA832),
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (kitchen.status == VerificationStatus.rejected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: StatusBadge(
                    label: 'BANNED',
                    type: StatusType.rejected,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
