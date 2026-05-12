import 'package:flutter/material.dart';

import '../../features/booking/my_bookings_screen.dart';
import '../../features/chatbot/style_advisor_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../widgets/bottom_nav.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;

  final _tabs = const [
    HomeScreen(),
    StyleAdvisorScreen(),
    MyBookingsScreen(),
    WishlistScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: BottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
