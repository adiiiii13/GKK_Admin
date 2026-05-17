## 2024-05-17 - Hardcoded Admin Credentials in Offline Fallback
**Vulnerability:** A hardcoded backdoor existed in `SupabaseAuthService._offlineLogin` allowing login with phone `9876543210` and password `admin123` when the Supabase client failed to initialize or encountered an error.
**Learning:** Development test credentials or bypasses were left in the codebase (likely for offline testing/development) but merged into the production path. In an authentication fallback scenario (e.g. network failure), this provided an unauthenticated entry point into the app.
**Prevention:** Never implement hardcoded test credentials or bypasses in authentication fallbacks. All authentication must rely on the authoritative backend, and network errors should fail securely rather than granting access.
