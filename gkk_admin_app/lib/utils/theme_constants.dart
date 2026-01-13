import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  late SharedPreferences _prefs;
  bool _isDarkMode = false;

  // For circular reveal animation
  Offset? _toggleButtonPosition;
  GlobalKey themeButtonKey = GlobalKey();

  bool get isDarkMode => _isDarkMode;
  Offset? get toggleButtonPosition => _toggleButtonPosition;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  void setToggleButtonPosition(Offset position) {
    _toggleButtonPosition = position;
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}

class AppTheme {
  // Light Theme Colors
  static const Color primaryGreen = Color(0xFF2DA832);
  static const Color secondaryGold = Color(0xFFC2941B);
  static const Color backgroundCream = Color(0xFFFDFBF7);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF16213E);
  static const Color darkCard = Color(0xFF1F2544);

  // Gradients
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF2DA832), Color(0xFF4DBF55)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFC2941B), Color(0xFFE5B84B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGreenGradient = LinearGradient(
    colors: [Color(0xFF1E7B22), Color(0xFF2DA832)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFFAFAFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Styles
  static BoxDecoration roundedBox = BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4)),
    ],
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: secondaryGold,
      surface: backgroundCream,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundCream,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    useMaterial3: true,
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: secondaryGold,
      surface: darkSurface,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    useMaterial3: true,
  );

  // Helper methods for adaptive colors
  static Color getBackgroundColor(bool isDark) =>
      isDark ? darkBackground : backgroundCream;

  static Color getCardColor(bool isDark) => isDark ? darkCard : Colors.white;

  static Color getTextColor(bool isDark) =>
      isDark ? Colors.white : Colors.black87;

  static Color getSubtitleColor(bool isDark) =>
      isDark ? Colors.grey.shade400 : Colors.black54;
}
