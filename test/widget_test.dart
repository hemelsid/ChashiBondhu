import 'package:chashibondhu/core/theme/app_theme.dart';
import 'package:chashibondhu/features/feed/feed_screen.dart';
import 'package:chashibondhu/features/water/water_check_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(theme: buildAppTheme(), home: child);

void main() {
  testWidgets('Feed screen shows error, then result', (tester) async {
    await tester.pumpWidget(_wrap(const FeedScreen()));
    await tester.scrollUntilVisible(find.text('হিসাব করুন'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('হিসাব করুন'));
    await tester.pumpAndSettle();
    expect(find.text('মাছের জাত বেছে নিন।'), findsOneWidget);
  });

  testWidgets('Water check needs at least one value', (tester) async {
    await tester.pumpWidget(_wrap(const WaterCheckScreen()));
    await tester.scrollUntilVisible(find.text('চেক করুন'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('চেক করুন'));
    await tester.pumpAndSettle();
    expect(find.text('অন্তত একটি মাপ লিখুন।'), findsOneWidget);
  });
}
