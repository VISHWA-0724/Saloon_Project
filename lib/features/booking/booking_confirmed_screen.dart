import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/booking_provider.dart';
import '../../shared/widgets/gradient_button.dart';

class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>().lastBooking;
    final service = context.watch<BookingProvider>().service;

    final imageUrl = booking?.imageUrl ??
        service?.images.firstOrNull ??
        'https://source.unsplash.com/800x600/?salon+interior';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('Booking Confirmed!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('Your appointment has been scheduled successfully.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  booking?.bookingId ?? '#SALON123456',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryPurple),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ServiceCard(imageUrl: imageUrl, title: booking?.serviceTitle ?? (service?.title ?? 'Premium Service')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onPressed: () {},
                    child: const Text('Add to Calendar', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onPressed: () {},
                    child: const Text('Share', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GradientButton(
              expanded: true,
              text: 'View My Bookings',
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (_) => false),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (_) => false),
              child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  const _ServiceCard({required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Shimmer.fromColors(
              baseColor: const Color(0xFFE9E7F5),
              highlightColor: Colors.white,
              child: Container(height: 220, color: const Color(0xFFE9E7F5)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xC0000000)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient(),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text('PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 6),
                      Text('SalonEase Elite - Today 5:30 PM',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

