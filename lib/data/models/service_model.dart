class ServiceAddOn {
  final String name;
  final int price;
  final int duration;

  const ServiceAddOn({
    required this.name,
    required this.price,
    required this.duration,
  });

  factory ServiceAddOn.fromJson(Map<String, dynamic> json) => ServiceAddOn(
        name: (json['name'] ?? '').toString(),
        price: _asInt(json['price']),
        duration: _asInt(json['duration']),
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'price': price, 'duration': duration};
}

class ServiceModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final int price;
  final int originalPrice;
  final int duration;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final List<ServiceAddOn> addOns;
  final List<String> availableSlots;
  final String salonName;
  final String salonLocation;

  const ServiceModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.duration,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.addOns,
    required this.availableSlots,
    required this.salonName,
    required this.salonLocation,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: (json['_id'] ?? json['id']).toString(),
        title: (json['title'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        price: _asInt(json['price']),
        originalPrice: _asInt(json['originalPrice'] ?? json['price']),
        duration: _asInt(json['duration']),
        images: ((json['images'] ?? []) as List)
            .map((e) => e.toString().trim())
            .where((url) => url.isNotEmpty)
            .toList(),
        rating: ((json['rating'] ?? 0).toDouble()),
        reviewCount: _asInt(json['reviewCount']),
        addOns: ((json['addOns'] ?? []) as List)
            .map((e) => ServiceAddOn.fromJson(e as Map<String, dynamic>))
            .toList(),
        availableSlots: ((json['availableSlots'] ?? []) as List)
            .map((e) => e.toString())
            .toList(),
        salonName: (json['salonName'] ?? 'SalonEase Studio').toString(),
        salonLocation:
            (json['salonLocation'] ?? 'Premium Street, City').toString(),
      );

  String get heroTag => 'service_$id';
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
