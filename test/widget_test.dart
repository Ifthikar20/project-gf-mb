// Basic Flutter widget test for the Wellness App.

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/main.dart';

void main() {
  testWidgets('Wellness app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WellnessApp());

    // Verify that the app loads (basic smoke test)
    await tester.pump();
    
    // The app should exist
    expect(find.byType(WellnessApp), findsOneWidget);
  });
}
