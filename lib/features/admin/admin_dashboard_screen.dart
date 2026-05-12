import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/service_model.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = const {};
  List<BookingModel> _bookings = const [];
  List<UserModel> _customers = const [];
  List<ServiceModel> _services = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api =
          ApiService.create(token: auth.token, onUnauthorized: auth.logout);
      final dashboard =
          await api.get('/api/admin/dashboard') as Map<String, dynamic>;
      final bookings =
          await api.get('/api/admin/bookings') as Map<String, dynamic>;
      final customers =
          await api.get('/api/admin/customers') as Map<String, dynamic>;
      final services = await api.get('/api/services') as List;
      if (!mounted) return;
      setState(() {
        _stats =
            (dashboard['stats'] as Map?)?.cast<String, dynamic>() ?? const {};
        _bookings = ((bookings['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(BookingModel.fromJson)
            .toList();
        _customers = ((customers['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(UserModel.fromJson)
            .toList();
        _services = services
            .cast<Map<String, dynamic>>()
            .map(ServiceModel.fromJson)
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _setStatus(BookingModel booking, String status) async {
    if (booking.status != 'upcoming') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This booking status is already locked.')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    try {
      final api =
          ApiService.create(token: auth.token, onUnauthorized: auth.logout);
      await api.patch('/api/admin/bookings/${booking.id}/status',
          data: {'status': status});
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _addService() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddServiceSheet(),
    );
    if (created == true) await _load();
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      floatingActionButton: _tab == 3
          ? FloatingActionButton.extended(
              onPressed: _addService,
              backgroundColor: AppColors.primaryPurple,
              icon: const Icon(Icons.add_business_rounded, color: Colors.white),
              label: const Text('Add Service',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 92),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Owner Dashboard',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(auth.user?.email ?? 'admin@salonease.com',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded)),
                  IconButton(
                      onPressed: _logout, icon: const Icon(IconlyLight.logout)),
                ],
              ),
              const SizedBox(height: 14),
              _AdminTabs(
                  value: _tab,
                  onChanged: (value) => setState(() => _tab = value)),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _EmptyState(message: _error!)
              else if (_tab == 0)
                _Overview(stats: _stats, bookings: _bookings)
              else if (_tab == 1)
                _BookingsList(bookings: _bookings, onStatusChanged: _setStatus)
              else if (_tab == 2)
                _CustomersList(customers: _customers)
              else
                _ServicesList(services: _services, onAdd: _addService),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTabs extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _AdminTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = const ['Overview', 'Bookings', 'Customers', 'Services'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = value == index;
          return Padding(
            padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : 8),
            child: SizedBox(
              width: index == 2 ? 118 : 104,
              child: ChoiceChip(
                selected: selected,
                label: Center(child: Text(items[index])),
                selectedColor: AppColors.primaryPurple,
                labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800),
                onSelected: (_) => onChanged(index),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<BookingModel> bookings;

  const _Overview({required this.stats, required this.bookings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatsGrid(stats: stats),
        const SizedBox(height: 18),
        Text('Latest Bookings',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (bookings.isEmpty)
          const _EmptyState(message: 'No bookings yet.')
        else
          ...bookings
              .take(6)
              .map((booking) => _AdminBookingTile(booking: booking)),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('Customers', '${stats['users'] ?? 0}', IconlyBold.profile),
      _StatItem('Services', '${stats['services'] ?? 0}', Icons.spa_outlined),
      _StatItem('Bookings', '${stats['bookings'] ?? 0}', IconlyBold.calendar),
      _StatItem(
          'Revenue',
          '${AppStrings.currencySymbol}${stats['revenue'] ?? 0}',
          IconlyBold.wallet),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (_, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(item.icon, color: AppColors.primaryPurple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    Text(item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookingsList extends StatelessWidget {
  final List<BookingModel> bookings;
  final void Function(BookingModel booking, String status) onStatusChanged;

  const _BookingsList({required this.bookings, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const _EmptyState(message: 'No customer bookings yet.');
    }
    return Column(
      children: bookings
          .map((booking) => _AdminBookingTile(
                booking: booking,
                onStatusChanged: (status) => onStatusChanged(booking, status),
              ))
          .toList(),
    );
  }
}

class _AdminBookingTile extends StatelessWidget {
  final BookingModel booking;
  final ValueChanged<String>? onStatusChanged;

  const _AdminBookingTile({required this.booking, this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final locked = booking.status != 'upcoming';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 520;
          final info = Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(IconlyBold.calendar,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.serviceTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                        '${booking.bookingId} - ${booking.timeSlot} - ${AppStrings.currencySymbol}${booking.total}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          );
          final actions = locked || onStatusChanged == null
              ? _StatusChip(status: booking.status)
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => onStatusChanged?.call('confirmed'),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Confirm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => onStatusChanged?.call('cancelled'),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ],
                );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 10),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _CustomersList extends StatelessWidget {
  final List<UserModel> customers;

  const _CustomersList({required this.customers});

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return const _EmptyState(message: 'No customers registered yet.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Customers',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('${customers.length} registered customer accounts',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        ...customers.map((customer) => _CustomerTile(customer: customer)),
      ],
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final UserModel customer;

  const _CustomerTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    final initial = customer.name.trim().isEmpty
        ? '?'
        : customer.name.trim().characters.first.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 520;
          final details = Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.1),
                child: Text(initial,
                    style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(customer.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(customer.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          );
          final metrics = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _MiniMetric(
                  label: 'Bookings', value: customer.bookingsCount.toString()),
              _MiniMetric(label: 'Points', value: customer.points.toString()),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 10),
                metrics,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 12),
              metrics,
            ],
          );
        },
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.primaryPurple, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ServicesList extends StatelessWidget {
  final List<ServiceModel> services;
  final VoidCallback onAdd;

  const _ServicesList({required this.services, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Shop Services',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const Spacer(),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (services.isEmpty)
          const _EmptyState(
              message: 'No services yet. Add the first salon service.')
        else
          ...services.map((service) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.spa_rounded,
                          color: AppColors.primaryPurple),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(
                              '${service.category} - ${service.duration} min - ${service.salonLocation}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text('${AppStrings.currencySymbol}${service.price}',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              )),
      ],
    );
  }
}

class _AddServiceSheet extends StatefulWidget {
  const _AddServiceSheet();

  @override
  State<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<_AddServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController();
  final _location = TextEditingController(text: 'Main Road, City');
  String _category = 'Hair';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _duration.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    try {
      final api =
          ApiService.create(token: auth.token, onUnauthorized: auth.logout);
      await api.post('/api/services', data: {
        'title': _title.text.trim(),
        'category': _category,
        'description': _description.text.trim(),
        'price': int.parse(_price.text.trim()),
        'originalPrice': int.parse(_price.text.trim()) + 200,
        'duration': int.parse(_duration.text.trim()),
        'images': [AppStrings.unsplashBeautyInterior],
        'availableSlots': [
          '10:00',
          '11:30',
          '13:00',
          '15:00',
          '17:30',
          '19:00'
        ],
        'salonName': 'SalonEase Studio',
        'salonLocation': _location.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          18, 0, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Service',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Service name'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const ['Hair', 'Nails', 'Spa', 'Makeup']
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value ?? 'Hair'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                    validator: (value) =>
                        int.tryParse((value ?? '').trim()) == null
                            ? 'Number required'
                            : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _duration,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Duration min'),
                    validator: (value) =>
                        int.tryParse((value ?? '').trim()) == null
                            ? 'Number required'
                            : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Shop location'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving...' : 'Save Service'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child:
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem(this.label, this.value, this.icon);
}
