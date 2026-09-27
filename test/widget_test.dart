// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_radar_grid/main.dart';

void main() {
  testWidgets('Radar Grid launches and opens the radar map tab', (tester) async {
    await tester.pumpWidget(const RadarGridApp());
    await tester.pumpAndSettle();

    expect(find.byType(MainRadarShell), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    await tester.tap(find.text('Radar Map'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MapRadarScreen), findsOneWidget);
  });
}
