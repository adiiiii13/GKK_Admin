
## 2024-05-18 - Optimize Dashboard Counts via DB-Side Aggregates
**Learning:** Using `.select('status')` to fetch full arrays of records simply to count statuses locally becomes a severe memory and network bottleneck (O(N) data transfer) as tables grow, which is a common anti-pattern in Supabase Flutter apps.
**Action:** Replace full array fetches with parallel database-side aggregates using `Future.wait` and `supabase.from('table').count(CountOption.exact).eq(...)` which returns an integer directly (O(1) data transfer).
