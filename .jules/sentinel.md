## 2024-05-11 - Hardcoded Supabase Credentials
**Vulnerability:** Supabase URLs and Anon Keys were hardcoded in multiple files (services.dart, agent_management_screen.dart, support_monitor_screen.dart).
**Learning:** Hardcoded secrets in client-side code (especially mobile apps) can be extracted, allowing unauthorized access to the database.
**Prevention:** Use flutter_dotenv to load environment variables from a .env file, and initialize them securely.
