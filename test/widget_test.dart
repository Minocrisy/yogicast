import 'package:flutter_test/flutter_test.dart';
import 'package:yogicast/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const YogicastApp());

    // Verify that our app title is displayed
    expect(find.text('YOGICAST'), findsOneWidget);
  });
}
