class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String avatarUrl;
  final double reliabilityRating;
  final int completedDeals;
  final String accountType; // 'individual' | 'commercial'
  final String? businessName;
  final bool verifiedStatus;
  final double serviceRadiusKm;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    this.reliabilityRating = 5.0,
    this.completedDeals = 0,
    this.accountType = 'individual',
    this.businessName,
    this.verifiedStatus = false,
    this.serviceRadiusKm = 5.0,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'avatarUrl': avatarUrl,
    'reliabilityRating': reliabilityRating,
    'completedDeals': completedDeals,
    'accountType': accountType,
    'businessName': businessName,
    'verifiedStatus': verifiedStatus,
    'serviceRadiusKm': serviceRadiusKm,
  };

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      reliabilityRating: (data['reliabilityRating'] as num?)?.toDouble() ?? 5.0,
      completedDeals: (data['completedDeals'] as num?)?.toInt() ?? 0,
      accountType: data['accountType'] ?? 'individual',
      businessName: data['businessName'],
      verifiedStatus: data['verifiedStatus'] ?? false,
      serviceRadiusKm: (data['serviceRadiusKm'] as num?)?.toDouble() ?? 5.0,
    );
  }
}
