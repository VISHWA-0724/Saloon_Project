import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/booking_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/booking_provider.dart';
import '../../data/services/api_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  String _filter = 'All dates';

  bool _loading = true;
  List<BookingModel> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    try {
      final api = ApiService.create(token: auth.token, onUnauthorized: auth.logout);
      final res = await api.dio.get('/api/bookings/my');
      final raw = res.data;
      final list = raw is List
          ? raw.cast<Map<String, dynamic>>()
          : ((raw['items'] as List?) ?? const []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _items = list.map(BookingModel.fromJson).toList();
        _loading = false;
      });
    } catch (_) {
      final last = context.read<BookingProvider>().lastBooking;
      setState(() {
        _items = last == null ? const [] : [last];
        _loading = false;
      });
    }
  }

  List<BookingModel> _byTab() {
    final idx = _tabs.index;
    if (idx == 0) return _items.where((b) => b.status == 'upcoming' || b.status == 'confirmed').toList();
    if (idx == 1) return _items.where((b) => b.status == 'past').toList();
    return _items.where((b) => b.status == 'cancelled').toList();
  }

  Future<void> _cancel(BookingModel booking) async {
    final auth = context.read<AuthProvider>();
    try {
      final api = ApiService.create(token: auth.token, onUnauthorized: auth.logout);
      await api.patch('/api/bookings/${booking.id}/cancel');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Bookings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Track & manage your appointments',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: _filter,
                    items: const [
                      DropdownMenuItem(value: 'All dates', child: Text('All dates')),
                      DropdownMenuItem(value: 'This week', child: Text('This week')),
                      DropdownMenuItem(value: 'This month', child: Text('This month')),
                    ],
                    onChanged: (v) => setState(() => _filter = v ?? 'All dates'),
                  )
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              labelColor: AppColors.primaryPurple,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryPurple,
              onTap: (_) => setState(() {}),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
                Tab(text: 'Cancelled'),
              ],
            ),
            Expanded(
              child: _loading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: 4,
                      itemBuilder: (_, __) => Shimmer.fromColors(
                        baseColor: const Color(0xFFE9E7F5),
                        highlightColor: Colors.white,
                        child: Container(
                          height: 110,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      children: [
                        ..._byTab().asMap().entries.map((e) {
                          final i = e.key;
                          final b = e.value;
                          final variant = i % 3;
                          if (variant == 0) return _BookingCardUpcoming(b: b, onCancel: () => _cancel(b));
                          if (variant == 1) return _BookingCardDetailed(b: b);
                          return _BookingCardMinimal(b: b);
                        }),
                        const SizedBox(height: 8),
                        _LoyaltyCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCardUpcoming extends StatelessWidget {
  final BookingModel b;
  final VoidCallback onCancel;

  const _BookingCardUpcoming({required this.b, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient(),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(IconlyBold.calendar, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.salonName, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${b.serviceTitle} - ${b.timeSlot}', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text('${AppStrings.currencySymbol}${b.total}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {},
                  child: const Text('Reschedule', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.danger),
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: onCancel,
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  child: const Text('View Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingCardDetailed extends StatelessWidget {
  final BookingModel b;
  const _BookingCardDetailed({required this.b});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: b.imageUrl,
              height: 74,
              width: 74,
              fit: BoxFit.cover,
              placeholder: (_, __) => Shimmer.fromColors(
                baseColor: const Color(0xFFE9E7F5),
                highlightColor: Colors.white,
                child: Container(height: 74, width: 74, color: const Color(0xFFE9E7F5)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.salonName, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(b.serviceTitle, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _pill('${b.date.day}/${b.date.month}'),
                    const SizedBox(width: 8),
                    _pill(b.timeSlot),
                  ],
                )
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${AppStrings.currencySymbol}${b.total}', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              IconButton(onPressed: () {}, icon: const Icon(IconlyLight.moreCircle)),
            ],
          )
        ],
      ),
    );
  }

  Widget _pill(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryPurple, fontSize: 12)),
    );
  }
}

class _BookingCardMinimal extends StatelessWidget {
  final BookingModel b;
  const _BookingCardMinimal({required this.b});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(IconlyBold.timeCircle, color: AppColors.primaryPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.serviceTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${b.salonName} - ${b.timeSlot}', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('${AppStrings.currencySymbol}${b.total}', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          IconButton(onPressed: () {}, icon: const Icon(IconlyLight.call, size: 20)),
          IconButton(onPressed: () {}, icon: const Icon(IconlyLight.message, size: 20)),
        ],
      ),
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Book 3 services, get 15% OFF!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 6),
                Text('Explore more and unlock Elite rewards.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: TextButton(
              onPressed: () {},
              child: const Text('Explore More', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          )
        ],
      ),
    );
  }
}

