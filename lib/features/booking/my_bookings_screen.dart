import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/image_url.dart';
import '../../data/models/booking_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/booking_provider.dart';
import '../../data/services/api_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  String _filter = 'All dates';

  bool _loading = true;
  List<BookingModel> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    try {
      final api =
          ApiService.create(token: auth.token, onUnauthorized: auth.logout);
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
    final current = _items
        .where((b) => b.status == 'upcoming' || b.status == 'confirmed')
        .toList();
    final cancelled = _items.where((b) => b.status == 'cancelled').toList();
    final list = idx == 0 ? current : cancelled;
    return list.where(_matchesDateFilter).toList();
  }

  bool _matchesDateFilter(BookingModel booking) {
    final now = DateTime.now();
    final date =
        DateTime(booking.date.year, booking.date.month, booking.date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (_filter == 'This week') {
      final end = today.add(const Duration(days: 7));
      return !date.isBefore(today) && date.isBefore(end);
    }
    if (_filter == 'This month') {
      return date.year == today.year && date.month == today.month;
    }
    return true;
  }

  Future<void> _reschedule(BookingModel booking) async {
    if (booking.status != 'upcoming') return;
    final result = await showModalBottomSheet<_RescheduleChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RescheduleSheet(booking: booking),
    );
    if (result == null) return;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    try {
      final api =
          ApiService.create(token: auth.token, onUnauthorized: auth.logout);
      await api.patch('/api/bookings/${booking.id}/reschedule', data: {
        'date': result.date.toIso8601String(),
        'timeSlot': result.timeSlot,
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showDetails(BookingModel booking) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking Details',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _DetailRow(label: 'Booking ID', value: booking.bookingId),
            _DetailRow(label: 'Service', value: booking.serviceTitle),
            _DetailRow(label: 'Salon', value: booking.salonName),
            _DetailRow(
              label: 'Date',
              value:
                  '${booking.date.day}/${booking.date.month}/${booking.date.year}',
            ),
            _DetailRow(label: 'Time', value: booking.timeSlot),
            _DetailRow(label: 'Status', value: _statusLabel(booking.status)),
            _DetailRow(
              label: 'Total',
              value: '${AppStrings.currencySymbol}${booking.total}',
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    if (status == 'confirmed') return 'Confirmed';
    if (status == 'cancelled') return 'Cancelled';
    if (status == 'past') return 'Locked';
    return 'Pending salon approval';
  }

  Future<void> _cancel(BookingModel booking) async {
    if (booking.status != 'upcoming') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This booking is already locked.')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    try {
      final api =
          ApiService.create(token: auth.token, onUnauthorized: auth.logout);
      await api.patch('/api/bookings/${booking.id}/cancel');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
                        Text('My Bookings',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Track & manage your appointments',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: _filter,
                    items: const [
                      DropdownMenuItem(
                          value: 'All dates', child: Text('All dates')),
                      DropdownMenuItem(
                          value: 'This week', child: Text('This week')),
                      DropdownMenuItem(
                          value: 'This month', child: Text('This month')),
                    ],
                    onChanged: (v) =>
                        setState(() => _filter = v ?? 'All dates'),
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
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      children: [
                        if (_byTab().isEmpty)
                          _EmptyBookingsState(
                            message: _tabs.index == 0
                                ? 'No active bookings yet.'
                                : 'No cancelled bookings.',
                          )
                        else
                          ..._byTab().map(
                            (b) => _BookingCard(
                              b: b,
                              onCancel: () => _cancel(b),
                              onReschedule: () => _reschedule(b),
                              onViewDetails: () => _showDetails(b),
                            ),
                          ),
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

class _BookingCard extends StatelessWidget {
  final BookingModel b;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback onViewDetails;

  const _BookingCard({
    required this.b,
    required this.onCancel,
    required this.onReschedule,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final locked = b.status != 'upcoming';

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
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: ImageUrl.resolve(b.imageUrl),
                  height: 58,
                  width: 58,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 58,
                    width: 58,
                    color: const Color(0xFFE9E7F5),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 58,
                    width: 58,
                    color: const Color(0xFFE9E7F5),
                    child: const Icon(Icons.spa_rounded,
                        color: AppColors.primaryPurple),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.serviceTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${b.salonName} - ${b.timeSlot}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(
                            '${b.date.day}/${b.date.month}/${b.date.year}'),
                        _StatusPill(status: b.status),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('${AppStrings.currencySymbol}${b.total}',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          if (locked)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onViewDetails,
                child: const Text('View Details',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 430;
                final buttonWidth =
                    narrow ? (constraints.maxWidth - 10) / 2 : null;

                Widget sized(Widget child, {bool wide = false}) {
                  if (!narrow) return Expanded(child: child);
                  return SizedBox(
                      width: wide ? constraints.maxWidth : buttonWidth,
                      child: child);
                }

                final children = [
                  sized(
                    OutlinedButton(
                      onPressed: onReschedule,
                      child: const Text('Reschedule',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  sized(
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: onCancel,
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  sized(
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onViewDetails,
                      child: const Text('View Details',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    wide: true,
                  ),
                ];

                if (narrow) {
                  return Wrap(spacing: 10, runSpacing: 10, children: children);
                }

                return Row(
                  children: [
                    children[0],
                    const SizedBox(width: 10),
                    children[1],
                    const SizedBox(width: 10),
                    children[2],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;

  const _InfoPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryPurple,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == 'cancelled';
    final label = switch (status) {
      'confirmed' => 'Confirmed',
      'cancelled' => 'Cancelled',
      'past' => 'Locked',
      _ => 'Pending',
    };
    final color = isCancelled ? AppColors.danger : AppColors.primaryPurple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _EmptyBookingsState extends StatelessWidget {
  final String message;

  const _EmptyBookingsState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(IconlyBold.calendar, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RescheduleChoice {
  final DateTime date;
  final String timeSlot;

  const _RescheduleChoice({required this.date, required this.timeSlot});
}

class _RescheduleSheet extends StatefulWidget {
  final BookingModel booking;

  const _RescheduleSheet({required this.booking});

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late DateTime _date = widget.booking.date.isBefore(DateTime.now())
      ? DateTime.now()
      : widget.booking.date;
  late String _slot =
      widget.booking.timeSlot.isEmpty ? _slots.first : widget.booking.timeSlot;

  static const _slots = ['10:00', '11:30', '13:00', '15:00', '17:30', '19:00'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 0, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reschedule Booking',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final d = DateTime.now().add(Duration(days: i + 1));
                final selected = d.year == _date.year &&
                    d.month == _date.month &&
                    d.day == _date.day;
                return InkWell(
                  onTap: () => setState(() => _date = d),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 86,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryPurple
                          : AppColors.primaryPurple.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: selected
                              ? AppColors.primaryPurple
                              : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${d.day}/${d.month}',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _weekday(d.weekday),
                          style: TextStyle(
                            color:
                                selected ? Colors.white : AppColors.textPrimary,
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _slots.map((slot) {
              final selected = slot == _slot;
              return ChoiceChip(
                selected: selected,
                label: Text(slot),
                selectedColor: AppColors.primaryPurple,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                onSelected: (_) => setState(() => _slot = slot),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              _RescheduleChoice(date: _date, timeSlot: _slot),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save New Time',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  String _weekday(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[(weekday - 1).clamp(0, 6).toInt()];
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
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
                const SizedBox(height: 6),
                Text('Explore more and unlock Elite rewards.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12)),
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Open Home to explore more services.')),
                );
              },
              child: const Text('Explore More',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          )
        ],
      ),
    );
  }
}
