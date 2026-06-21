// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:agrolens_samegrelo/app.dart';

void main() {
  testWidgets('home screen renders core actions', (WidgetTester tester) async {
    await tester.pumpWidget(const AgroLensApp());
    await tester.pump();
    expect(find.text('AgroLens\nSamegrelo'), findsOneWidget);
    expect(find.text('Take / Choose Photo'), findsOneWidget);
    expect(find.text('Multi-view Nut Inspection'), findsOneWidget);
    // Diagnosis History sits lower in the scrolling list; scroll it into view.
    await tester.scrollUntilVisible(find.text('Diagnosis History'), 200);
    expect(find.text('Diagnosis History'), findsOneWidget);
  });
}
