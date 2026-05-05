
## 2024-05-24 - Hardcoded Firebase Service Account Credentials
**Vulnerability:** A `credentials.dart` file contained a hardcoded Firebase Service Account JSON, including a `private_key` which allowed full administrative access to the Firebase project.
**Learning:** Hardcoding credentials natively into Dart makes it easy to leak via version control or reverse-engineer the compiled application.
**Prevention:** Always load sensitive credentials dynamically via environment variables (`.env`) rather than hardcoding them into source files. Use `flutter_dotenv` or similar to handle multi-line secrets properly.
