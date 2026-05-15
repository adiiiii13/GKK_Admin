
## 2026-05-15 - Debounce Local Search Filters to Reduce Re-renders
**Learning:** In Flutter, updating state synchronously on every keystroke (`onChanged: (value) => setState(...)`) for a search filter that drives a large list causes expensive and unnecessary UI re-renders, resulting in visible jank. It can also lead to "setState after dispose" errors if the user navigates away rapidly.
**Action:** Always implement a debounce timer (e.g., `Timer(Duration(milliseconds: 300), ...)`) for search inputs that update list state locally. Ensure the timer is properly canceled in the `dispose` method.
