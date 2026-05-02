## 2024-05-02 - Added Dynamic Tooltips for Password Visibility
**Learning:** Found an `IconButton` used for password visibility toggling in the login screen without a tooltip or accessible label. Screen readers would not be able to identify the button's purpose without it.
**Action:** Added a dynamic tooltip (`'Show password'` / `'Hide password'`) based on the component's state to provide proper aria-equivalent text to screen readers and improve micro-UX on hover for pointer users. Ensure all future `IconButton` instances include a tooltip.
