## 2023-11-20 - Password visibility toggle tooltips
**Learning:** The `IconButton` used for password visibility toggles (`obscureText`) on `login.dart` and `admin_verification_screen.dart` lacked `tooltip` properties, impacting accessibility.
**Action:** When creating custom inputs with visibility toggles, always conditionally provide a `tooltip` explaining the action.
