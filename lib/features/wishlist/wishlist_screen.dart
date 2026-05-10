import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/booking_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/service_provider.dart';
import '../../data/providers/wishlist_provider.dart';
import '../../shared/widgets/service_card.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final auth = context.read<AuthProvider>();
    final services = context.watch<ServiceProvider>().services;
    final items = services.where((s) => wishlist.isSaved(s.id)).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
          children: [
            Text('Wishlist', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Your saved premium services', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 150,
                      child: Lottie.network('https://assets9.lottiefiles.com/packages/lf20_kcxm4gkw.json'),
                    ),
                    const SizedBox(height: 10),
                    const Text('No wishlist items yet', style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              )
            else
              GridView.builder(
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
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.serviceDetail, arguments: s.id),
                    onBook: () {
                      context.read<BookingProvider>().start(s);
                      Navigator.of(context).pushNamed(AppRoutes.serviceDetail, arguments: s.id);
                    },
                    onWishlistTap: () async {
                      await wishlist.remove(
                        s.id,
                        token: auth.token,
                        onUnauthorized: auth.logout,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Removed from wishlist'),
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed: () {
                              wishlist.add(
                                s.id,
                                token: auth.token,
                                onUnauthorized: auth.logout,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

