// lib/credentials.dart
// ⚠️ KEEP THIS FILE PRIVATE - Never commit to public repositories!
// Add this file to .gitignore

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase Service Account credentials for FCM authentication.
/// Project: GharKaKhana (gharkakhana-6f013)
/// Note: Loaded dynamically via environment variables to avoid hardcoded secrets.
Map<String, dynamic> get serviceAccountJson => {
  "type": "service_account",
  "project_id": dotenv.env['FIREBASE_PROJECT_ID'] ?? 'gharkakhana-6f013',
  "private_key_id": dotenv.env['FIREBASE_PRIVATE_KEY_ID'] ?? '',
  "private_key": (dotenv.env['FIREBASE_PRIVATE_KEY'] ?? '').replaceAll('\\n', '\n'),
  "client_email": dotenv.env['FIREBASE_CLIENT_EMAIL'] ?? 'firebase-adminsdk-fbsvc@gharkakhana-6f013.iam.gserviceaccount.com',
  "client_id": dotenv.env['FIREBASE_CLIENT_ID'] ?? '',
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": dotenv.env['FIREBASE_CLIENT_X509_CERT_URL'] ?? 'https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40gharkakhana-6f013.iam.gserviceaccount.com',
  "universe_domain": "googleapis.com",
};
