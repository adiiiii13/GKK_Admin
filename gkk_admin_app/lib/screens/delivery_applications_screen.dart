import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/delivery_applications_service.dart';

class DeliveryApplicationsScreen extends StatefulWidget {
  const DeliveryApplicationsScreen({super.key});

  @override
  State<DeliveryApplicationsScreen> createState() => _DeliveryApplicationsScreenState();
}

class _DeliveryApplicationsScreenState extends State<DeliveryApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final DeliveryApplicationsService _service = DeliveryApplicationsService();
  List<DeliveryApplication> _applications = [];
  Map<String, int> _statusCounts = {'pending': 0, 'underReview': 0, 'verified': 0, 'rejected': 0};
  bool _isLoading = true;
  String _selectedFilter = 'ALL';
  late TabController _tabController;

  final List<String> _filterOptions = ['ALL', 'pending', 'underReview', 'verified', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      case 'pending':
        return Colors.orange;
      case 'underReview':
        return Colors.blue;
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'underReview':
        return Icons.rate_review;
      case 'verified':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Future<void> _showApproveDialog(DeliveryApplication app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Application?'),
        content: Text(
          'Are you sure you want to approve "${app.fullName}" as a Delivery Agent?',
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
      final result = await _service.approveApplication(applicationId: app.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
        if (result.success) {
          // Send approval email
          final emailResult = await _service.sendEmailNotification(
            email: app.email,
            fullName: app.fullName,
            type: 'APPROVED',
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

  Future<void> _showRejectDialog(DeliveryApplication app) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting "${app.fullName}"'),
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
          // Send rejection email
          final emailResult = await _service.sendEmailNotification(
            email: app.email,
            fullName: app.fullName,
            type: 'REJECTED',
            reason: reason,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(emailResult.success
                    ? 'Rejection email sent to ${app.email}'
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

  Future<void> _showRevokeDialog(DeliveryApplication app) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Delivery Agent?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revoking access for "${app.fullName}"'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Revocation Reason',
                hintText: 'Enter reason for revoking access...',
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
            style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a revocation reason'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // We use rejectApplication internally to set status to rejected
      final result = await _service.rejectApplication(
        applicationId: app.id,
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
          // Send revocation email
          final emailResult = await _service.sendEmailNotification(
            email: app.email,
            fullName: app.fullName,
            type: 'REVOKED',
            reason: reason,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(emailResult.success
                    ? 'Revocation email sent to ${app.email}'
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCount = _statusCounts.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Applications'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'All ($totalCount)'),
            Tab(text: 'Pending (${_statusCounts['pending']})'),
            Tab(text: 'Under Review (${_statusCounts['underReview']})'),
            Tab(text: 'Verified (${_statusCounts['verified']})'),
            Tab(text: 'Rejected (${_statusCounts['rejected']})'),
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

  Widget _buildApplicationCard(DeliveryApplication app, bool isDark) {
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
          app.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${app.phone} • ${app.city}'),
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
                    app.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
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
                _buildInfoRow('Name', app.fullName),
                _buildInfoRow('Age', '${app.age} years'),
                _buildInfoRow('Gender', app.gender),
                _buildInfoRow('Address', app.address),
                _buildInfoRow('City/State', '${app.city}, ${app.state}'),
                _buildInfoRow('Phone', app.phone),
                _buildInfoRow('Email', app.email),

                const SizedBox(height: 16),

                // KYC Section
                _buildSectionHeader('KYC Verification'),
                _buildInfoRow('ID Type', app.kycDocumentType ?? 'Not specified'),
                _buildInfoRow('ID Number', app.kycIdNumber ?? 'Not specified'),
                _buildDocRow('Document', app.kycDocumentUrl),

                const SizedBox(height: 16),

                // Vehicle Details Section
                _buildSectionHeader('Vehicle Details'),
                _buildInfoRow('Vehicle Type', app.vehicleType ?? 'Not specified'),
                _buildInfoRow('Engine Type', app.engineType ?? 'Not specified'),
                _buildInfoRow('Vehicle Number', app.vehicleNumber ?? 'Not specified'),
                _buildInfoRow('Vehicle Make', app.vehicleMake ?? 'Not specified'),
                _buildDocRow('Driving License', app.drivingLicenseUrl),
                _buildDocRow('Vehicle Photo', app.vehiclePhotoUrl),

                const SizedBox(height: 20),

                // Action Buttons
                if (app.status == 'underReview' || app.status == 'pending')
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
                else if (app.status == 'verified')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Agent Performance'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Deliveries', '0', Icons.local_shipping),
                            _buildStatItem('Rating', 'N/A', Icons.star),
                            _buildStatItem('Reviews', '0', Icons.rate_review),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showRevokeDialog(app),
                          icon: const Icon(Icons.block, color: Colors.deepOrange),
                          label: const Text('Revoke Access', style: TextStyle(color: Colors.deepOrange)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.deepOrange),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
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
}
