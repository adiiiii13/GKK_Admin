import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../credentials.dart';

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
      // 1. Authenticate with service account
      final credentials = ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(credentials, scopes);

      // 2. Build FCM v1 API endpoint
      final projectId = serviceAccountJson['project_id'];
      final uri = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      // 3. Build data payload
      final dataPayload = {
        "title": title,
        "body": body,
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
      };
      
      // Add image URL if provided
      if (imageUrl != null && imageUrl.isNotEmpty) {
        dataPayload["image_url"] = imageUrl;
      }

      // 4. Send DATA-ONLY message to topic (allows app to personalize @user)
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "message": {
            "topic": "all_users",
            // Send as DATA message (not notification) so we can personalize @user
            "data": dataPayload,
            // Android-specific config for high priority delivery
            "android": {
              "priority": "high",
            },
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
