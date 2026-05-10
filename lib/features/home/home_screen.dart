import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/service_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/booking_provider.dart';
import '../../data/providers/service_provider.dart';
import '../../shared/widgets/service_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  bool _hasUnreadNotifications = true;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      context.read<ServiceProvider>().fetchServices(token: auth.token, onUnauthorized: auth.logout);
    });
  }

  void _onSearchChanged(ServiceProvider services, String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      services.setQuery(v);
    });
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Notifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _hasUnreadNotifications = false);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Mark all read', style: TextStyle(fontWeight: FontWeight.w800)),
                )
              ],
            ),
            const SizedBox(height: 10),
            _NotificationTile(
              title: 'Booking confirmed',
              subtitle: 'Your appointment is locked in. See details now.',
              icon: IconlyBold.tickSquare,
            ),
            _NotificationTile(
              title: 'Exclusive offer',
              subtitle: 'Use FIRST20 for 20% off your first booking.',
              icon: IconlyBold.ticketStar,
            ),
            _NotificationTile(
              title: 'New services added',
              subtitle: 'Trending glam packages are now live.',
              icon: IconlyBold.star,
            ),
          ],
        ),
      ),
    );
  }

  void _openFilters(ServiceProvider services) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (_) => _FilterSheet(services: services),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final services = context.watch<ServiceProvider>();
    final name = (auth.user?.name.split(' ').firstOrNull ?? 'Guest');

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (services.filtered.isEmpty) return;
          final s = services.filtered.first;
          context.read<BookingProvider>().start(s);
          Navigator.of(context).pushNamed(AppRoutes.serviceDetail, arguments: s.id);
        },
        backgroundColor: AppColors.primaryPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book Now +', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
          children: [
            Row(
              children: [
                Hero(
                  tag: 'user_avatar',
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: CachedNetworkImageProvider(
                      auth.user?.profileImage ?? 'https://source.unsplash.com/200x200/?portrait+woman',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back, $name',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('Find premium services near you',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openNotifications,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(IconlyLight.notification),
                      if (_hasUnreadNotifications)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => _onSearchChanged(services, v),
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      prefixIcon: const Icon(IconlyLight.search),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _search.clear();
                          services.setQuery('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _openFilters(services),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient(),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(IconlyBold.filter, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (services.isLoading) _CategoriesShimmer() else SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: services.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = services.categories[i];
                  final active = c == services.activeCategory;
                  return InkWell(
                    onTap: () => services.setCategory(c),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primaryPurple : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: active ? AppColors.primaryPurple : AppColors.border),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          color: active ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            if (services.isLoading) _PromoShimmer() else _PromoBanner(),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Popular Services', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('See all')),
              ],
            ),
            const SizedBox(height: 10),
            if (services.isLoading)
              _LoadingGrid()
            else
              _ServicesGrid(
                items: services.filtered,
                onTap: (s) => Navigator.of(context).pushNamed(AppRoutes.serviceDetail, arguments: s.id),
                onBook: (s) {
                  context.read<BookingProvider>().start(s);
                  Navigator.of(context).pushNamed(AppRoutes.serviceDetail, arguments: s.id);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x1A534AB7), blurRadius: 18, offset: Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('20% OFF on First Booking',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        )),
                const SizedBox(height: 6),
                Text('Use code: FIRST20',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Text('FIRST20', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFE9E7F5),
        highlightColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _CategoriesShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: const Color(0xFFE9E7F5),
          highlightColor: Colors.white,
          child: Container(
            width: 86,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9E7F5),
      highlightColor: Colors.white,
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  final List<ServiceModel> items;
  final ValueChanged<ServiceModel> onTap;
  final ValueChanged<ServiceModel> onBook;

  const _ServicesGrid({required this.items, required this.onTap, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, i) {
        final s = items[i];
        return ServiceCard(
          service: s,
          onTap: () => onTap(s),
          onBook: () => onBook(s),
        );
      },
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _NotificationTile({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final ServiceProvider services;
  const _FilterSheet({required this.services});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _category = widget.services.activeCategory;
  late RangeValues _price = RangeValues(widget.services.minPrice, widget.services.maxPrice);
  late double _minRating = widget.services.minRating;
  late double _maxDuration = widget.services.maxDuration.toDouble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filters', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  widget.services.clearFilters();
                  setState(() {
                    _category = widget.services.activeCategory;
                    _price = RangeValues(widget.services.minPrice, widget.services.maxPrice);
                    _minRating = widget.services.minRating;
                    _maxDuration = widget.services.maxDuration.toDouble();
                  });
                },
                child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.w800)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text('Category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.services.categories.map((c) {
              final active = c == _category;
              return InkWell(
                onTap: () => setState(() => _category = c),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primaryPurple : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: active ? AppColors.primaryPurple : AppColors.border),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(color: active ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w800),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text('Price Range', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          RangeSlider(
            values: _price,
            min: 0,
            max: 5000,
            divisions: 50,
            activeColor: AppColors.primaryPurple,
            labels: RangeLabels('₹${_price.start.round()}', '₹${_price.end.round()}'),
            onChanged: (v) => setState(() => _price = v),
          ),
          const SizedBox(height: 10),
          Text('Minimum Rating', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: AppColors.primaryPurple,
            label: _minRating.toStringAsFixed(1),
            onChanged: (v) => setState(() => _minRating = v),
          ),
          const SizedBox(height: 10),
          Text('Max Duration (min)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          Slider(
            value: _maxDuration,
            min: 15,
            max: 180,
            divisions: 11,
            activeColor: AppColors.primaryPurple,
            label: _maxDuration.round().toString(),
            onChanged: (v) => setState(() => _maxDuration = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    widget.services.applyFilters(
                      category: _category,
                      minPrice: _price.start,
                      maxPrice: _price.end,
                      minRating: _minRating,
                      maxDuration: _maxDuration.round(),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

