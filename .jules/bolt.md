## 2024-05-06 - N+1 Query Resolution in Agent List
**Learning:** Resolving N+1 database inefficiencies in the 'gkk_admin_app' project requires using batch queries with the Supabase client's `.inFilter()` (or `.in_()`) instead of iterative single-row requests in loops. This specifically occurs when retrieving detailed entity information (like agent emails/ban statuses) after initially pulling IDs from relations.
**Action:** Always pre-aggregate unique IDs into a `Set` or `List` and execute a single batch lookup via `.inFilter()` to convert O(N) network requests to O(1) performance.
