## 2024-05-15 - Hardcoded Service Account Credentials Extracted
**Vulnerability:** A complete, valid Firebase Service Account JSON payload (including full `private_key` with broad administrative permissions) was hardcoded directly in `lib/credentials.dart`.
**Learning:** Developers often hardcode keys during development to quickly test 3rd-party integrations (like push notifications), and accidentally commit these secrets since `.gitignore` rules either weren't implemented or were bypassed.
**Prevention:** Always use environment variables (e.g., via `flutter_dotenv`) for all secrets and service accounts from the start of development, providing safe fallbacks or placeholders for unconfigured environments. Ensure `.env` is strongly listed in `.gitignore`.
