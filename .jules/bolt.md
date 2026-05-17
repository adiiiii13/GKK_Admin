## 2024-05-17 - Supabase v2.x Batch Query Method
**Learning:** When using `supabase_flutter: ^2.3.0` (v2.x), the `PostgrestFilterBuilder` method for checking if a column value is in a list of values is `.inFilter()`. Attempting to use `.in_()` will result in an "undefined method" compilation error, contrary to general v2.x documentation that sometimes suggests `.in_()`.
**Action:** Always use `.inFilter()` when constructing batch queries with Supabase Dart SDK v2.x to avoid compilation failures.

## 2024-05-17 - Unintentional Dependency Downgrades
**Learning:** Running `flutter test` or commands that trigger implicit dependency resolution in a restricted environment might cause `pubspec.lock` changes (e.g., downgrading `matcher` or `test_api`).
**Action:** Always verify `git status` after running Flutter commands to ensure unintended lockfile modifications aren't committed alongside performance optimizations.
