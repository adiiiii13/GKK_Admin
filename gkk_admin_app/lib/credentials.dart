// lib/credentials.dart
// ⚠️ KEEP THIS FILE PRIVATE - Never commit to public repositories!
// Add this file to .gitignore

/// Firebase Service Account credentials for FCM authentication.
/// Project: GharKaKhana (gharkakhana-6f013)
import 'package:flutter_dotenv/flutter_dotenv.dart';

Map<String, dynamic> get serviceAccountJson => {
  "type": "service_account",
  "project_id": dotenv.env['FIREBASE_PROJECT_ID'] ?? "gharkakhana-placeholder",
  "private_key_id": dotenv.env['FIREBASE_PRIVATE_KEY_ID'] ?? "placeholder",
  "private_key": (dotenv.env['FIREBASE_PRIVATE_KEY'] ?? "").replaceAll(
    r'\n',
    '\n',
  ),
  "client_email":
      dotenv.env['FIREBASE_CLIENT_EMAIL'] ??
      "placeholder@placeholder.iam.gserviceaccount.com",
  "client_id": dotenv.env['FIREBASE_CLIENT_ID'] ?? "placeholder",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url":
      dotenv.env['FIREBASE_CLIENT_CERT_URL'] ?? "placeholder",
  "universe_domain": "googleapis.com",
};
