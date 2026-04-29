import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Kitchen Application Model
class KitchenApplication {
  final String id;
  final String ownerName;
  final int age;
  final String gender;
  final String location;
  final String phone;
  final String email;
  final String? aadharFrontUrl;
  final String? aadharBackUrl;
  final String? panCardUrl;
  final bool kycSkipped;
  final String kitchenName;
  final String description;
  final String? nomineePartner;
  final bool isVegetarian;
  final List<String> kitchenPhotos;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  KitchenApplication({
    required this.id,
    required this.ownerName,
    required this.age,
    required this.gender,
    required this.location,
    required this.phone,
    required this.email,
    this.aadharFrontUrl,
    this.aadharBackUrl,
    this.panCardUrl,
    this.kycSkipped = false,
    required this.kitchenName,
    required this.description,
    this.nomineePartner,
    this.isVegetarian = true,
    this.kitchenPhotos = const [],
    this.status = 'PENDING',
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory KitchenApplication.fromJson(Map<String, dynamic> json) {
    return KitchenApplication(
      id: json['id'] ?? '',
      ownerName: json['owner_name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'OTHER',
      location: json['location'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      aadharFrontUrl: json['aadhar_front_url'],
      aadharBackUrl: json['aadhar_back_url'],
      panCardUrl: json['pan_card_url'],
      kycSkipped: json['kyc_skipped'] ?? false,
      kitchenName: json['kitchen_name'] ?? '',
      description: json['description'] ?? '',
      nomineePartner: json['nominee_partner'],
      isVegetarian: json['is_vegetarian'] ?? true,
      kitchenPhotos: (json['kitchen_photos'] as List<dynamic>?)?.cast<String>() ?? [],
      status: json['status'] ?? 'PENDING',
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      reviewedBy: json['reviewed_by'],
    );
  }

  /// Check if application is taking longer than expected (> 2 days)
  bool get isTakingLonger {
    if (status != 'PENDING') return false;
    final difference = DateTime.now().difference(createdAt);
    return difference.inDays >= 2;
  }

  /// Get days since application was submitted
  int get daysSinceSubmission => DateTime.now().difference(createdAt).inDays;
}

/// Kitchen Applications Service for Admin App
/// Handles fetching, approving, and rejecting kitchen applications
class KitchenApplicationsService {
  static final KitchenApplicationsService _instance = KitchenApplicationsService._internal();
  factory KitchenApplicationsService() => _instance;
  KitchenApplicationsService._internal();

  SupabaseClient? _supabase;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize Supabase client for Kitchen database
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final url = dotenv.env['KITCHEN_SUPABASE_URL'] ?? '';
      final anonKey = dotenv.env['KITCHEN_SUPABASE_ANON_KEY'] ?? '';

      if (url.isNotEmpty && anonKey.isNotEmpty) {
        _supabase = SupabaseClient(url, anonKey);
        _isInitialized = true;
        debugPrint('✅ Kitchen Supabase (Admin) initialized');
      } else {
        debugPrint('⚠️ Kitchen Supabase credentials not found');
      }
    } catch (e) {
      debugPrint('❌ Kitchen Supabase init error: $e');
    }
  }

  /// Get all applications with optional status filter
  Future<List<KitchenApplication>> getApplications({String? status}) async {
    try {
      if (_supabase == null) {
        debugPrint('⚠️ Service not initialized');
        return [];
      }

      var query = _supabase!.from('kitchen_applications').select();
      
      if (status != null && status != 'ALL') {
        query = query.eq('status', status);
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List).map((e) => KitchenApplication.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Get applications error: $e');
      return [];
    }
  }

  /// Get application by ID
  Future<KitchenApplication?> getApplicationById(String id) async {
    try {
      if (_supabase == null) return null;

      final result = await _supabase!
          .from('kitchen_applications')
          .select()
          .eq('id', id)
          .single();

      return KitchenApplication.fromJson(result);
    } catch (e) {
      debugPrint('❌ Get application by ID error: $e');
      return null;
    }
  }

  /// Approve an application
  Future<({bool success, String message})> approveApplication({
    required String applicationId,
    required String reviewedBy,
  }) async {
    try {
      if (_supabase == null) {
        return (success: false, message: 'Service not initialized');
      }

      await _supabase!
          .from('kitchen_applications')
          .update({
            'status': 'APPROVED',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': reviewedBy,
            'rejection_reason': null,
          })
          .eq('id', applicationId);

      debugPrint('✅ Application $applicationId approved');
      return (success: true, message: 'Application approved successfully');
    } catch (e) {
      debugPrint('❌ Approve error: $e');
      return (success: false, message: 'Failed to approve: ${e.toString()}');
    }
  }

  /// Reject an application
  Future<({bool success, String message})> rejectApplication({
    required String applicationId,
    required String reviewedBy,
    required String reason,
  }) async {
    try {
      if (_supabase == null) {
        return (success: false, message: 'Service not initialized');
      }

      await _supabase!
          .from('kitchen_applications')
          .update({
            'status': 'REJECTED',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': reviewedBy,
            'rejection_reason': reason,
          })
          .eq('id', applicationId);

      debugPrint('✅ Application $applicationId rejected');
      return (success: true, message: 'Application rejected');
    } catch (e) {
      debugPrint('❌ Reject error: $e');
      return (success: false, message: 'Failed to reject: ${e.toString()}');
    }
  }

  /// Send approval email via Supabase Edge Function (cloud-hosted, always on)
  Future<({bool success, String message})> sendApprovalEmail({
    required String email,
    required String ownerName,
    required String kitchenName,
  }) async {
    try {
      final subject = 'Congratulations! Your Kitchen "$kitchenName" is Approved - Ghar Ka Khana';
      final body = '''Dear $ownerName,

Great news! Your kitchen application for "$kitchenName" has been approved by our admin team.

You can now login to the Ghar Ka Khana Kitchen app using your registered email ($email) and the password you set during registration.

Steps to get started:
1. Open the Ghar Ka Khana Kitchen app
2. Tap "I have an account" / "Login"
3. Enter your email: $email
4. Enter your password
5. Start managing your kitchen!

If you have any questions, please contact our support team.

Welcome to the Ghar Ka Khana family!

Best regards,
GharKaKhana Admin Team''';

      final response = await http.post(
        Uri.parse('https://yvbjnuobnxekgibfqsmq.supabase.co/functions/v1/send-email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2YmpudW9ibnhla2dpYmZxc21xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzOTY1NzIsImV4cCI6MjA5MDk3MjU3Mn0.Hf5zPb8urWQq155fUxF7kQIGFb0NyWphdMyeRI83vgk',
        },
        body: jsonEncode({
          'to': email,
          'subject': subject,
          'body': body,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          debugPrint('Approval email sent to $email');
          return (success: true, message: 'Approval email sent to $email');
        }
        return (success: false, message: (responseData['error'] ?? 'Email send failed').toString());
      } else {
        debugPrint('Email send failed: ${response.statusCode} ${response.body}');
        return (success: false, message: 'Email send failed (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Email send error: $e');
      return (success: false, message: 'Email send error: ${e.toString()}');
    }
  }

  /// Get counts by status (for dashboard)
  Future<Map<String, int>> getStatusCounts() async {
    try {
      if (_supabase == null) return {'PENDING': 0, 'APPROVED': 0, 'REJECTED': 0};

      final data = await _supabase!
          .from('kitchen_applications')
          .select('status');

      final counts = <String, int>{'PENDING': 0, 'APPROVED': 0, 'REJECTED': 0};
      for (final row in data as List) {
        final status = row['status'] as String?;
        if (status != null && counts.containsKey(status)) {
          counts[status] = (counts[status] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e) {
      debugPrint('❌ Get counts error: $e');
      return {'PENDING': 0, 'APPROVED': 0, 'REJECTED': 0};
    }
  }
}
