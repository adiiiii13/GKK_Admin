## 2024-05-13 - Optimize Supabase Count Queries
**Learning:** In Flutter apps connecting to Supabase, fetching all records (e.g., `select('status')`) just to count them locally causes unnecessary data transfer and processing overhead, leading to poor performance with large datasets.
**Action:** Use Supabase's built-in `count` option with `head: true` to perform counting directly on the database side, minimizing payload size and improving performance.
