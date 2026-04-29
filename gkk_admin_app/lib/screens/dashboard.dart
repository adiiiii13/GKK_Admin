import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/services.dart';
import '../utils/theme_constants.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardsAnimationController;
  late List<Animation<double>> _cardAnimations;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Staggered card animations
    _cardsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimations = List.generate(
      6,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _cardsAnimationController,
          curve: Interval(
            index * 0.1,
            0.6 + (index * 0.1),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _cardsAnimationController.forward();

    // Sync profile from auth
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncUserProfile());
  }

  void _syncUserProfile() {
    final authService = context.read<SupabaseAuthService>();
    final storageService = context.read<LocalStorageService>();

    if (authService.currentAdmin != null) {
      final phone = authService.currentAdmin!.phone.startsWith('G-')
          ? ''
          : authService.currentAdmin!.phone;

      storageService.updateAdminProfile(
        authService.currentAdmin!.name ?? 'Admin',
        phone,
        authService.currentAdmin!.avatarUrl ?? storageService.adminImage,
        email: authService.currentAdmin!.email,
      );
    }
  }

  @override
  void dispose() {
    _cardsAnimationController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final authService = context.read<SupabaseAuthService>();
    await authService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _pickAndCropImage() async {
    final isDark = context.read<ThemeService>().isDarkMode;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.getCardColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Profile Picture',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(isDark),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSource(
                    ctx,
                    Icons.camera_alt,
                    'Camera',
                    ImageSource.camera,
                  ),
                  _buildImageSource(
                    ctx,
                    Icons.photo_library,
                    'Gallery',
                    ImageSource.gallery,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          toolbarColor: AppTheme.primaryGreen,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Profile Picture',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile != null && mounted) {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Uploading avatar...'),
            ],
          ),
          backgroundColor: AppTheme.getCardColor(isDark),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final authService = context.read<SupabaseAuthService>();
      final result = await authService.updateAvatar(File(croppedFile.path));

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success
                ? AppTheme.primaryGreen
                : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildImageSource(
    BuildContext ctx,
    IconData icon,
    String label,
    ImageSource source,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(ctx, source),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2da832), Color(0xFF4DBF55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final authService = context.read<SupabaseAuthService>();
    final admin = authService.currentAdmin;
    final isDark = context.read<ThemeService>().isDarkMode;

    if (admin == null) return;

    final nameController = TextEditingController(text: admin.name);
    final phoneController = TextEditingController(text: admin.phone);
    final emailController = TextEditingController(text: admin.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: TextStyle(color: AppTheme.getTextColor(isDark)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(
                  Icons.person,
                  color: AppTheme.primaryGreen,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                labelStyle: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                ),
              ),
              style: TextStyle(color: AppTheme.getTextColor(isDark)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                prefixIcon: const Icon(
                  Icons.phone,
                  color: AppTheme.primaryGreen,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                labelStyle: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                ),
              ),
              style: TextStyle(color: AppTheme.getTextColor(isDark)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email, color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                labelStyle: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                ),
                fillColor: isDark ? Colors.black12 : Colors.grey.shade100,
                filled: true,
              ),
              style: const TextStyle(color: Colors.grey),
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
              final result = await authService.updateProfile(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
              );

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success
                        ? AppTheme.primaryGreen
                        : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(isDark),
            _buildProfileSection(isDark),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: _buildServicesGrid(isDark),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF2da832), Color(0xFFc2941b)],
        ).createShader(bounds),
        child: const Text(
          'GKK Admin',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        // Settings button
        IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFF607D8B)),
          tooltip: 'Settings',
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
        Builder(
          builder: (buttonContext) {
            return IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: const Color(0xFF2da832),
              ),
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
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
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFFE63946)),
          tooltip: 'Log out',
          onPressed: _logout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProfileSection(bool isDark) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: ProfileAndServicesDelegate(
        expandedHeight: 320,
        onImageTap: _pickAndCropImage,
        onEditTap: () => _showEditProfileDialog(context),
      ),
    );
  }

  Widget _buildServicesGrid(bool isDark) {
    final services = [
      _ServiceData(
        title: 'Authentication',
        subtitle: 'Kitchens & Delivery',
        icon: Icons.verified_user,
        gradient: const LinearGradient(
          colors: [Color(0xFF2da832), Color(0xFF4DBF55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/auth',
      ),
      _ServiceData(
        title: 'Kitchens',
        subtitle: 'Manage Menus & Profiles',
        icon: Icons.restaurant,
        gradient: const LinearGradient(
          colors: [Color(0xFFc2941b), Color(0xFFE5B84B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/kitchens',
      ),
      _ServiceData(
        title: 'Users',
        subtitle: 'Profiles & Tokens',
        icon: Icons.people,
        gradient: const LinearGradient(
          colors: [Color(0xFF2da832), Color(0xFF4DBF55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/users',
      ),
      _ServiceData(
        title: 'Delivery Fleet',
        subtitle: 'Agents & Logs',
        icon: Icons.delivery_dining,
        gradient: const LinearGradient(
          colors: [Color(0xFFc2941b), Color(0xFFE5B84B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/delivery',
      ),
      _ServiceData(
        title: 'Notifier',
        subtitle: 'Push Notifications',
        icon: Icons.notifications_active,
        gradient: const LinearGradient(
          colors: [Color(0xFF2da832), Color(0xFF4ADE80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/notifier',
      ),
      _ServiceData(
        title: 'Banner Manager',
        subtitle: 'Home Carousel Cards',
        icon: Icons.view_carousel,
        gradient: const LinearGradient(
          colors: [Color(0xFFc2941b), Color(0xFFE5B84B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/banners',
      ),
      _ServiceData(
        title: 'Customer Tickets',
        subtitle: 'Support Monitor',
        icon: Icons.support_agent,
        gradient: const LinearGradient(
          colors: [Color(0xFF2da832), Color(0xFF4ADE80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/support_monitor',
      ),
      _ServiceData(
        title: 'Agent Control',
        subtitle: 'Manage & Revoke',
        icon: Icons.admin_panel_settings,
        gradient: const LinearGradient(
          colors: [Color(0xFFc2941b), Color(0xFFE5B84B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/agent_management',
      ),
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final service = services[index];
          return FadeTransition(
            opacity: _cardAnimations.length > index
                ? _cardAnimations[index]
                : _cardsAnimationController,
            // Fallback if animation list too short, though hardcoded 6 matches 5 services
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    _cardAnimations.length > index
                        ? _cardAnimations[index]
                        : _cardsAnimationController,
                  ),
              child: _buildServiceCard(service, isDark),
            ),
          );
        }, childCount: services.length),
      ),
    );
  }

  Widget _buildServiceCard(_ServiceData data, bool isDark) {
    return GradientCard(
      color: isDark ? const Color(0xFF1F2544) : Colors.white,
      onTap: () => Navigator.pushNamed(context, data.route),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: data.gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: data.gradient.colors.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(data.icon, size: 22, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                data.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.getTextColor(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                data.subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final String route;

  _ServiceData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.route,
  });
}

class ProfileAndServicesDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final VoidCallback onImageTap;
  final VoidCallback onEditTap;

  ProfileAndServicesDelegate({
    required this.expandedHeight,
    required this.onImageTap,
    required this.onEditTap,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    // Calculate progress based on the profile part only
    // Total max = expandedHeight + 70 (services)
    // Total min = 140 (profile collapsed) + 70 (services)

    // Actually, let's keep it simple. shrinkOffset goes from 0 to (max - min).
    // range = (expandedHeight + 70) - (140 + 70) = expandedHeight - 140.

    final safeExpandedHeight = expandedHeight + 70;
    const safeCollapsedHeight = 210.0; // 140 + 70

    final progress = shrinkOffset / (safeExpandedHeight - safeCollapsedHeight);
    final clampedProgress = progress.clamp(0.0, 1.0);

    final expandedOpacity = (1.0 - (clampedProgress * 2)).clamp(0.0, 1.0);
    final collapsedOpacity = ((clampedProgress - 0.5) * 2).clamp(0.0, 1.0);

    return Container(
      color: AppTheme.getBackgroundColor(isDark),
      child: Column(
        children: [
          // PROFILE SECTION
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Consumer<LocalStorageService>(
                builder: (context, service, _) {
                  return GradientCard(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1F2544), const Color(0xFF16213E)]
                          : [Colors.white, const Color(0xFFFAFAFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    padding: EdgeInsets.zero,
                    onTap: null,
                    enableHoverEffect: false,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // EXPANDED VIEW
                        if (expandedOpacity > 0)
                          Positioned.fill(
                            child: Opacity(
                              opacity: expandedOpacity,
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: onImageTap,
                                          child: ProfileAvatar(
                                            imagePath: service.adminImage,
                                            size: 100,
                                            showGlow: true,
                                            heroTag: 'profile_avatar_expanded',
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: onImageTap,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xFF2da832),
                                                    Color(0xFF4DBF55),
                                                  ],
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ShaderMask(
                                          shaderCallback: (bounds) =>
                                              const LinearGradient(
                                                colors: [
                                                  Color(0xFF2da832),
                                                  Color(0xFFc2941b),
                                                ],
                                              ).createShader(bounds),
                                          child: Text(
                                            service.adminName,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: isDark
                                                ? Colors.grey.shade500
                                                : Colors.grey.shade400,
                                          ),
                                          onPressed: onEditTap,
                                          tooltip: 'Edit Profile',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (service.adminPhone.isNotEmpty)
                                      Text(
                                        service.adminPhone,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    else
                                      InkWell(
                                        onTap: onEditTap,
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreen
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.primaryGreen
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.add_circle_outline,
                                                size: 14,
                                                color: AppTheme.primaryGreen,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Add your phone number',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.primaryGreen,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    if (service.adminEmail?.isNotEmpty ?? false)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.email_outlined,
                                            size: 16,
                                            color: AppTheme.getSubtitleColor(
                                              isDark,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            service.adminEmail!,
                                            style: TextStyle(
                                              color: AppTheme.getSubtitleColor(
                                                isDark,
                                              ),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // COLLAPSED VIEW
                        if (collapsedOpacity > 0)
                          Positioned.fill(
                            child: Opacity(
                              opacity: collapsedOpacity,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: onImageTap,
                                      child: ProfileAvatar(
                                        imagePath: service.adminImage,
                                        size: 50,
                                        showGlow: false,
                                        heroTag: 'profile_avatar_collapsed',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            service.adminName,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.getTextColor(
                                                isDark,
                                              ),
                                            ),
                                          ),
                                          if (service.adminPhone.isNotEmpty)
                                            Text(
                                              service.adminPhone,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          if (service.adminEmail?.isNotEmpty ??
                                              false)
                                            Text(
                                              service.adminEmail!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade400,
                                      ),
                                      onPressed: onEditTap,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // SERVICES TITLE (Fixed at Bottom)
          Container(
            height: 70,
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2544) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Services',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight + 70; // Profile max + Services height

  @override
  double get minExtent => 210; // Profile collapsed (140) + Services height (70)

  @override
  bool shouldRebuild(covariant ProfileAndServicesDelegate oldDelegate) {
    return true;
  }
}
