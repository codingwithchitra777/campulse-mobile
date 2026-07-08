// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CsxTradingJournalApp());

    // Verify the app boots to the Dashboard view (title bar + bottom nav both label it 'Dashboard')
    expect(find.text('Dashboard'), findsWidgets);
  });
}
