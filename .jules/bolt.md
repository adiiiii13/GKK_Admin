## 2024-05-11 - Search Debounce Optimization
**Learning:** In Flutter, using `Timer` for debouncing requires careful memory management, specifically canceling the timer inside the `dispose()` method to avoid exceptions (e.g., calling `setState` after the widget is disposed).
**Action:** Always verify that async mechanisms like timers are canceled inside the widget's `dispose()` method when implementing similar UX/performance enhancements.
