import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum ActionButtonVariant { primary, secondary, danger, ghost }

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ActionButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;

  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = ActionButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = AppSpacing.minTouchTarget,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case ActionButtonVariant.primary:
        bg = AppColors.accent;
        fg = AppColors.textOnAccent;
        border = BorderSide.none;
        break;
      case ActionButtonVariant.secondary:
        bg = AppColors.surfaceElevated;
        fg = AppColors.textPrimary;
        border = const BorderSide(
          color: AppColors.surfaceHighlight,
          width: 1.2,
        );
        break;
      case ActionButtonVariant.danger:
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        border = const BorderSide(color: AppColors.error, width: 1);
        break;
      case ActionButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.textSecondary;
        border = BorderSide.none;
        break;
    }

    final content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          side: border,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
        ),
        child: content,
      ),
    );
  }
}
