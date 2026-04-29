// lib/credentials.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase Service Account credentials for FCM authentication.
/// Project: GharKaKhana (gharkakhana-6f013)
///
/// NOTE: The actual secrets are loaded from the .env file.
Map<String, dynamic> get serviceAccountJson {
  // Replace actual newline characters if they are escaped in the .env file
  final privateKey =
      dotenv.env['FIREBASE_PRIVATE_KEY']?.replaceAll(r'\n', '\n') ?? '';

  return {
    "type": "service_account",
    "project_id": dotenv.env['FIREBASE_PROJECT_ID'] ?? "gharkakhana-6f013",
    "private_key_id": dotenv.env['FIREBASE_PRIVATE_KEY_ID'] ?? "",
    "private_key": privateKey,
    "client_email": dotenv.env['FIREBASE_CLIENT_EMAIL'] ?? "",
    "client_id": dotenv.env['FIREBASE_CLIENT_ID'] ?? "",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40gharkakhana-6f013.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };
}
