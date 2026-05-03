## 2024-05-03 - Debouncing Flutter Search Fields
**Learning:** In Flutter lists with search functionality, firing `setState` directly `onChanged` triggers a complete rebuild for every keystroke. This causes severe stuttering when filtering large lists and can lead to "setState after dispose" exceptions if the user navigates away before the rebuild completes.
**Action:** Always wrap `TextField` `onChanged` callbacks with a `Timer` (e.g., 300ms debounce), ensure `if (mounted)` checks are present inside the timer callback, and remember to `cancel()` the timer in the `dispose` method.
