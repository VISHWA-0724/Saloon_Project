class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String role;
  final int points;
  final int bookingsCount;
  final int reviewsCount;
  final List<String> wishlist;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.role,
    required this.points,
    required this.bookingsCount,
    required this.reviewsCount,
    required this.wishlist,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profileImage = json['profileImage']?.toString().trim();
    return UserModel(
      id: (json['_id'] ?? json['id']).toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      profileImage:
          profileImage == null || profileImage.isEmpty ? null : profileImage,
      role: (json['role'] ?? 'user').toString(),
      points: _asInt(json['points']),
      bookingsCount: _asInt(json['bookingsCount']),
      reviewsCount: _asInt(json['reviewsCount']),
      wishlist:
          ((json['wishlist'] ?? []) as List).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'profileImage': profileImage,
        'role': role,
        'points': points,
        'bookingsCount': bookingsCount,
        'reviewsCount': reviewsCount,
        'wishlist': wishlist,
      };
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
