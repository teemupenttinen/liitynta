import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';

/// Toggle for favourites. Visual chip stays 28pt; hit area expands to 44pt.
class FavouriteToggleButton extends StatelessWidget {
  final bool isFavourite;
  final VoidCallback onTap;
  final String semanticLabel;
  const FavouriteToggleButton({
    super.key,
    required this.isFavourite,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isFavourite,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kMinTouchTarget,
              minHeight: kMinTouchTarget,
            ),
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isFavourite ? AppColors.favBgActive : AppColors.favBg,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Icon(
                  isFavourite ? Icons.favorite : Icons.favorite_border,
                  size: 14,
                  color: isFavourite
                      ? AppColors.availLow
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline pill-shaped CTA used in route cards, favourites, facility sheet.
/// Visual height 28pt sits centred inside a 44pt hit area. Pass null for
/// either icon slot to render text-only.
class InlineCTAButton extends StatelessWidget {
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final String label;
  final VoidCallback? onTap;
  final String? semanticLabel;
  const InlineCTAButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final fg = isDisabled ? AppColors.textMuted : AppColors.primary;
    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: semanticLabel ?? label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouchTarget),
            child: Center(
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? AppColors.borderLight
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, size: 14, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(color: fg),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 4),
                      Icon(trailingIcon, size: 14, color: fg),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 44pt hit-area wrapper for icon-only controls (back button, clear-X, etc.).
class IconTapTarget extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color color;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool? toggled;
  const IconTapTarget({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
    this.iconSize = 20,
    this.toggled,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      toggled: toggled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kMinTouchTarget / 2),
          child: SizedBox(
            width: kMinTouchTarget,
            height: kMinTouchTarget,
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );
  }
}
