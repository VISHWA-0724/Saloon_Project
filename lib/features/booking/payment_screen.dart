import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/image_url.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/booking_provider.dart';
import '../../shared/widgets/gradient_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _coupon = TextEditingController();

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking(
      BookingProvider booking, AuthProvider auth) async {
    if (booking.service == null || booking.slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and slot first')),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final ok = await booking.createBooking(
      token: auth.token,
      onUnauthorized: auth.logout,
    );
    if (!mounted) return;
    navigator.pop();
    if (ok) {
      navigator.pushNamedAndRemoveUntil(
          AppRoutes.bookingConfirmed, (_) => false);
      return;
    }
    messenger.showSnackBar(
        SnackBar(content: Text(booking.error ?? 'Booking failed')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final booking = context.watch<BookingProvider>();
    final s = booking.service;
    final bill = booking.bill();

    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: const Center(child: Text('No service selected.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
        children: [
          _Stepper(),
          const SizedBox(height: 12),
          _ServiceSummaryCard(
            imageUrl: ImageUrl.first(s.images),
            title: s.title,
            salon: s.salonName,
            time: '${booking.slot ?? 'Select slot'} - ${s.duration} min',
          ),
          const SizedBox(height: 14),
          Text('Demo Payment Method',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _PayMethod(
            title: 'Credit/Debit Card',
            subtitle: 'Demo card payment completes instantly',
            icon: IconlyBold.wallet,
            selected: booking.paymentMethod == 'card',
            onTap: () => booking.setPaymentMethod('card'),
          ),
          _PayMethod(
            title: 'UPI / GPay',
            subtitle: 'Demo UPI payment completes instantly',
            icon: IconlyBold.buy,
            selected: booking.paymentMethod == 'upi',
            onTap: () => booking.setPaymentMethod('upi'),
          ),
          _PayMethod(
            title: 'SalonEase Wallet',
            subtitle: 'Demo wallet balance',
            icon: IconlyBold.wallet,
            selected: booking.paymentMethod == 'wallet',
            onTap: () => booking.setPaymentMethod('wallet'),
          ),
          _PayMethod(
            title: 'Pay at Salon',
            subtitle: 'Cash or card at counter',
            icon: IconlyBold.ticketStar,
            selected: booking.paymentMethod == 'salon',
            onTap: () => booking.setPaymentMethod('salon'),
          ),
          const SizedBox(height: 14),
          Text('Offers & Coupons',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _coupon,
                  decoration:
                      const InputDecoration(hintText: 'Enter coupon code'),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                onPressed: booking.isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok =
                            await context.read<BookingProvider>().applyCoupon(
                                  token: auth.token,
                                  onUnauthorized: auth.logout,
                                  code: _coupon.text,
                                );
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text(ok
                                  ? 'Coupon applied!'
                                  : booking.error ?? 'Coupon invalid')),
                        );
                      },
                child: const Text('Apply',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Hint: Try FIRST20 for first booking discount',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Text('Bill Details',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _kv('Subtotal', '${AppStrings.currencySymbol}${bill.subtotal}'),
                const SizedBox(height: 8),
                _kv('GST (18%)', '${AppStrings.currencySymbol}${bill.gst}'),
                const SizedBox(height: 8),
                _kv('Discount', '-${AppStrings.currencySymbol}${bill.discount}',
                    valueColor: AppColors.danger),
                const SizedBox(height: 10),
                Divider(color: Colors.grey.withValues(alpha: 0.25)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('TOTAL PAYABLE',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text('${AppStrings.currencySymbol}${bill.total}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    dashPattern: const [6, 4],
                    color: AppColors.primaryPurple.withValues(alpha: 0.5),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Text(
                        'You save ${AppStrings.currencySymbol}${(s.originalPrice - s.price).clamp(0, 1 << 31)} today',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryPurple),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, -10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GradientButton(
              expanded: true,
              text:
                  booking.isLoading ? 'Completing...' : 'Complete Demo Payment',
              onPressed: booking.isLoading
                  ? null
                  : () => _confirmBooking(booking, auth),
            ),
            const SizedBox(height: 10),
            Text(
                'Demo payment records the booking instantly. No real money is charged.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {Color? valueColor}) {
    return Row(
      children: [
        Text(k, style: const TextStyle(color: AppColors.textSecondary)),
        const Spacer(),
        Text(v,
            style: TextStyle(fontWeight: FontWeight.w900, color: valueColor)),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget step(String label, bool active) {
      return Expanded(
        child: Row(
          children: [
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primaryPurple
                    : Colors.grey.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(active ? Icons.check : Icons.circle,
                  size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: active
                        ? AppColors.primaryPurple
                        : AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Row(
      children: [
        step('Select', true),
        Container(
            height: 2,
            width: 26,
            color: AppColors.primaryPurple.withValues(alpha: 0.3)),
        step('Payment', true),
        Container(
            height: 2, width: 26, color: Colors.grey.withValues(alpha: 0.2)),
        step('Confirm', false),
      ],
    );
  }
}

class _ServiceSummaryCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String salon;
  final String time;

  const _ServiceSummaryCard(
      {required this.imageUrl,
      required this.title,
      required this.salon,
      required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              imageUrl: imageUrl,
              height: 64,
              width: 64,
              fit: BoxFit.cover,
              placeholder: (_, __) => Shimmer.fromColors(
                baseColor: const Color(0xFFE9E7F5),
                highlightColor: Colors.white,
                child: Container(
                    height: 64, width: 64, color: const Color(0xFFE9E7F5)),
              ),
              errorWidget: (_, __, ___) => Container(
                  height: 64, width: 64, color: const Color(0xFFE9E7F5)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(salon,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(time,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryPurple,
                          fontSize: 12)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _PayMethod extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PayMethod(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppColors.primaryPurple : AppColors.border,
              width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryGradient() : null,
                color: selected
                    ? null
                    : AppColors.primaryPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : AppColors.primaryPurple,
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primaryPurple)
            else
              Icon(Icons.circle_outlined,
                  color: Colors.grey.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
