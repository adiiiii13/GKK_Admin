## 2024-05-18 - Text Field Search Debounce
**Learning:** TextField search lists can suffer from severe UI thread blocking if complex filtering runs on every keystroke, especially in lists holding many data models.
**Action:** Always add a ~300ms debounce `Timer` before running search filtering or API calls inside a `TextField` `onChanged` callback. Ensure the Timer is properly canceled in `dispose()` to prevent memory leaks and "calling setState after dispose" exceptions.
