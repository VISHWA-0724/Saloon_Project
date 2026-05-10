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
    return UserModel(
      id: (json['_id'] ?? json['id']).toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      profileImage: json['profileImage']?.toString(),
      role: (json['role'] ?? 'user').toString(),
      points: (json['points'] ?? 0) as int,
      bookingsCount: (json['bookingsCount'] ?? 0) as int,
      reviewsCount: (json['reviewsCount'] ?? 0) as int,
      wishlist: ((json['wishlist'] ?? []) as List).map((e) => e.toString()).toList(),
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

