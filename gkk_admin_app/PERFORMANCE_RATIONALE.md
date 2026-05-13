# Performance Rationale: Database-side Count Queries

## The Problem
In the `KitchenApplicationsService` and `DeliveryApplicationsService`, the `getStatusCounts` methods previously fetched all rows from their respective tables using `select('status')` or `select('verification_status')`, and then iterated over every row locally to tally up the counts for each status.
As the application scales, this means fetching potentially thousands of rows, leading to large network payloads and increased memory overhead on the client side.

## The Solution
Replaced the local iteration loop with concurrent database-side count queries using `Future.wait` and Supabase's `count(CountOption.exact)` with `head: true` (in v2.x, `.count` does not return rows).

```dart
      final results = await Future.wait([
        _supabase!.from('kitchen_applications').select('*').eq('status', 'PENDING').count(CountOption.exact),
        _supabase!.from('kitchen_applications').select('*').eq('status', 'APPROVED').count(CountOption.exact),
        _supabase!.from('kitchen_applications').select('*').eq('status', 'REJECTED').count(CountOption.exact),
      ]);
```

## Theoretical Impact
- **Network Payload:** Reduced from O(N) (where N is total rows) to O(1) (just 3 integer values returned).
- **Client Memory:** Eliminated the creation of large lists of JSON objects in memory.
- **Execution Time:** By using `Future.wait`, the three lightweight count queries execute in parallel, resolving much faster than transferring a huge JSON payload over the network.
