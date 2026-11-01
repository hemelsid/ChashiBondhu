import 'package:chashibondhu/core/theme/app_theme.dart';
import 'package:chashibondhu/features/feed/feed_screen.dart';
import 'package:chashibondhu/features/water/water_check_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(theme: buildAppTheme(), home: child);

/// A tall, phone-width test screen so the whole form (and its bottom
/// button) is built and on screen without scrolling.
void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Feed screen asks for the fish type first', (tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(_wrap(const FeedScreen()));
    await tester.tap(find.text('হিসাব করুন'));
    await tester.pumpAndSettle();
    expect(find.text('মাছের জাত বেছে নিন।'), findsOneWidget);
  });

  testWidgets('Water check needs at least one value', (tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(_wrap(const WaterCheckScreen()));
    await tester.tap(find.text('চেক করুন'));
    await tester.pumpAndSettle();
    expect(find.text('অন্তত একটি মাপ লিখুন।'), findsOneWidget);
  });
}
