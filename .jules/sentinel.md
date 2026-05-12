## 2024-05-12 - Hardcoded Firebase Private Key Vulnerability
**Vulnerability:** A hardcoded Firebase service account private key was found in `lib/credentials.dart`.
**Learning:** Keys and tokens hardcoded in source code files are easily leaked if the code is pushed to version control, even if a comment warns not to commit the file. Developers sometimes do this for convenience or during quick iterations, but it bypasses secret management tools.
**Prevention:** Always use environment variables for sensitive configurations and secrets. `flutter_dotenv` should be used to securely load these variables into the Dart runtime. For multi-line secrets like RSA keys stored in `.env`, ensure escaped newline characters (`\n`) are restored properly using `.replaceAll(r'\n', '\n')`.
