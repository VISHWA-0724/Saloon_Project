import 'package:flutter/foundation.dart';

import '../models/booking_model.dart';
import '../models/service_model.dart';
import '../services/api_service.dart';

class BookingBill {
  final int subtotal;
  final int gst;
  final int discount;
  final int total;

  const BookingBill({
    required this.subtotal,
    required this.gst,
    required this.discount,
    required this.total,
  });
}

class BookingProvider extends ChangeNotifier {
  ServiceModel? _service;
  DateTime _date = DateTime.now();
  String? _slot;
  final Set<int> _selectedAddOns = {};
  String _paymentMethod = 'card';
  String? _coupon;
  int _discount = 0;

  bool _loading = false;
  String? _error;
  BookingModel? _lastBooking;

  ServiceModel? get service => _service;
  ServiceModel? get selectedService => _service;
  DateTime get date => _date;
  DateTime get selectedDate => _date;
  String? get slot => _slot;
  String? get selectedSlot => _slot;
  Set<int> get selectedAddOns => _selectedAddOns;
  String get paymentMethod => _paymentMethod;
  String get selectedPaymentMethod => _paymentMethod;
  String? get coupon => _coupon;
  String? get appliedCoupon => _coupon;
  int get discount => _discount;
  bool get isLoading => _loading;
  String? get error => _error;
  BookingModel? get lastBooking => _lastBooking;

  void start(ServiceModel service) {
    _service = service;
    _date = DateTime.now();
    _slot = null;
    _selectedAddOns.clear();
    _paymentMethod = 'card';
    _coupon = null;
    _discount = 0;
    _error = null;
    notifyListeners();
  }

  void setDate(DateTime d) {
    _date = d;
    notifyListeners();
  }

  void setSlot(String s) {
    _slot = s;
    notifyListeners();
  }

  void toggleAddOn(int index) {
    if (_selectedAddOns.contains(index)) {
      _selectedAddOns.remove(index);
    } else {
      _selectedAddOns.add(index);
    }
    notifyListeners();
  }

  void setPaymentMethod(String v) {
    _paymentMethod = v;
    notifyListeners();
  }

  void clearState() {
    _service = null;
    _date = DateTime.now();
    _slot = null;
    _selectedAddOns.clear();
    _paymentMethod = 'card';
    _coupon = null;
    _discount = 0;
    _error = null;
    notifyListeners();
  }

  int _addOnsTotal() {
    final s = _service;
    if (s == null) return 0;
    var total = 0;
    for (final idx in _selectedAddOns) {
      if (idx >= 0 && idx < s.addOns.length) total += s.addOns[idx].price;
    }
    return total;
  }

  BookingBill bill() {
    final base = (_service?.price ?? 0) + _addOnsTotal();
    final gst = ((base * 18) / 100).round();
    final total = (base + gst - _discount).clamp(0, 1 << 31);
    return BookingBill(subtotal: base, gst: gst, discount: _discount, total: total);
  }

  Future<bool> applyCoupon({
    required String? token,
    required VoidCallback onUnauthorized,
    required String code,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiService.create(token: token, onUnauthorized: onUnauthorized);
      final b = bill();
      final res = await api.dio.post('/api/bookings/apply-coupon', data: {
        'code': code.trim(),
        'subtotal': b.subtotal,
      });
      final data = res.data as Map<String, dynamic>;
      _coupon = code.trim();
      _discount = (data['discount'] ?? 0) as int;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _coupon = null;
      _discount = 0;
      _error = 'Invalid coupon.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createBooking({
    required String? token,
    required VoidCallback onUnauthorized,
  }) async {
    final s = _service;
    if (s == null || _slot == null) {
      _error = 'Select a date & time slot.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiService.create(token: token, onUnauthorized: onUnauthorized);
      final b = bill();
      final addOns = _selectedAddOns.map((i) => s.addOns[i].toJson()).toList();

      final res = await api.dio.post('/api/bookings', data: {
        'serviceId': s.id,
        'date': _date.toIso8601String(),
        'timeSlot': _slot,
        'addOns': addOns,
        'paymentMethod': _paymentMethod,
        'coupon': _coupon,
        'subtotal': b.subtotal,
        'gst': b.gst,
        'discount': _discount,
        'total': b.total,
      });

      final data = res.data as Map<String, dynamic>;
      _lastBooking = BookingModel.fromJson(data['booking'] as Map<String, dynamic>);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}

