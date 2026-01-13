import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/services.dart';
import '../../utils/theme_constants.dart';
import '../../widgets/widgets.dart';
import '../details/delivery_detail.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<UserModel> _agents = [];

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    setState(() => _isLoading = true);
    final mainDb = Provider.of<MainDatabaseService>(context, listen: false);
    final agents = await mainDb.fetchUsers(role: UserRole.delivery);

    if (mounted) {
      setState(() {
        _agents = agents;
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
          'Delivery Fleet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAgents),
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
                hintText: 'Search delivery agents...',
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
                      final agents = _agents.where((u) {
                        final isAgent = u.role == UserRole.delivery;
                        final matchesSearch =
                            u.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            (u.deliveryDetails?.vehicleNumber ?? '')
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase());
                        return isAgent && matchesSearch;
                      }).toList();

                      if (agents.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _loadAgents,
                          child: ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delivery_dining,
                                        size: 80,
                                        color: isDark
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No active delivery agents',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
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

                      return RefreshIndicator(
                        onRefresh: _loadAgents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: agents.length,
                          itemBuilder: (context, index) {
                            final agent = agents[index];
                            return _buildAgentCard(agent, isDark);
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

  Widget _buildAgentCard(UserModel agent, bool isDark) {
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
          MaterialPageRoute(builder: (_) => DeliveryDetailScreen(user: agent)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ProfileAvatar(
                imageUrl: agent.profileImage,
                size: 60,
                heroTag: 'delivery_avatar_${agent.id}',
                fallbackIcon: Icons.delivery_dining,
                showGlow: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.motorcycle,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          agent.deliveryDetails?.vehicleNumber ?? 'No Vehicle',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatBadge(
                          Icons.check_circle,
                          '${agent.deliveryDetails?.deliveriesCompleted.length ?? 0} Done',
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        if (agent.deliveryDetails?.isOnline ?? false)
                          _buildStatBadge(Icons.circle, 'Online', Colors.green)
                        else
                          _buildStatBadge(
                            Icons.circle_outlined,
                            'Offline',
                            Colors.grey,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (agent.status == VerificationStatus.rejected)
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

  Widget _buildStatBadge(IconData icon, String text, Color color) {
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
