import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  static const String _groqApiKeyKey = 'groq_api_key';
  static const String _replicateApiKeyKey = 'replicate_api_key';
  static const String _themeModeKey = 'theme_mode';
  static const String _autoPlayKey = 'auto_play';

  SettingsProvider(this._prefs);

  String get groqApiKey => _prefs.getString(_groqApiKeyKey) ?? '';
  String get replicateApiKey => _prefs.getString(_replicateApiKeyKey) ?? '';
  String get themeMode => _prefs.getString(_themeModeKey) ?? 'system';
  bool get autoPlay => _prefs.getBool(_autoPlayKey) ?? true;

  Future<void> setGroqApiKey(String value) async {
    await _prefs.setString(_groqApiKeyKey, value);
    notifyListeners();
  }

  Future<void> setReplicateApiKey(String value) async {
    await _prefs.setString(_replicateApiKeyKey, value);
    notifyListeners();
  }

  Future<void> setThemeMode(String value) async {
    if (!['system', 'light', 'dark'].contains(value)) {
      value = 'system';
    }
    await _prefs.setString(_themeModeKey, value);
    notifyListeners();
  }

  Future<void> setAutoPlay(bool value) async {
    await _prefs.setBool(_autoPlayKey, value);
    notifyListeners();
  }

  bool get hasRequiredKeys => 
    groqApiKey.isNotEmpty && replicateApiKey.isNotEmpty;

  Future<void> clearSettings() async {
    await Future.wait([
      _prefs.remove(_groqApiKeyKey),
      _prefs.remove(_replicateApiKeyKey),
      _prefs.remove(_themeModeKey),
      _prefs.remove(_autoPlayKey),
    ]);
    notifyListeners();
  }
}
