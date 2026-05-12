import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

import '../../core/constants/app_colors.dart';

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const BottomNav({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 18, offset: Offset(0, -8)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: BottomNavigationBar(
        currentIndex: index,
        onTap: onChanged,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedIconTheme: const IconThemeData(size: 23),
        unselectedIconTheme: const IconThemeData(size: 22),
        items: const [
          BottomNavigationBarItem(icon: Icon(IconlyBold.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_rounded), label: 'AI Styles'),
          BottomNavigationBarItem(
              icon: Icon(IconlyBold.calendar), label: 'Bookings'),
          BottomNavigationBarItem(
              icon: Icon(IconlyBold.heart), label: 'Wishlist'),
          BottomNavigationBarItem(
              icon: Icon(IconlyBold.profile), label: 'Profile'),
        ],
      ),
    );
  }
}
