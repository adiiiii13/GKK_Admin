## 2024-05-10 - Hardcoded Supabase Secrets

**Vulnerability:** Several files (`lib/services/services.dart`, `lib/screens/agent_management_screen.dart`, `lib/screens/email_management_screen.dart`, `lib/screens/support_monitor_screen.dart`) contain hardcoded Supabase keys (`sb_publishable_FKT03rJkxcGCSjXCV2xfeA_bX1jmJD8`, `sb_publishable_IWjNg9Xc6cFGd9JgEOA3Hg_G-CA32h8`) instead of loading them from environment variables via `.env`. A hardcoded JSON Web Token was also found in `lib/screens/support_monitor_screen.dart`.
**Learning:** Developers often hardcode secrets during debugging or early development and forget to remove them before committing.
**Prevention:** Always use environment variables for sensitive configuration strings. The `.env` file should not be committed to version control.
