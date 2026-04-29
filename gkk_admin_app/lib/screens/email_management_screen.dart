import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/theme_constants.dart';
import '../services/services.dart';
import 'package:provider/provider.dart';

class EmailManagementScreen extends StatefulWidget {
  const EmailManagementScreen({Key? key}) : super(key: key);

  @override
  State<EmailManagementScreen> createState() => _EmailManagementScreenState();
}

class _EmailManagementScreenState extends State<EmailManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _emailLogs = [];
  bool _isLoading = true;
  bool _isSending = false;

  // Compose email fields
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dbService = context.read<MainDatabaseService>();
      final logsResponse = await dbService.client
          .from('email_logs')
          .select()
          .order('sent_at', ascending: false)
          .limit(50);
      
      setState(() {
        _emailLogs = List<Map<String, dynamic>>.from(logsResponse);
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

  Future<Map<String, dynamic>> _sendEmailViaResend({
    required String to,
    required String subject,
    required String body,
  }) async {
    try {
      final dbService = context.read<MainDatabaseService>();
      
      // Call Supabase Edge Function
      final response = await http.post(
        Uri.parse('https://mwnpwuxrbaousgwgoyco.supabase.co/functions/v1/send-email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer sb_publishable_FKT03rJkxcGCSjXCV2xfeA_bX1jmJD8',
        },
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'body': body,
          'from': 'GharKaKhana <noreply@adityarouth.site>', // Will use this after domain verified
        }),
      );

      debugPrint('Edge Function response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'message': 'Email sent!'};
        } else {
          return {'success': false, 'message': data['error'] ?? 'Unknown error'};
        }
      } else {
        final errorBody = jsonDecode(response.body);
        return {'success': false, 'message': errorBody['error'] ?? 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('Edge Function error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<void> _sendEmail() async {
    if (_subjectController.text.isEmpty || _bodyController.text.isEmpty) {
      _showSnackBar('Please fill subject and body', isError: true);
      return;
    }

    if (_emailController.text.isEmpty) {
      _showSnackBar('Please enter recipient email', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      final recipientEmail = _emailController.text.trim();
      final subject = _subjectController.text.trim();
      final body = _bodyController.text.trim();

      // Send email via Resend
      final result = await _sendEmailViaResend(
        to: recipientEmail,
        subject: subject,
        body: body,
      );
      
      final success = result['success'] as bool;
      final message = result['message'] as String;

      // Log to database
      final dbService = context.read<MainDatabaseService>();
      await dbService.client.from('email_logs').insert({
        'sender_name': 'GharKaKhana',
        'recipient_email': recipientEmail,
        'subject': subject,
        'body': body,
        'status': success ? 'sent' : 'failed',
      });

      if (success) {
        _showSnackBar('📧 Email sent successfully to $recipientEmail!');
        // Clear form
        _subjectController.clear();
        _bodyController.clear();
        _emailController.clear();
      } else {
        _showSnackBar('❌ $message', isError: true);
      }
      
      _loadData();
    } catch (e) {
      _showSnackBar('Failed to send email: $e', isError: true);
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(isDark),
      appBar: AppBar(
        title: const Text('Email Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Compose'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildComposeTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildComposeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recipient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'Enter recipient email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Email Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      hintText: 'Enter email subject',
                      prefixIcon: const Icon(Icons.subject),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bodyController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: 'Message Body',
                      hintText: 'Write your email message here...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendEmail,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Sending...' : 'Send Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_emailLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No emails sent yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _emailLogs.length,
        itemBuilder: (ctx, index) {
          final log = _emailLogs[index];
          final status = (log['status'] ?? 'pending') as String;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: status == 'sent' ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  status == 'sent' ? Icons.check_circle : Icons.error,
                  color: status == 'sent' ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                log['subject'] ?? 'No Subject',
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To: ${log['recipient_email']}'),
                  Text(
                    _formatDate(log['sent_at']),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'sent' ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: status == 'sent' ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
