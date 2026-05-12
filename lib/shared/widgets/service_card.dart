import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/image_url.dart';
import '../../data/models/service_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/wishlist_provider.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;
  final VoidCallback onBook;
  final Future<void> Function()? onWishlistTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    required this.onBook,
    this.onWishlistTap,
  });

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final auth = context.read<AuthProvider>();
    final saved = wishlist.isSaved(service.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 178;
        final imageHeight = compact ? 104.0 : 116.0;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Hero(
                      tag: service.heroTag,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: CachedNetworkImage(
                          imageUrl: ImageUrl.first(service.images),
                          height: imageHeight,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: const Color(0xFFE9E7F5),
                            highlightColor: Colors.white,
                            child: Container(color: const Color(0xFFE9E7F5)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: imageHeight,
                            color: const Color(0xFFE9E7F5),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: InkWell(
                        onTap: () async {
                          if (onWishlistTap != null) {
                            await onWishlistTap!.call();
                            return;
                          }
                          await wishlist.toggle(
                            service.id,
                            token: auth.token,
                            onUnauthorized: auth.logout,
                          );
                        },
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Icon(
                            saved ? IconlyBold.heart : IconlyLight.heart,
                            color: saved
                                ? AppColors.primaryPink
                                : AppColors.textPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, compact ? 8 : 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFF6B100), size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${service.rating.toStringAsFixed(1)} (${service.reviewCount})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${service.duration} min',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppColors.primaryPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          service.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      SizedBox(height: compact ? 8 : 10),
                      if (compact)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PriceRow(service: service),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: _BookButton(onPressed: onBook),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: _PriceRow(service: service)),
                            const SizedBox(width: 8),
                            _BookButton(onPressed: onBook),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PriceRow extends StatelessWidget {
  final ServiceModel service;

  const _PriceRow({required this.service});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${AppStrings.currencySymbol}${service.price}',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          '${AppStrings.currencySymbol}${service.originalPrice}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.lineThrough,
              ),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BookButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryPurple,
        minimumSize: const Size(70, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      onPressed: onPressed,
      child: const Text('Book'),
    );
  }
}
