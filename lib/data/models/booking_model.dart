class BookingModel {
  final String id;
  final String bookingId;
  final String status; // upcoming/confirmed/cancelled
  final String serviceTitle;
  final String salonName;
  final String salonLocation;
  final String imageUrl;
  final DateTime date;
  final String timeSlot;
  final int total;

  const BookingModel({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.serviceTitle,
    required this.salonName,
    required this.salonLocation,
    required this.imageUrl,
    required this.date,
    required this.timeSlot,
    required this.total,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: (json['_id'] ?? json['id']).toString(),
        bookingId: (json['bookingId'] ?? '').toString(),
        status: (json['status'] ?? 'upcoming').toString(),
        serviceTitle: (json['serviceTitle'] ??
                json['service']?['title'] ??
                json['serviceId']?['title'] ??
                '')
            .toString(),
        salonName: (json['salonName'] ??
                json['service']?['salonName'] ??
                json['serviceId']?['salonName'] ??
                'SalonEase Studio')
            .toString(),
        salonLocation: (json['salonLocation'] ??
                json['service']?['salonLocation'] ??
                json['serviceId']?['salonLocation'] ??
                'Premium Street, City')
            .toString(),
        imageUrl: (json['imageUrl'] ??
                _firstImage(json['service']) ??
                _firstImage(json['serviceId']) ??
                '')
            .toString()
            .trim(),
        date: DateTime.tryParse((json['date'] ?? '').toString()) ??
            DateTime.now(),
        timeSlot: (json['timeSlot'] ?? '').toString(),
        total: _asInt(json['total']),
      );
}

String? _firstImage(dynamic service) {
  if (service is! Map<String, dynamic>) return null;
  final images = service['images'];
  if (images is! List || images.isEmpty) return null;
  return images.first?.toString();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
