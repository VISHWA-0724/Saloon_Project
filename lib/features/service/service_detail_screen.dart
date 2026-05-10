import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/service_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/booking_provider.dart';
import '../../data/providers/service_provider.dart';
import '../../shared/widgets/gradient_button.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceModel? _service;
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final p = context.read<ServiceProvider>();
    final s = await p.fetchServiceById(widget.serviceId, token: auth.token, onUnauthorized: auth.logout);
    if (!mounted) return;
    setState(() {
      _service = s;
      _loading = false;
    });
    if (s != null) context.read<BookingProvider>().start(s);
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final s = _service;

    if (_loading) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFE9E7F5),
              highlightColor: Colors.white,
              child: Column(
                children: [
                  Container(height: 240, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18))),
                  const SizedBox(height: 14),
                  Container(height: 18, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 10),
                  Container(height: 18, width: 220, color: Colors.white),
                  const SizedBox(height: 20),
                  Row(
                    children: List.generate(
                      3,
                      (_) => Expanded(
                        child: Container(
                          height: 42,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service')),
        body: const Center(child: Text('Service not found.')),
      );
    }

    final bill = booking.bill();
    final headerUrl = s.images.isNotEmpty ? s.images.first : AppStrings.unsplashHairSalon;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 320,
            width: double.infinity,
            child: Hero(
              tag: s.heroTag,
              child: CachedNetworkImage(
                imageUrl: headerUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: const Color(0xFFE9E7F5),
                  highlightColor: Colors.white,
                  child: Container(color: const Color(0xFFE9E7F5)),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _CircleIcon(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _CircleIcon(icon: IconlyLight.send, onTap: () {}),
                  const SizedBox(width: 10),
                  _CircleIcon(icon: IconlyLight.upload, onTap: () {}),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.62,
            minChildSize: 0.62,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 18, offset: Offset(0, -10))],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 46,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            s.category.toUpperCase(),
                            style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.star_rounded, color: Color(0xFFF6B100), size: 18),
                        const SizedBox(width: 4),
                        Text('${s.rating.toStringAsFixed(1)} - ${s.reviewCount} reviews',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(s.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${AppStrings.currencySymbol}${s.price}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${AppStrings.currencySymbol}${s.originalPrice}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPink.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('${s.duration} min',
                              style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.description,
                      maxLines: _expanded ? 99 : 3,
                      overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        child: Text(_expanded ? 'Read less' : 'Read more', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Select Date', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 74,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 10,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final d = DateTime.now().add(Duration(days: i));
                          final selected = d.year == booking.date.year && d.month == booking.date.month && d.day == booking.date.day;
                          return InkWell(
                            onTap: () => booking.setDate(d),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 88,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primaryPurple : AppColors.primaryPurple.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected ? AppColors.primaryPurple : AppColors.border,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Helpers.formatDate(d).split(',').first,
                                    style: TextStyle(
                                      color: selected ? Colors.white : AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    Helpers.formatDate(d).split(',').last.trim(),
                                    style: TextStyle(
                                      color: selected ? Colors.white : AppColors.textPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Select Time', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: s.availableSlots.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.5,
                      ),
                      itemBuilder: (_, i) {
                        final slot = s.availableSlots[i];
                        final selected = slot == booking.slot;
                        return InkWell(
                          onTap: () => booking.setSlot(slot),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primaryPurple.withValues(alpha: 0.10) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? AppColors.primaryPurple : AppColors.border,
                                width: selected ? 1.6 : 1,
                              ),
                            ),
                            child: Text(
                              slot,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: selected ? AppColors.primaryPurple : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Text('Enhance Your Service',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    ...List.generate(s.addOns.length, (i) {
                      final a = s.addOns[i];
                      final checked = booking.selectedAddOns.contains(i);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: checked,
                              activeColor: AppColors.primaryPurple,
                              onChanged: (_) => booking.toggleAddOn(i),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  Text('${a.duration} min',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text('${AppStrings.currencySymbol}${a.price}', style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -10))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total Price', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text('${AppStrings.currencySymbol}${bill.total}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      expanded: true,
                      radius: 30,
                      text: 'Proceed to Book',
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.payment),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

