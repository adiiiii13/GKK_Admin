## 2024-05-14 - Optimize List Search Inputs
**Learning:** In Flutter, typing quickly in a TextField whose onChanged callback directly calls setState triggers a re-build of the widget tree for every single keystroke. When dealing with potentially large lists, this leads to noticeable jank and high CPU usage.
**Action:** Always wrap `setState` updates from search TextFields in a Timer (debounce) so that state updates and widget rebuilds are delayed until the user stops typing for a short duration (e.g., 300ms). Remember to cancel the Timer in the widget's `dispose()` method.
