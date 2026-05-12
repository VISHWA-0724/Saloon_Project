import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/image_url.dart';
import '../../data/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.user;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
          children: [
            Row(
              children: [
                Text('SalonEase',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const Spacer(),
                IconButton(
                    onPressed: () => _showProfileSnack(
                        context, 'No new notifications right now.'),
                    icon: const Icon(IconlyLight.notification)),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CachedNetworkImage(
                    imageUrl: AppStrings.unsplashBeautyInterior,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: const Color(0xFFE9E7F5),
                      highlightColor: Colors.white,
                      child: Container(
                          height: 160, color: const Color(0xFFE9E7F5)),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: -28,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        child: Hero(
                          tag: 'user_avatar',
                          child: CircleAvatar(
                            radius: 33,
                            backgroundImage: CachedNetworkImageProvider(
                              ImageUrl.profile(u?.profileImage),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.personalInfo),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient(),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(Icons.edit,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 44),
            Text(u?.name ?? 'Guest User',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(u?.email ?? 'guest@salonease.app',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(u?.phone ?? '+91 ***** *****',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _StatBox(
                        label: 'Bookings', value: '${u?.bookingsCount ?? 2}')),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatBox(
                        label: 'Points', value: '${u?.points ?? 120}')),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatBox(
                        label: 'Reviews', value: '${u?.reviewsCount ?? 8}')),
              ],
            ),
            const SizedBox(height: 16),
            Text('Account Settings',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            _Tile(
              icon: IconlyLight.profile,
              title: 'Personal Info',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.personalInfo),
            ),
            _Tile(
                icon: IconlyLight.notification,
                title: 'Notifications',
                onTap: () => _showProfileSnack(
                    context, 'No new notifications right now.')),
            _Tile(
                icon: IconlyLight.ticket,
                title: 'Refer & Earn',
                badge: 'NEW',
                onTap: () {
                  Clipboard.setData(
                    const ClipboardData(text: 'Join SalonEase with my invite.'),
                  );
                  _showProfileSnack(context, 'Referral invite copied.');
                }),
            _Tile(
              icon: IconlyLight.setting,
              title: 'Settings',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
            ),
            const SizedBox(height: 10),
            _Tile(
              icon: IconlyLight.logout,
              title: 'Logout',
              danger: true,
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              },
            ),
            const SizedBox(height: 16),
            _EliteCard(points: u?.points ?? 120),
          ],
        ),
      ),
    );
  }

  void _showProfileSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;
  final String? badge;
  const _Tile(
      {required this.icon,
      required this.title,
      required this.onTap,
      this.danger = false,
      this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: danger
                ? AppColors.danger.withValues(alpha: 0.10)
                : AppColors.primaryPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon,
              color: danger ? AppColors.danger : AppColors.primaryPurple,
              size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: danger ? AppColors.danger : null),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient(),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11)),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.withValues(alpha: 0.6)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _EliteCard extends StatelessWidget {
  final int points;
  const _EliteCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final progress = (points / 500).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SalonEase Elite',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text('$points / 500 points',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}
