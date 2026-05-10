import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/storage_service.dart';
import '../../shared/widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  void _goNext() {
    if (_index < 2) {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  void _finish() {
    context.read<StorageService>().setHasSeenOnboarding(true);
    final authed = context.read<AuthProvider>().isAuthenticated;
    Navigator.of(context).pushReplacementNamed(authed ? AppRoutes.main : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: AppStrings.unsplashLuxuryInterior,
              fit: BoxFit.cover,
              placeholder: (_, __) => Shimmer.fromColors(
                baseColor: const Color(0xFFE9E7F5),
                highlightColor: Colors.white,
                child: Container(color: const Color(0xFFE9E7F5)),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xA0000000), Color(0xF0000000)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _finish,
                      child: const Text('Skip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 320,
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (i) => setState(() => _index = i),
                      children: const [
                        _Slide(
                          title: 'Book Premium Salon Services',
                          subtitle: 'Easy booking, best prices',
                          aIcon: IconlyBold.calendar,
                          aTitle: 'Instant Booking',
                          aSub: 'Reserve in seconds',
                          bIcon: IconlyBold.star,
                          bTitle: 'Best Rates',
                          bSub: 'Premium quality',
                        ),
                        _Slide(
                          title: 'Luxury Experience, Anytime',
                          subtitle: 'Curated professionals & verified salons',
                          aIcon: IconlyBold.shieldDone,
                          aTitle: 'Trusted Pros',
                          aSub: 'Verified specialists',
                          bIcon: IconlyBold.location,
                          bTitle: 'Nearby Salons',
                          bSub: 'Pick your location',
                        ),
                        _Slide(
                          title: 'Rewards & Elite Benefits',
                          subtitle: 'Earn points with every booking',
                          aIcon: IconlyBold.wallet,
                          aTitle: 'Wallet & Offers',
                          aSub: 'Exclusive deals',
                          bIcon: IconlyBold.heart,
                          bTitle: 'Wishlist',
                          bSub: 'Save favorites',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SmoothPageIndicator(
                    controller: _controller,
                    count: 3,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: AppColors.primaryPink,
                      dotColor: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    expanded: true,
                    text: _index < 2 ? 'Next' : 'Get Started',
                    onPressed: _goNext,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData aIcon;
  final String aTitle;
  final String aSub;
  final IconData bIcon;
  final String bTitle;
  final String bSub;

  const _Slide({
    required this.title,
    required this.subtitle,
    required this.aIcon,
    required this.aTitle,
    required this.aSub,
    required this.bIcon,
    required this.bTitle,
    required this.bSub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _FeatureCard(icon: aIcon, title: aTitle, subtitle: aSub)),
            const SizedBox(width: 12),
            Expanded(child: _FeatureCard(icon: bIcon, title: bTitle, subtitle: bSub)),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient(),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

