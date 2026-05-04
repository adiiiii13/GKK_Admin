
## 2024-05-04 - Hardcoded Firebase Credentials Removal
**Vulnerability:** Hardcoded Firebase Service Account credentials were found in `gkk_admin_app/lib/credentials.dart`.
**Learning:** The credentials file was used directly to authenticate for FCM notifications, exposing sensitive keys like the private key in the repository.
**Prevention:** Store sensitive keys and configuration in a `.env` file loaded at runtime (e.g. using `flutter_dotenv`) and ensure the `.env` file is included in `.gitignore`. For multi-line variables like private keys, remember to decode newline characters (e.g., using `.replaceAll(r'\n', '\n')`) when reading them.
