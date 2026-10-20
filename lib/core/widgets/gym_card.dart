import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class GymCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final double? width;
  final double? height;

  const GymCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      width: width,
      height: height,
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: AppSpacing.roundedMd,
        border: border ?? Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedMd,
          splashColor: AppColors.accentMuted,
          highlightColor: AppColors.surfaceHighlight.withValues(alpha: 0.3),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
