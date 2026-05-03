
## 2024-05-03 - [CRITICAL] Hardcoded Firebase Service Account Credentials
**Vulnerability:** Found a hardcoded, highly sensitive Firebase Service Account private key (`lib/credentials.dart`) checked into the codebase.
**Learning:** The previous implementation embedded credentials directly into a Dart map instead of using a secure config injection strategy like `flutter_dotenv`.
**Prevention:** Always load sensitive credentials via environment variables and ensure the target file (e.g. `.env`) is ignored by source control (`.gitignore`). Escaping newlines when retrieving multi-line keys from `.env` was also necessary `(dotenv.env['...'].replaceAll(r'\n', '\n'))`.
