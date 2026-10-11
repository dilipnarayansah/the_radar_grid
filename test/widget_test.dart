import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_radar_grid/main.dart';
import 'package:the_radar_grid/features/shell/main_spot_shell.dart';
import 'package:the_radar_grid/features/map/spot_radar_map.dart';

void main() {
  testWidgets('Spot launches and opens the map radar tab', (tester) async {
    await tester.pumpWidget(const SpotApp());
    await tester.pumpAndSettle();

    expect(find.byType(MainSpotShell), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    await tester.tap(find.text('Radar'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MapRadarView), findsOneWidget);
  });
}
