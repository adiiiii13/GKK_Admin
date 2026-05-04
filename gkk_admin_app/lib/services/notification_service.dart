import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';

/// FCM Push Notification Service for sending notifications to all app users.
///
/// Uses Firebase Cloud Messaging (FCM) HTTP v1 API with Service Account authentication.
///
/// Architecture:
/// Admin App → Google OAuth2 → Access Token → FCM v1 API → All Subscribed Users
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isLoading = false;
  String? _lastError;
  bool _lastSendSuccess = false;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get lastSendSuccess => _lastSendSuccess;

  /// Pre-defined notification templates for quick messaging
  static const List<Map<String, String>> templates = [
    {
      'name': 'New Menu Update',
      'title': '🍽️ New Dishes Added!',
      'body': 'Check out our latest menu items. Fresh and delicious!',
    },
    {
      'name': 'Special Offer',
      'title': '🎉 Special Offer Today!',
      'body': 'Get 20% off on all orders. Limited time only!',
    },
    {
      'name': 'Delivery Update',
      'title': '🚚 Faster Deliveries!',
      'body': 'We\'ve improved our delivery times. Order now!',
    },
    {
      'name': 'Weekend Special',
      'title': '🌟 Weekend Special',
      'body': 'Enjoy exclusive weekend deals on your favorite meals!',
    },
  ];

  /// Sends a push notification to all users subscribed to the 'all_users' topic.
  ///
  /// [title] - The notification title
  /// [body] - The notification body/message
  /// [imageUrl] - Optional image URL to display with notification
  ///
  /// Uses DATA-ONLY messages so the User app can personalize @user placeholders.
  /// Throws an exception if the send fails.
  Future<void> sendNotification({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _lastError = null;
    _lastSendSuccess = false;
    notifyListeners();

    try {
      // 1. Load credentials from environment
      final privateKey = dotenv.env['FIREBASE_PRIVATE_KEY']?.replaceAll(
        r'\n',
        '\n',
      );
      if (privateKey == null || privateKey.isEmpty) {
        throw Exception(
          "Missing FIREBASE_PRIVATE_KEY in environment variables",
        );
      }

      final serviceAccountJson = {
        "type": "service_account",
        "project_id": dotenv.env['FIREBASE_PROJECT_ID'],
        "private_key_id": dotenv.env['FIREBASE_PRIVATE_KEY_ID'],
        "private_key": privateKey,
        "client_email": dotenv.env['FIREBASE_CLIENT_EMAIL'],
        "client_id": dotenv.env['FIREBASE_CLIENT_ID'],
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": dotenv.env['FIREBASE_CLIENT_CERT_URL'],
        "universe_domain": "googleapis.com",
      };

      // 2. Authenticate with service account
      final credentials = ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(credentials, scopes);

      // 3. Build FCM v1 API endpoint
      final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
      final uri = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      // 4. Build data payload
      final dataPayload = {
        "title": title,
        "body": body,
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
      };

      // Add image URL if provided
      if (imageUrl != null && imageUrl.isNotEmpty) {
        dataPayload["image_url"] = imageUrl;
      }

      // 5. Send DATA-ONLY message to topic (allows app to personalize @user)
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "message": {
            "topic": "all_users",
            // Send as DATA message (not notification) so we can personalize @user
            "data": dataPayload,
            // Android-specific config for high priority delivery
            "android": {"priority": "high"},
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("FCM Error ${response.statusCode}: ${response.body}");
      }

      _lastSendSuccess = true;
      client.close();
    } catch (e) {
      _lastError = e.toString();
      _lastSendSuccess = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sends a notification using a pre-defined template
  Future<void> sendTemplateNotification(int templateIndex) async {
    if (templateIndex < 0 || templateIndex >= templates.length) {
      throw Exception("Invalid template index");
    }

    final template = templates[templateIndex];
    await sendNotification(title: template['title']!, body: template['body']!);
  }

  /// Clears the last error state
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
