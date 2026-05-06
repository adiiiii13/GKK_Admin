## 2024-05-06 - Hardcoded Secrets in Source Code
**Vulnerability:** Firebase Service Account credentials (including the private key) and Supabase API credentials were hardcoded directly into the Dart source files (`lib/credentials.dart` and `lib/services/services.dart`).
**Learning:** Hardcoded credentials are a critical vulnerability as they can easily be extracted from the compiled application or leaked via version control, giving unauthorized access to backend services.
**Prevention:** Always use a `.env` file and `flutter_dotenv` to load configuration and secrets dynamically at runtime, ensuring they are not hardcoded into the source code repository.
