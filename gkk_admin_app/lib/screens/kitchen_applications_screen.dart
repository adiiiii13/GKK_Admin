import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/kitchen_applications_service.dart';

/// Kitchen Applications Management Screen
/// Displays list of kitchen registration applications for admin review
class KitchenApplicationsScreen extends StatefulWidget {
  const KitchenApplicationsScreen({super.key});

  @override
  State<KitchenApplicationsScreen> createState() => _KitchenApplicationsScreenState();
}

class _KitchenApplicationsScreenState extends State<KitchenApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final KitchenApplicationsService _service = KitchenApplicationsService();
  List<KitchenApplication> _applications = [];
  Map<String, int> _statusCounts = {'PENDING': 0, 'APPROVED': 0, 'REJECTED': 0};
  bool _isLoading = true;
  String _selectedFilter = 'ALL';
  late TabController _tabController;

  final List<String> _filterOptions = ['ALL', 'PENDING', 'APPROVED', 'REJECTED'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initService();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedFilter = _filterOptions[_tabController.index];
    });
    _loadApplications();
  }

  Future<void> _initService() async {
    await _service.init();
    await _loadApplications();
    await _loadCounts();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    final apps = await _service.getApplications(
      status: _selectedFilter == 'ALL' ? null : _selectedFilter,
    );
    setState(() {
      _applications = apps;
      _isLoading = false;
    });
  }

  Future<void> _loadCounts() async {
    final counts = await _service.getStatusCounts();
    setState(() => _statusCounts = counts);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.schedule;
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Future<void> _showApproveDialog(KitchenApplication app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Application?'),
        content: Text(
          'Are you sure you want to approve "${app.kitchenName}" by ${app.ownerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _service.approveApplication(
        applicationId: app.id,
        reviewedBy: 'Admin', // TODO: Get actual admin email
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
        if (result.success) {
          // Auto-send approval email
          final emailResult = await _service.sendApprovalEmail(
            email: app.email,
            ownerName: app.ownerName,
            kitchenName: app.kitchenName,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(emailResult.success
                    ? 'Approval email sent to ${app.email}'
                    : 'Email failed: ${emailResult.message}'),
                backgroundColor: emailResult.success ? Colors.blue : Colors.orange,
              ),
            );
          }
          _loadApplications();
          _loadCounts();
        }
      }
    }
  }

  Future<void> _showRejectDialog(KitchenApplication app) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting "${app.kitchenName}" by ${app.ownerName}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Enter reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a rejection reason'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final result = await _service.rejectApplication(
        applicationId: app.id,
        reviewedBy: 'Admin',
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
        if (result.success) {
          _loadApplications();
          _loadCounts();
        }
      }
    }
  }

  Future<void> _sendEmail(KitchenApplication app, String type) async {
    final subject = type == 'APPROVED'
        ? 'Congratulations! Your Kitchen is Approved - Ghar Ka Khana'
        : 'Application Update - Ghar Ka Khana';
    
    final body = type == 'APPROVED'
        ? '''Dear ${app.ownerName},

Congratulations! We are delighted to inform you that your kitchen "${app.kitchenName}" has been approved on Ghar Ka Khana.

You can now log in to the app and start accepting orders.

Welcome to the Ghar Ka Khana family!

Best regards,
Ghar Ka Khana Team'''
        : '''Dear ${app.ownerName},

Thank you for your interest in joining Ghar Ka Khana.

Unfortunately, we are unable to approve your kitchen "${app.kitchenName}" at this time.

Reason: ${app.rejectionReason ?? 'Not specified'}

You may reapply after addressing the above concerns.

Best regards,
Ghar Ka Khana Team''';

    final emailUri = Uri(
      scheme: 'mailto',
      path: app.email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email client'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCount = _statusCounts.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Applications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All ($totalCount)'),
            Tab(text: 'Pending (${_statusCounts['PENDING']})'),
            Tab(text: 'Approved (${_statusCounts['APPROVED']})'),
            Tab(text: 'Rejected (${_statusCounts['REJECTED']})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No applications found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadApplications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _applications.length,
                    itemBuilder: (context, index) {
                      final app = _applications[index];
                      return _buildApplicationCard(app, isDark);
                    },
                  ),
                ),
    );
  }

  Widget _buildApplicationCard(KitchenApplication app, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final statusColor = _getStatusColor(app.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(_getStatusIcon(app.status), color: statusColor),
        ),
        title: Text(
          app.kitchenName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${app.ownerName} • ${app.phone}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    app.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                if (app.isTakingLonger) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⚠️ Overdue',
                      style: TextStyle(fontSize: 10, color: Colors.orange),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  dateFormat.format(app.createdAt.toLocal()),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Details Section
                _buildSectionHeader('Personal Details'),
                _buildInfoRow('Name', app.ownerName),
                _buildInfoRow('Age', '${app.age} years'),
                _buildInfoRow('Gender', app.gender),
                _buildInfoRow('Location', app.location),
                _buildInfoRow('Phone', app.phone),
                _buildInfoRow('Email', app.email),

                const SizedBox(height: 16),

                // KYC Section
                _buildSectionHeader('KYC Verification'),
                if (app.kycSkipped)
                  const Text(
                    'KYC was skipped',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  )
                else ...[
                  _buildDocRow('Aadhar Front', app.aadharFrontUrl),
                  _buildDocRow('Aadhar Back', app.aadharBackUrl),
                  _buildDocRow('PAN Card', app.panCardUrl),
                ],

                const SizedBox(height: 16),

                // Kitchen Details Section
                _buildSectionHeader('Kitchen Details'),
                _buildInfoRow('Kitchen Name', app.kitchenName),
                _buildInfoRow('Type', app.isVegetarian ? '🥗 Vegetarian Only' : '🍖 Non-Veg Available'),
                if (app.nomineePartner != null)
                  _buildInfoRow('Nominee/Partner', app.nomineePartner!),
                const SizedBox(height: 8),
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    app.description,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),

                const SizedBox(height: 16),
                _buildSectionHeader('Kitchen Photos'),
                if (app.kitchenPhotos.isEmpty)
                  const Text(
                    'No photos uploaded',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: app.kitchenPhotos.map((url) => _buildPhotoThumbnail(url)).toList(),
                  ),

                if (app.rejectionReason != null) ...[
                  const SizedBox(height: 16),
                  _buildSectionHeader('Rejection Reason'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      app.rejectionReason!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action Buttons
                if (app.status == 'PENDING')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(app),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reject', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showApproveDialog(app),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: FilledButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _sendEmail(app, app.status),
                      icon: const Icon(Icons.email),
                      label: const Text('Send Email Notification'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.amber,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDocRow(String label, String? url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  url != null ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: url != null ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  url != null ? 'Uploaded' : 'Not uploaded',
                  style: TextStyle(
                    fontSize: 13,
                    color: url != null ? Colors.green : Colors.red,
                  ),
                ),
                if (url != null) ...[
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _showImageDialog(label, url),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String title, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 8),
                          Text('Failed to load image'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(String url) {
    return InkWell(
      onTap: () => _showImageDialog('Kitchen Photo', url),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
