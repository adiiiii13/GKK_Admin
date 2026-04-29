## 2025-04-29 - [CRITICAL] Hardcoded Firebase Service Account Key
**Vulnerability:** A hardcoded Firebase Service Account private key was found in `lib/credentials.dart`.
**Learning:** Warning comments like `// ⚠️ KEEP THIS FILE PRIVATE - Never commit to public repositories!` are insufficient for protecting secrets. Developers might still accidentally commit them.
**Prevention:** Always use environment variables (e.g., via `.env` with `flutter_dotenv`) and add the `.env` file to `.gitignore` to prevent secrets from being tracked by version control. Additionally, parse newline characters in private keys from `.env` correctly.
