import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingType { offer, need, bounty, tool }

class GridListing {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String tag;
  final String iconEmoji;
  final double rating;
  final int reviewsCount;
  final String eta;
  final double distanceKm;
  final String price;
  final String bio;
  final String phone;
  final String sector;
  final double? latitude;
  final double? longitude;
  final ListingType type;
  final bool isVerified;
  final String paymentTag;
  final String statusText;
  final String? authorId; // Security: Link to owner
  final bool isBoosted;   // Feature: ₹29 pay-to-boost
  bool isFavorite;

  GridListing({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.tag,
    required this.iconEmoji,
    required this.rating,
    required this.reviewsCount,
    required this.eta,
    required this.distanceKm,
    required this.price,
    required this.bio,
    required this.phone,
    required this.sector,
    this.latitude,
    this.longitude,
    this.type = ListingType.offer,
    this.isVerified = true,
    this.paymentTag = '📱 UPI / Cash',
    this.statusText = '🟢 Active Now',
    this.isFavorite = false,
    this.authorId,
    this.isBoosted = false,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'subtitle': subtitle,
    'category': category,
    'tag': tag,
    'iconEmoji': iconEmoji,
    'rating': rating,
    'reviewsCount': reviewsCount,
    'eta': eta,
    'distanceKm': distanceKm,
    'price': price,
    'bio': bio,
    'phone': phone,
    'sector': sector,
    'latitude': latitude,
    'longitude': longitude,
    'type': type.name,
    'isVerified': isVerified,
    'paymentTag': paymentTag,
    'statusText': statusText,
    'isFavorite': isFavorite,
    'authorId': authorId,
    'isBoosted': isBoosted,
  };

  factory GridListing.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final typeName = data['type'] as String?;

    return GridListing(
      id: doc.id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      category: data['category'] as String? ?? '',
      tag: data['tag'] as String? ?? '',
      iconEmoji: data['iconEmoji'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: (data['reviewsCount'] as num?)?.toInt() ?? 0,
      eta: data['eta'] as String? ?? '',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
      price: data['price'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      sector: data['sector'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      type: ListingType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => ListingType.offer,
      ),
      isVerified: data['isVerified'] as bool? ?? true,
      paymentTag: data['paymentTag'] as String? ?? '📱 UPI / Cash',
      statusText: data['statusText'] as String? ?? '🟢 Active Now',
      isFavorite: data['isFavorite'] as bool? ?? false,
      authorId: data['authorId'] as String?,
      isBoosted: data['isBoosted'] as bool? ?? false,
    );
  }
}
