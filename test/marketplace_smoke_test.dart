import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_radar_grid/models/user.dart';
import 'package:the_radar_grid/features/feed/widgets/spot_listing_card.dart';
import 'package:the_radar_grid/features/profile/profile_screen.dart';
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

  group('Spot Marketplace Widget Tests', () {
    testWidgets('Boosted listings should display the BOOSTED badge', (WidgetTester tester) async {
      final boostedItem = mockListings.firstWhere((l) => l.isBoosted);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpotListingCard(
            item: boostedItem,
            isJobMode: false,
            onTap: () {},
            onChat: () {},
            onCall: () {},
            onWhatsApp: () {},
          ),
        ),
      ));

      expect(find.text('⚡ BOOSTED'), findsOneWidget);
    });

    testWidgets('Non-boosted listings should NOT display the BOOSTED badge', (WidgetTester tester) async {
      final normalItem = mockListings.firstWhere((l) => !l.isBoosted);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpotListingCard(
            item: normalItem,
            isJobMode: false,
            onTap: () {},
            onChat: () {},
            onCall: () {},
            onWhatsApp: () {},
          ),
        ),
      ));

      expect(find.text('⚡ BOOSTED'), findsNothing);
    });

    testWidgets('Tapping a listing card triggers onTap callback', (WidgetTester tester) async {
      bool tapped = false;
      final item = mockListings.first;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SpotListingCard(
            item: item,
            isJobMode: false,
            onTap: () => tapped = true,
            onChat: () {},
            onCall: () {},
            onWhatsApp: () {},
          ),
        ),
      ));

      await tester.tap(find.byType(SpotListingCard));
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

      expect(find.text('Guest Industrial Partner'), findsOneWidget);
      expect(find.text('Sign In / Register Account'), findsOneWidget);
    });
  });
}
