import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../utils/theme_constants.dart';

/// Banner Manager Screen - CRUD operations for User app home carousel cards
class BannerManagerScreen extends StatefulWidget {
  const BannerManagerScreen({Key? key}) : super(key: key);

  @override
  State<BannerManagerScreen> createState() => _BannerManagerScreenState();
}

class _BannerManagerScreenState extends State<BannerManagerScreen> {
  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mainDb = context.read<MainDatabaseService>();
      final response = await mainDb.client
          .from('carousel_cards')
          .select()
          .order('order_position', ascending: true);

      setState(() {
        _banners = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBanner(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure you want to delete this banner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final mainDb = context.read<MainDatabaseService>();
        await mainDb.client.from('carousel_cards').delete().eq('id', id);
        _loadBanners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Banner deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting banner: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleBannerStatus(String id, bool currentStatus) async {
    try {
      final mainDb = context.read<MainDatabaseService>();
      await mainDb.client
          .from('carousel_cards')
          .update({'is_active': !currentStatus})
          .eq('id', id);
      _loadBanners();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBannerEditor({Map<String, dynamic>? banner}) {
    showDialog(
      context: context,
      builder: (ctx) => BannerEditorDialog(
        banner: banner,
        onSave: () {
          Navigator.pop(ctx);
          _loadBanners();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.getTextColor(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF2da832), Color(0xFFc2941b)],
          ).createShader(bounds),
          child: const Text(
            'Banner Manager',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2da832)),
            onPressed: _loadBanners,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBannerEditor(),
        backgroundColor: const Color(0xFF2da832),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Banner', style: TextStyle(color: Colors.white)),
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading banners',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadBanners,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_banners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_carousel_outlined,
              size: 80,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No banners yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first carousel banner',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBanners,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          final banner = _banners[index];
          return _buildBannerCard(banner, isDark);
        },
      ),
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> banner, bool isDark) {
    final isActive = banner['is_active'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2544) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner Preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2da832), const Color(0xFF4DBF55)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            banner['tag'] ?? 'OFFER',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          banner['title'] ?? 'Banner Title',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (banner['image_url'] != null &&
                      banner['image_url'].isNotEmpty)
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            banner['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Inactive overlay
                  if (!isActive)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'INACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Status Toggle
                GestureDetector(
                  onTap: () => _toggleBannerStatus(banner['id'], isActive),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.visibility : Icons.visibility_off,
                          size: 14,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive ? 'Active' : 'Hidden',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Click URL indicator
                if (banner['click_url'] != null &&
                    banner['click_url'].isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, size: 12, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Has Link',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                // Edit Button
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  onPressed: () => _showBannerEditor(banner: banner),
                ),
                // Delete Button
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade400),
                  onPressed: () => _deleteBanner(banner['id']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for adding/editing banner cards
class BannerEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? banner;
  final VoidCallback onSave;

  const BannerEditorDialog({Key? key, this.banner, required this.onSave})
    : super(key: key);

  @override
  State<BannerEditorDialog> createState() => _BannerEditorDialogState();
}

class _BannerEditorDialogState extends State<BannerEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tagController;
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _imageUrlController;
  late TextEditingController _clickUrlController;
  String _selectedColor = '#FF9800'; // Default orange
  String _selectedBgColor = '#FFFFFF'; // Default white background
  String _selectedTemplate = 'classic'; // Default template
  bool _isActive = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Orange', 'color': '#FF9800'},
    {'name': 'Pink', 'color': '#E91E63'},
    {'name': 'Green', 'color': '#4CAF50'},
    {'name': 'Blue', 'color': '#2196F3'},
    {'name': 'Purple', 'color': '#9C27B0'},
    {'name': 'Gold', 'color': '#FFC107'},
    {'name': 'Red', 'color': '#F44336'},
  ];

  // Background color options for banner
  final List<Map<String, dynamic>> _bgColorOptions = [
    {'name': 'White', 'color': '#FFFFFF'},
    {'name': 'Cream', 'color': '#FFF8E1'},
    {'name': 'Light Green', 'color': '#E8F5E9'},
    {'name': 'Light Blue', 'color': '#E3F2FD'},
    {'name': 'Light Pink', 'color': '#FCE4EC'},
    {'name': 'Light Purple', 'color': '#F3E5F5'},
    {'name': 'Light Orange', 'color': '#FFF3E0'},
    {'name': 'Dark', 'color': '#1E1E1E'},
  ];

  // Template options with names, ids and icons
  final List<Map<String, dynamic>> _templateOptions = [
    {
      'id': 'classic',
      'name': 'Classic',
      'icon': Icons.view_carousel,
      'desc': 'Text left, round image right',
    },
    {
      'id': 'full_image',
      'name': 'Full Image',
      'icon': Icons.image,
      'desc': 'Background image with overlay',
    },
    {
      'id': 'split_view',
      'name': 'Split View',
      'icon': Icons.view_sidebar,
      'desc': '50/50 split layout',
    },
    {
      'id': 'center_focus',
      'name': 'Center Focus',
      'icon': Icons.center_focus_strong,
      'desc': 'Centered text, image bg',
    },
    {
      'id': 'stacked',
      'name': 'Stacked',
      'icon': Icons.view_agenda,
      'desc': 'Image top, text bottom',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController(text: widget.banner?['tag'] ?? '');
    _titleController = TextEditingController(
      text: widget.banner?['title'] ?? '',
    );
    _subtitleController = TextEditingController(
      text: widget.banner?['subtitle'] ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.banner?['image_url'] ?? '',
    );
    _clickUrlController = TextEditingController(
      text: widget.banner?['click_url'] ?? '',
    );
    _selectedColor = widget.banner?['badge_color'] ?? '#FF9800';
    _selectedBgColor = widget.banner?['background_color'] ?? '#FFFFFF';
    _selectedTemplate = widget.banner?['template_style'] ?? 'classic';
    _isActive = widget.banner?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _tagController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _imageUrlController.dispose();
    _clickUrlController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Future<void> _saveBanner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final mainDb = context.read<MainDatabaseService>();

      final bannerData = {
        'tag': _tagController.text.trim(),
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'image_url': _imageUrlController.text.trim(),
        'click_url': _clickUrlController.text.trim(),
        'badge_color': _selectedColor,
        'background_color': _selectedBgColor,
        'template_style': _selectedTemplate,
        'is_active': _isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.banner != null) {
        // Update existing
        await mainDb.client
            .from('carousel_cards')
            .update(bannerData)
            .eq('id', widget.banner!['id']);
      } else {
        // Create new
        // Get max order position
        final existing = await mainDb.client
            .from('carousel_cards')
            .select('order_position')
            .order('order_position', ascending: false)
            .limit(1);

        final maxOrder = existing.isNotEmpty
            ? (existing[0]['order_position'] ?? 0)
            : 0;

        bannerData['order_position'] = maxOrder + 1;
        bannerData['created_at'] = DateTime.now().toIso8601String();

        await mainDb.client.from('carousel_cards').insert(bannerData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.banner != null
                  ? 'Banner updated successfully'
                  : 'Banner created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving banner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    final isEditing = widget.banner != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.getCardColor(isDark),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2da832), Color(0xFF4DBF55)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add_circle,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Banner' : 'Add New Banner',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _tagController,
                        label: 'Tag Text',
                        hint: 'e.g., WEEKEND SPECIAL',
                        icon: Icons.label,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _titleController,
                        label: 'Title',
                        hint: 'e.g., Flat ₹100 Cashback',
                        icon: Icons.title,
                        isDark: isDark,
                        maxLines: 2,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _subtitleController,
                        label: 'Subtitle',
                        hint: 'e.g., Order above ₹400 • Use Code: OFFER100',
                        icon: Icons.subtitles,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _imageUrlController,
                        label: 'Image URL',
                        hint: 'https://example.com/image.jpg',
                        icon: Icons.image,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _clickUrlController,
                        label: 'Click URL (Optional)',
                        hint: 'https://gkk.com/offer',
                        icon: Icons.link,
                        isDark: isDark,
                        helperText: 'Page to open when user taps this banner',
                      ),
                      const SizedBox(height: 20),
                      // Badge Color
                      Text(
                        'Badge Color',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _colorOptions.map((option) {
                          final isSelected = _selectedColor == option['color'];
                          return GestureDetector(
                            onTap: () => setState(
                              () => _selectedColor = option['color'],
                            ),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _hexToColor(option['color']),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _hexToColor(
                                            option['color'],
                                          ).withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      // Background Color
                      Text(
                        'Banner Background',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Background color for card-style templates',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _bgColorOptions.map((option) {
                          final isSelected =
                              _selectedBgColor == option['color'];
                          final isDarkColor = option['color'] == '#1E1E1E';
                          return GestureDetector(
                            onTap: () => setState(
                              () => _selectedBgColor = option['color'],
                            ),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _hexToColor(option['color']),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? (isDarkColor
                                            ? Colors.white
                                            : const Color(0xFF2da832))
                                      : Colors.grey.shade300,
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF2da832,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: isDarkColor
                                          ? Colors.white
                                          : const Color(0xFF2da832),
                                      size: 20,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Template Selector
                      Text(
                        'Banner Template',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(isDark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose how your banner will look',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _templateOptions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final template = _templateOptions[index];
                            final isSelected =
                                _selectedTemplate == template['id'];
                            return GestureDetector(
                              onTap: () => setState(
                                () => _selectedTemplate = template['id'],
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 100,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFF2da832,
                                        ).withValues(alpha: 0.1)
                                      : (isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2da832)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      template['icon'] as IconData,
                                      size: 28,
                                      color: isSelected
                                          ? const Color(0xFF2da832)
                                          : (isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      template['name'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? const Color(0xFF2da832)
                                            : AppTheme.getTextColor(isDark),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: Color(0xFF2da832),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Active Toggle
                      Row(
                        children: [
                          Text(
                            'Active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getTextColor(isDark),
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            activeColor: const Color(0xFF2da832),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveBanner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2da832),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Banner' : 'Create Banner',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
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
    int maxLines = 1,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: AppTheme.getTextColor(isDark)),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: Icon(icon, color: const Color(0xFF2da832)),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
        helperStyle: TextStyle(color: Colors.blue.shade400, fontSize: 11),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2da832), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
      ),
    );
  }
}
