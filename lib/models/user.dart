class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String avatarUrl;
  final double reliabilityRating;
  final int completedDeals;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    this.reliabilityRating = 5.0,
    this.completedDeals = 0,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'avatarUrl': avatarUrl,
    'reliabilityRating': reliabilityRating,
    'completedDeals': completedDeals,
  };

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      reliabilityRating: (data['reliabilityRating'] as num?)?.toDouble() ?? 5.0,
      completedDeals: (data['completedDeals'] as num?)?.toInt() ?? 0,
    );
  }
}
