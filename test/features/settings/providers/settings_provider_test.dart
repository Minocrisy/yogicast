import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yogicast/features/settings/providers/settings_provider.dart';
import '../../../helpers/test_helper.dart';

void main() {
  group('SettingsProvider', () {
    late SettingsProvider settingsProvider;
    late SharedPreferences preferences;

    setUp(() async {
      await setupTestEnvironment();
      preferences = await SharedPreferences.getInstance();
      settingsProvider = SettingsProvider(preferences);
    });

    test('initial values are correct', () {
      expect(settingsProvider.groqApiKey, isEmpty);
      expect(settingsProvider.replicateApiKey, isEmpty);
      expect(settingsProvider.themeMode, equals('system'));
      expect(settingsProvider.autoPlay, isTrue);
      expect(settingsProvider.hasRequiredKeys, isFalse);
    });

    test('setGroqApiKey updates value and notifies listeners', () async {
      bool notified = false;
      settingsProvider.addListener(() => notified = true);

      await settingsProvider.setGroqApiKey('test-key');

      expect(settingsProvider.groqApiKey, equals('test-key'));
      expect(notified, isTrue);
    });

    test('setReplicateApiKey updates value and notifies listeners', () async {
      bool notified = false;
      settingsProvider.addListener(() => notified = true);

      await settingsProvider.setReplicateApiKey('test-key');

      expect(settingsProvider.replicateApiKey, equals('test-key'));
      expect(notified, isTrue);
    });

    test('setThemeMode updates value and notifies listeners', () async {
      bool notified = false;
      settingsProvider.addListener(() => notified = true);

      await settingsProvider.setThemeMode('dark');

      expect(settingsProvider.themeMode, equals('dark'));
      expect(notified, isTrue);
    });

    test('setAutoPlay updates value and notifies listeners', () async {
      bool notified = false;
      settingsProvider.addListener(() => notified = true);

      await settingsProvider.setAutoPlay(false);

      expect(settingsProvider.autoPlay, isFalse);
      expect(notified, isTrue);
    });

    test('hasRequiredKeys returns true only when both API keys are set', () async {
      expect(settingsProvider.hasRequiredKeys, isFalse);

      await settingsProvider.setGroqApiKey('test-key');
      expect(settingsProvider.hasRequiredKeys, isFalse);

      await settingsProvider.setReplicateApiKey('test-key');
      expect(settingsProvider.hasRequiredKeys, isTrue);
    });

    test('clearSettings resets all values and notifies listeners', () async {
      // Set some values first
      await settingsProvider.setGroqApiKey('test-key');
      await settingsProvider.setReplicateApiKey('test-key');
      await settingsProvider.setThemeMode('dark');
      await settingsProvider.setAutoPlay(false);

      bool notified = false;
      settingsProvider.addListener(() => notified = true);

      await settingsProvider.clearSettings();

      expect(settingsProvider.groqApiKey, isEmpty);
      expect(settingsProvider.replicateApiKey, isEmpty);
      expect(settingsProvider.themeMode, equals('system'));
      expect(settingsProvider.autoPlay, isTrue);
      expect(notified, isTrue);
    });

    test('values persist between instances', () async {
      // Set values in first instance
      await settingsProvider.setGroqApiKey('test-key');
      await settingsProvider.setReplicateApiKey('test-key');
      await settingsProvider.setThemeMode('dark');
      await settingsProvider.setAutoPlay(false);

      // Create new instance with same SharedPreferences
      final newProvider = SettingsProvider(preferences);

      // Verify values are preserved
      expect(newProvider.groqApiKey, equals('test-key'));
      expect(newProvider.replicateApiKey, equals('test-key'));
      expect(newProvider.themeMode, equals('dark'));
      expect(newProvider.autoPlay, isFalse);
    });

    test('handles invalid theme mode gracefully', () async {
      await settingsProvider.setThemeMode('invalid');
      expect(settingsProvider.themeMode, equals('system'));
    });

    test('handles empty API keys gracefully', () async {
      await settingsProvider.setGroqApiKey('');
      await settingsProvider.setReplicateApiKey('');
      
      expect(settingsProvider.groqApiKey, isEmpty);
      expect(settingsProvider.replicateApiKey, isEmpty);
      expect(settingsProvider.hasRequiredKeys, isFalse);
    });
  });
}
