import 'package:flutter_dotenv/flutter_dotenv.dart';

// lib/credentials.dart
// ⚠️ KEEP THIS FILE PRIVATE - Never commit to public repositories!
// Add this file to .gitignore

/// Firebase Service Account credentials for FCM authentication.
/// Loaded from environment variables for security.
Map<String, dynamic> get serviceAccountJson => {
  "type": dotenv.env['FIREBASE_TYPE'] ?? "service_account",
  "project_id": dotenv.env['FIREBASE_PROJECT_ID'] ?? "gharkakhana-6f013",
  "private_key_id": dotenv.env['FIREBASE_PRIVATE_KEY_ID'] ?? "",
  "private_key": (dotenv.env['FIREBASE_PRIVATE_KEY'] ?? "").replaceAll(r'\n', '\n'),
  "client_email": dotenv.env['FIREBASE_CLIENT_EMAIL'] ?? "firebase-adminsdk-fbsvc@gharkakhana-6f013.iam.gserviceaccount.com",
  "client_id": dotenv.env['FIREBASE_CLIENT_ID'] ?? "",
  "auth_uri": dotenv.env['FIREBASE_AUTH_URI'] ?? "https://accounts.google.com/o/oauth2/auth",
  "token_uri": dotenv.env['FIREBASE_TOKEN_URI'] ?? "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": dotenv.env['FIREBASE_AUTH_PROVIDER_CERT_URL'] ?? "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": dotenv.env['FIREBASE_CLIENT_CERT_URL'] ?? "",
  "universe_domain": dotenv.env['FIREBASE_UNIVERSE_DOMAIN'] ?? "googleapis.com",
};
