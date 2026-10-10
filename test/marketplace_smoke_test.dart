import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_radar_grid/main.dart';
import 'package:the_radar_grid/models/user.dart';
import 'mock_listings_dataset.dart';

void main() {
  group('UserProfile Unit Tests', () {
    test('UserProfile.fromMap should correctly parse production-shaped JSON', () {
      final mockJson = {
        'uid': 'test_user_789',
        'displayName': 'Alice Smith',
        'email': 'alice@example.com',
        'avatarUrl': 'https://example.com/avatar.png',
        'reliabilityRating': 4.8,
        'completedDeals': 25,
      };

      final user = UserProfile.fromMap(mockJson);

      expect(user.uid, 'test_user_789');
      expect(user.displayName, 'Alice Smith');
      expect(user.reliabilityRating, 4.8);
      expect(user.completedDeals, 25);
    });

    test('UserProfile should handle missing optional fields with defaults', () {
      final emptyJson = <String, dynamic>{};
      final user = UserProfile.fromMap(emptyJson);

      expect(user.uid, '');
      expect(user.displayName, '');
      expect(user.reliabilityRating, 5.0);
      expect(user.completedDeals, 0);
    });
  });

  group('Marketplace Widget Tests', () {
    testWidgets('Boosted listings should display the BOOSTED badge', (WidgetTester tester) async {
      // Find a boosted item from our mock dataset
      final boostedItem = mockListings.firstWhere((l) => l.isBoosted);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InteractiveCardItem(
            item: boostedItem,
            onTap: () {},
            onChat: () {},
          ),
        ),
      ));

      // Verify the badge text is present
      expect(find.text('⚡ BOOSTED'), findsOneWidget);
    });

    testWidgets('Non-boosted listings should NOT display the BOOSTED badge', (WidgetTester tester) async {
      // Find a non-boosted item
      final normalItem = mockListings.firstWhere((l) => !l.isBoosted);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InteractiveCardItem(
            item: normalItem,
            onTap: () {},
            onChat: () {},
          ),
        ),
      ));

      // Verify the badge text is NOT present
      expect(find.text('⚡ BOOSTED'), findsNothing);
    });

    testWidgets('Tapping a listing card triggers onTap callback', (WidgetTester tester) async {
      bool tapped = false;
      final item = mockListings.first;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: InteractiveCardItem(
            item: item,
            onTap: () => tapped = true,
            onChat: () {},
          ),
        ),
      ));

      // Tap the card
      await tester.tap(find.byType(InteractiveCardItem));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('ProfileScreen renders enterprise profile correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            user: null,
            listings: const [],
            onAuthChanged: () {},
          ),
        ),
      ));

      expect(find.text('Guest Neighbor'), findsOneWidget);
      expect(find.textContaining('Enterprise Rating'), findsOneWidget);
      expect(find.text('Sign In / Register Account'), findsOneWidget);
    });
  });
}
