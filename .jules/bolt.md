## 2025-04-29 - [Debounce Search Inputs]
**Learning:** In Flutter applications, triggering a full state rebuild (`setState`) on every keystroke in a search field can cause severe performance degradation, especially when managing large lists.
**Action:** Always implement a debounce timer (e.g., `Timer(Duration(milliseconds: 300), ...)`) to delay the filtering logic and re-rendering until the user pauses typing. Ensure to track the timer using a nullable `Timer` variable and correctly cancel it in the `dispose` method to prevent "calling setState after dispose" errors.
