import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Delivery Agent Application Model
class DeliveryApplication {
  final String id;
  final String fullName;
  final int age;
  final String gender;
  final String email;
  final String phone;
  final String address;
  final String state;
  final String city;
  final String? profilePhotoUrl;
  final String status;
  final String? kycDocumentType;
  final String? kycIdNumber;
  final String? kycDocumentUrl;
  final String? vehicleType;
  final String? engineType;
  final String? vehicleNumber;
  final String? vehicleMake;
  final String? drivingLicenseUrl;
  final String? vehiclePhotoUrl;
  final DateTime createdAt;

  DeliveryApplication({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.email,
    required this.phone,
    required this.address,
    required this.state,
    required this.city,
    this.profilePhotoUrl,
    this.status = 'PENDING',
    this.kycDocumentType,
    this.kycIdNumber,
    this.kycDocumentUrl,
    this.vehicleType,
    this.engineType,
    this.vehicleNumber,
    this.vehicleMake,
    this.drivingLicenseUrl,
    this.vehiclePhotoUrl,
    required this.createdAt,
  });

  factory DeliveryApplication.fromJson(Map<String, dynamic> json) {
    // Check if relationships are loaded
    final kycDocs = json['kyc_documents'] as List?;
    final vehicleDetails = json['vehicle_details'] as List?;

    Map<String, dynamic>? kyc;
    if (kycDocs != null && kycDocs.isNotEmpty) kyc = kycDocs.first;

    Map<String, dynamic>? vehicle;
    if (vehicleDetails != null && vehicleDetails.isNotEmpty) vehicle = vehicleDetails.first;

    return DeliveryApplication(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'OTHER',
      email: json['email'] ?? '',
      phone: json['phone_number'] ?? '',
      address: json['current_address'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      profilePhotoUrl: json['profile_photo_url'],
      status: json['verification_status'] ?? 'pending',
      kycDocumentType: kyc?['document_type'],
      kycIdNumber: kyc?['id_number'],
      kycDocumentUrl: kyc?['document_url'],
      vehicleType: vehicle?['vehicle_type'],
      engineType: vehicle?['engine_type'],
      vehicleNumber: vehicle?['vehicle_number'],
      vehicleMake: vehicle?['vehicle_make'],
      drivingLicenseUrl: vehicle?['driving_license_url'],
      vehiclePhotoUrl: vehicle?['vehicle_photo_url'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Delivery Applications Service for Admin App
class DeliveryApplicationsService {
  static final DeliveryApplicationsService _instance = DeliveryApplicationsService._internal();
  factory DeliveryApplicationsService() => _instance;
  DeliveryApplicationsService._internal();

  SupabaseClient? _supabase;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize Supabase client for Delivery database
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final url = dotenv.env['DELIVERY_SUPABASE_URL'] ?? '';
      final anonKey = dotenv.env['DELIVERY_SUPABASE_ANON_KEY'] ?? '';

      if (url.isNotEmpty && anonKey.isNotEmpty) {
        _supabase = SupabaseClient(url, anonKey);
        _isInitialized = true;
        debugPrint('✅ Delivery Supabase (Admin) initialized');
      } else {
        debugPrint('⚠️ Delivery Supabase credentials not found');
      }
    } catch (e) {
      debugPrint('❌ Delivery Supabase init error: $e');
    }
  }

  /// Get all applications
  Future<List<DeliveryApplication>> getApplications({String? status}) async {
    try {
      if (_supabase == null) {
        debugPrint('⚠️ Service not initialized');
        return [];
      }

      // Query delivery profiles and join kyc_documents and vehicle_details
      var query = _supabase!.from('delivery_profiles').select('*, kyc_documents(*), vehicle_details(*)');
      
      if (status != null && status != 'ALL') {
        query = query.eq('verification_status', status);
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List).map((e) => DeliveryApplication.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Get applications error: $e');
      return [];
    }
  }

  /// Approve an application
  Future<({bool success, String message})> approveApplication({
    required String applicationId,
  }) async {
    try {
      if (_supabase == null) {
        return (success: false, message: 'Service not initialized');
      }

      await _supabase!
          .from('delivery_profiles')
          .update({
            'verification_status': 'verified',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', applicationId);

      debugPrint('✅ Delivery Application $applicationId approved');
      return (success: true, message: 'Application approved successfully');
    } catch (e) {
      debugPrint('❌ Approve error: $e');
      return (success: false, message: 'Failed to approve: ${e.toString()}');
    }
  }

  /// Reject an application
  Future<({bool success, String message})> rejectApplication({
    required String applicationId,
    required String reason,
  }) async {
    try {
      if (_supabase == null) {
        return (success: false, message: 'Service not initialized');
      }

      await _supabase!
          .from('delivery_profiles')
          .update({
            'verification_status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', applicationId);

      debugPrint('✅ Delivery Application $applicationId rejected');
      return (success: true, message: 'Application rejected');
    } catch (e) {
      debugPrint('❌ Reject error: $e');
      return (success: false, message: 'Failed to reject: ${e.toString()}');
    }
  }

  /// Send email notification via Supabase Edge Function
  Future<({bool success, String message})> sendEmailNotification({
    required String email,
    required String fullName,
    required String type,
    String? reason,
  }) async {
    try {
      final subject = type == 'APPROVED'
          ? 'Congratulations! You are Approved as a Delivery Agent - Ghar Ka Khana'
          : type == 'REJECTED'
              ? 'Application Update - Ghar Ka Khana'
              : 'Account Revoked - Ghar Ka Khana';

      final body = type == 'APPROVED'
          ? '''Dear $fullName,

Congratulations! We are delighted to inform you that your application as a Delivery Agent has been approved on Ghar Ka Khana.

You can now log in to the Delivery app and start accepting delivery requests.

Welcome to the Ghar Ka Khana family!

Best regards,
Ghar Ka Khana Admin Team'''
          : type == 'REJECTED'
              ? '''Dear $fullName,

Thank you for your interest in joining Ghar Ka Khana as a Delivery Agent.

Unfortunately, we are unable to approve your application at this time.

Reason: ${reason ?? 'Not specified'}

You may reapply after addressing the above concerns.

Best regards,
Ghar Ka Khana Admin Team'''
              : '''Dear $fullName,

Your Ghar Ka Khana Delivery Agent account has been revoked.

Reason: ${reason ?? 'Violation of our terms or policies.'}

If you believe this was a mistake, please contact our support team.

Best regards,
Ghar Ka Khana Admin Team''';

      // Using the Kitchen DB Edge Function for sending emails since it's already set up
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
          debugPrint('Email sent to $email');
          return (success: true, message: 'Email sent to $email');
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

  /// Get counts by status
  Future<Map<String, int>> getStatusCounts() async {
    try {
      if (_supabase == null) return {'pending': 0, 'underReview': 0, 'verified': 0, 'rejected': 0};

      final data = await _supabase!
          .from('delivery_profiles')
          .select('verification_status');

      final counts = <String, int>{'pending': 0, 'underReview': 0, 'verified': 0, 'rejected': 0};
      for (final row in data as List) {
        final status = row['verification_status'] as String?;
        if (status != null && counts.containsKey(status)) {
          counts[status] = (counts[status] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e) {
      debugPrint('❌ Get counts error: $e');
      return {'pending': 0, 'underReview': 0, 'verified': 0, 'rejected': 0};
    }
  }
}
