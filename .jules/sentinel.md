## 2025-03-08 - Fix Hardcoded Firebase Service Account Credentials

**Vulnerability:** Found a hardcoded Firebase Service Account JSON (including a multi-line private key) in `lib/credentials.dart`. This is a critical security risk as it exposes complete control over the Firebase project if the source code is compromised or accidentally committed to a public repository.

**Learning:** The file `lib/credentials.dart` was storing `serviceAccountJson` as a static `final Map` with embedded string constants instead of pulling these sensitive values from environment variables.

**Prevention:** Replaced the hardcoded static `final Map` with a getter `Map<String, dynamic> get serviceAccountJson` that reads from `dotenv.env[...]`. Specifically, for the multi-line private key, it correctly restores the newlines using `.replaceAll(r'\n', '\n')`. In the future, always ensure that sensitive keys are kept strictly out of the codebase and injected via an `.env` file (which should be in `.gitignore`) and accessed via `flutter_dotenv`.
