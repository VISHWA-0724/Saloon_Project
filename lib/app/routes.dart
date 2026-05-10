import 'package:flutter/material.dart';

import '../features/admin/admin_dashboard_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/booking/booking_confirmed_screen.dart';
import '../features/booking/my_bookings_screen.dart';
import '../features/booking/payment_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/personal_info_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/service/service_detail_screen.dart';
import '../shared/layouts/main_layout.dart';

class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const main = '/main';
  static const admin = '/admin';
  static const serviceDetail = '/service';
  static const payment = '/payment';
  static const bookingConfirmed = '/booking-confirmed';
  static const myBookings = '/my-bookings';
  static const settings = '/settings';
  static const personalInfo = '/personal-info';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case AppRoutes.onboarding:
        return _page(const OnboardingScreen());
      case AppRoutes.login:
        return _page(const LoginScreen());
      case AppRoutes.register:
        return _page(const RegisterScreen());
      case AppRoutes.main:
        return _page(const MainLayout());
      case AppRoutes.admin:
        return _page(const AdminDashboardScreen());
      case AppRoutes.serviceDetail:
        return _page(ServiceDetailScreen(serviceId: routeSettings.arguments as String));
      case AppRoutes.payment:
        return _page(const PaymentScreen());
      case AppRoutes.bookingConfirmed:
        return _page(const BookingConfirmedScreen());
      case AppRoutes.myBookings:
        return _page(const MyBookingsScreen());
      case AppRoutes.settings:
        return _page(const SettingsScreen());
      case AppRoutes.personalInfo:
        return _page(const PersonalInfoScreen());
      default:
        return _page(const HomeScreen());
    }
  }

  static MaterialPageRoute _page(Widget child) =>
      MaterialPageRoute(builder: (_) => child);
}

