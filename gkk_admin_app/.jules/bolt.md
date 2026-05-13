## 2024-05-13 - Optimize Supabase Count Queries
**Learning:** In Supabase Dart SDK v2.x, appending `.count(CountOption.exact)` to a query directly executes it and returns a `Future<int>`. Unlike older SDKs or JS SDKs, it does not return a response object with a `.count` property, so attempting to access `.count` on the result will cause a compiler error.
**Action:** When migrating local counting loops to database-side queries, use `.count(CountOption.exact)` and directly use the resulting integer value.
