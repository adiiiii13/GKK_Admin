import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';
import '../services/services.dart';
import 'package:provider/provider.dart';

class CouponManagementScreen extends StatefulWidget {
  const CouponManagementScreen({Key? key}) : super(key: key);

  @override
  State<CouponManagementScreen> createState() => _CouponManagementScreenState();
}

class _CouponManagementScreenState extends State<CouponManagementScreen> {
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dbService = context.read<MainDatabaseService>();
      final couponsResponse = await dbService.client
          .from('coupons')
          .select()
          .order('created_at', ascending: false);
      
      setState(() {
        _coupons = List<Map<String, dynamic>>.from(couponsResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to load data: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCreateCouponDialog() {
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    final userIdController = TextEditingController();
    String couponType = 'universal';
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_offer, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 12),
              const Text('Create Coupon'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: 'Coupon Code',
                    hintText: 'e.g., SAVE20',
                    prefixIcon: const Icon(Icons.code),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: discountController,
                  decoration: InputDecoration(
                    labelText: 'Discount Percentage',
                    hintText: 'e.g., 20',
                    prefixIcon: const Icon(Icons.percent),
                    suffixText: '%',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('Coupon Type', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'universal', label: Text('Universal'), icon: Icon(Icons.public)),
                    ButtonSegment(value: 'specific', label: Text('Specific'), icon: Icon(Icons.person)),
                  ],
                  selected: {couponType},
                  onSelectionChanged: (selection) {
                    setDialogState(() => couponType = selection.first);
                  },
                ),
                if (couponType == 'specific') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: userIdController,
                    decoration: InputDecoration(
                      labelText: 'User ID or Email',
                      hintText: 'Enter user ID or email',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Coupon can be used'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                  activeColor: AppTheme.primaryGreen,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (codeController.text.isEmpty || discountController.text.isEmpty) {
                  _showSnackBar('Please fill all fields', isError: true);
                  return;
                }
                if (couponType == 'specific' && userIdController.text.isEmpty) {
                  _showSnackBar('Please enter user ID', isError: true);
                  return;
                }
                
                try {
                  final dbService = context.read<MainDatabaseService>();
                  await dbService.client.from('coupons').insert({
                    'code': codeController.text.trim(),
                    'discount_percent': int.parse(discountController.text.trim()),
                    'coupon_type': couponType,
                    'specific_user_email': couponType == 'specific' ? userIdController.text.trim() : null,
                    'is_active': isActive,
                  });
                  Navigator.pop(ctx);
                  _loadData();
                  _showSnackBar('Coupon created successfully!');
                } catch (e) {
                  _showSnackBar('Failed to create coupon: $e', isError: true);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCoupon(Map<String, dynamic> coupon) async {
    try {
      final dbService = context.read<MainDatabaseService>();
      await dbService.client
          .from('coupons')
          .update({'is_active': !(coupon['is_active'] as bool)})
          .eq('id', coupon['id']);
      _loadData();
      _showSnackBar('Coupon ${coupon['is_active'] ? 'deactivated' : 'activated'}');
    } catch (e) {
      _showSnackBar('Failed to update coupon: $e', isError: true);
    }
  }

  Future<void> _deleteCoupon(Map<String, dynamic> coupon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coupon?'),
        content: Text('Are you sure you want to delete coupon "${coupon['code']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dbService = context.read<MainDatabaseService>();
        await dbService.client.from('coupons').delete().eq('id', coupon['id']);
        _loadData();
        _showSnackBar('Coupon deleted');
      } catch (e) {
        _showSnackBar('Failed to delete: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      appBar: AppBar(
        title: const Text('Coupon Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCouponDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Coupon'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coupons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No coupons yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      const Text('Tap + to create your first coupon'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _coupons.length,
                    itemBuilder: (ctx, index) {
                      final coupon = _coupons[index];
                      final isUniversal = coupon['coupon_type'] == 'universal';
                      final isActive = coupon['is_active'] as bool;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: isActive
                                  ? [AppTheme.primaryGreen.withOpacity(0.1), const Color(0xFFc2941b).withOpacity(0.05)]
                                  : [Colors.grey.shade200, Colors.grey.shade100],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.primaryGreen : Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${coupon['discount_percent']}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  coupon['code'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    decoration: isActive ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isUniversal ? Colors.blue.shade100 : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isUniversal ? '🌍 Universal' : '👤 Specific',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isUniversal ? Colors.blue.shade700 : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  isActive ? '✅ Active' : '❌ Inactive',
                                  style: TextStyle(color: isActive ? Colors.green : Colors.red),
                                ),
                                Text('Used: ${coupon['times_used'] ?? 0} times'),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  onTap: () => _toggleCoupon(coupon),
                                  child: Row(
                                    children: [
                                      Icon(isActive ? Icons.pause : Icons.play_arrow),
                                      const SizedBox(width: 8),
                                      Text(isActive ? 'Deactivate' : 'Activate'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  onTap: () => _deleteCoupon(coupon),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
