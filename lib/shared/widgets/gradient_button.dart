import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool expanded;
  final Widget? leading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.radius = 30,
    this.expanded = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient(),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25534AB7),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 10),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onPressed,
        child:
            expanded ? SizedBox(width: double.infinity, child: child) : child,
      ),
    );
  }
}
