import 'package:intl/intl.dart';

class Helpers {
  static final _dateFmt = DateFormat('EEE, dd MMM');

  static String formatDate(DateTime d) => _dateFmt.format(d);

  static bool isValidEmail(String v) {
    final r = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return r.hasMatch(v.trim());
  }

  static String bookingId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return 'SALON${ts.substring(ts.length - 6)}';
  }
}
