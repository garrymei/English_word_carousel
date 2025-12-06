import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class EwcButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;

  const EwcButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = primary ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = primary ? scheme.onPrimary : scheme.onSurface;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.check, color: fg),
      label: Text(
        label,
        style: TextStyle(
          color: fg,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 12,
        shadowColor: AppColors.neonCyan.withValues(alpha: 0.6),
        side: BorderSide(
          color: AppColors.neonCyan.withValues(alpha: primary ? 0.9 : 0.5),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  }
}
