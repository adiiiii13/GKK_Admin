## 2024-05-10 - Adding Debounce to Search Input for Performance
**Learning:** For search fields managing large lists in Flutter, triggering `setState` on every character type can lead to unnecessary widget rebuilds, causing UI stutter or jank, and potentially throwing "calling setState after dispose" if a user types then quickly navigates away.
**Action:** Always wrap text field changes for large lists with a debounce timer (e.g. `Timer(const Duration(milliseconds: 300), ...)`) to delay state updates and ensure the timer is canceled in the `dispose` method.
