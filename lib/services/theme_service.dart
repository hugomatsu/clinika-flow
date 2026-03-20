import 'package:flutter/material.dart';
import '../models/branding_preferences.dart';
import 'firestore_service.dart';

class ThemeService {
  static final ValueNotifier<ThemeData> theme = ValueNotifier(_buildDefault());
  static final ValueNotifier<String> clinicName =
      ValueNotifier('Kelyn Physio');

  static ThemeData _buildDefault() {
    return _buildTheme(const Color(0xFF2962FF), const Color(0xFF26A69A), false);
  }

  static ThemeData buildFromBranding(BrandingPreferences prefs) {
    return _buildTheme(
      _hexToColor(prefs.primaryColor),
      _hexToColor(prefs.secondaryColor),
      prefs.darkMode,
    );
  }

  static ThemeData _buildTheme(Color primary, Color secondary, bool dark) {
    final brightness = dark ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: dark ? const Color(0xFF121212) : Colors.white,
    );
  }

  static Future<void> loadFromStorage() async {
    final prefs = await FirestoreService.getBranding();
    if (prefs != null) {
      theme.value = buildFromBranding(prefs);
      clinicName.value = prefs.clinicName;
    }
  }

  static Future<void> saveAndApply(BrandingPreferences prefs) async {
    await FirestoreService.saveBranding(prefs);
    theme.value = buildFromBranding(prefs);
    clinicName.value = prefs.clinicName;
  }

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
