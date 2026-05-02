## 2024-05-24 - Debouncing List Searches
**Learning:** Search queries on list screens (`users_list.dart`, `kitchens_list.dart`, `delivery_list.dart`) were triggering `setState` on every keystroke, which leads to unnecessary re-renders when managing large lists.
**Action:** Always add a debounce timer (e.g., 300ms) to search `TextField` instances that filter lists locally. Ensure to cancel the `Timer` in the `dispose` method to avoid memory leaks or "setState after dispose" exceptions.

## 2024-05-24 - Unintended Dependency Downgrades via Pub Get
**Learning:** Running `flutter pub get` or test commands can cause unintended downgrades to `pubspec.lock` in this specific environment (due to local SDK versions).
**Action:** Always monitor `git diff` and revert any unintended changes to `pubspec.lock` unless specifically updating dependencies.
