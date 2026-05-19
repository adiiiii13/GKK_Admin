## 2024-05-18 - Hardcoded SMTP App Password in Supabase Edge Function
**Vulnerability:** A plaintext SMTP app password ("tfkq jmwv dzoh rxrd") was hardcoded directly in the `send-email` Supabase Edge Function source code (`gkk_admin_app/supabase/functions/send-email/index.ts`).
**Learning:** Hardcoded credentials in source code can be easily exposed if the repository is public or if a developer's machine is compromised. It existed likely due to a quick implementation for sending emails via SMTP.
**Prevention:** Always use environment variables (`Deno.env.get('VAR_NAME')`) for sensitive credentials like API keys and passwords in Edge Functions. Configured secrets should be managed via the Supabase Dashboard or CLI.
