import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yogicast/features/settings/providers/settings_provider.dart';
import 'package:yogicast/features/settings/screens/settings_screen.dart';
import '../../../helpers/test_helper.dart';

void main() {
  group('SettingsScreen', () {
    late SettingsProvider settingsProvider;

    setUp(() async {
      await setupTestEnvironment();
      final prefs = await SharedPreferences.getInstance();
      settingsProvider = SettingsProvider(prefs);
    });

    Future<void> pumpSettingsScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: settingsProvider,
            child: const SettingsScreen(),
          ),
        ),
      );
    }

    testWidgets('displays API configuration section', (tester) async {
      await pumpSettingsScreen(tester);

      expect(find.text('API Configuration'), findsOneWidget);
      expect(find.text('Groq API Key'), findsOneWidget);
      expect(find.text('Replicate API Key'), findsOneWidget);
    });

    testWidgets('displays preferences section', (tester) async {
      await pumpSettingsScreen(tester);

      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('Auto-play Next Segment'), findsOneWidget);
    });

    testWidgets('can toggle API key visibility', (tester) async {
      await pumpSettingsScreen(tester);

      // Initially keys should be obscured
      expect(find.byIcon(Icons.visibility_off), findsNWidgets(2));

      // Toggle visibility for Groq API key
      await tester.tap(find.byIcon(Icons.visibility_off).first);
      await tester.pump();

      // One field should now be visible
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('can save API keys', (tester) async {
      await pumpSettingsScreen(tester);

      // Enter Groq API key
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter your Groq API key'),
        'test-groq-key',
      );
      
      // Tap save button
      await tester.tap(find.byIcon(Icons.save).first);
      await tester.pump();

      // Verify snackbar appears
      expect(find.text('Groq API key saved'), findsOneWidget);

      // Verify key was saved
      expect(settingsProvider.groqApiKey, equals('test-groq-key'));
    });

    testWidgets('can change theme mode', (tester) async {
      await pumpSettingsScreen(tester);

      // Open dropdown
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();

      // Select dark theme
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();

      // Verify theme was changed
      expect(settingsProvider.themeMode, equals('dark'));
    });

    testWidgets('can toggle auto-play', (tester) async {
      await pumpSettingsScreen(tester);

      // Initially should be enabled
      expect(settingsProvider.autoPlay, isTrue);

      // Toggle switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify auto-play was disabled
      expect(settingsProvider.autoPlay, isFalse);
    });

    testWidgets('shows reset confirmation dialog', (tester) async {
      await pumpSettingsScreen(tester);

      // Tap reset button
      await tester.tap(find.byIcon(Icons.restore));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Reset Settings'), findsOneWidget);
      expect(
        find.text('Are you sure you want to reset all settings to default?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('can reset settings', (tester) async {
      // Set some values first
      await settingsProvider.setGroqApiKey('test-key');
      await settingsProvider.setThemeMode('dark');
      await settingsProvider.setAutoPlay(false);

      await pumpSettingsScreen(tester);

      // Tap reset button
      await tester.tap(find.byIcon(Icons.restore));
      await tester.pumpAndSettle();

      // Tap reset in dialog
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Verify settings were reset
      expect(settingsProvider.groqApiKey, isEmpty);
      expect(settingsProvider.themeMode, equals('system'));
      expect(settingsProvider.autoPlay, isTrue);

      // Verify snackbar appears
      expect(find.text('Settings reset to default'), findsOneWidget);
    });

    testWidgets('shows error indicators for missing API keys', (tester) async {
      await pumpSettingsScreen(tester);

      // Initially both fields should show errors
      expect(
        find.text('API key is required'),
        findsNWidgets(2),
      );

      // Enter one key
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter your Groq API key'),
        'test-key',
      );
      await tester.pump();

      // Now only one error should show
      expect(
        find.text('API key is required'),
        findsOneWidget,
      );
    });
  });
}
