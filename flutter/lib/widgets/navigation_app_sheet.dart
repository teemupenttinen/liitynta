import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/navigation.dart' as nav;
import '../theme.dart';

const _appLabels = {
  nav.NavigationApp.apple: ('Kartat', LucideIcons.map),
  nav.NavigationApp.google: ('Google Maps', LucideIcons.navigation),
};

/// Hand off driving directions, asking which maps app to use first.
Future<void> startDriveNavigation(
  BuildContext context, {
  required double lat,
  required double lon,
  String? label,
}) async {
  final app = await _resolveApp(context);
  if (app == null) return;
  await nav.navigateTo(lat, lon, label: label, app: app);
}

/// Hand off transit directions, asking which maps app to use first.
Future<void> startTransitNavigation(
  BuildContext context, {
  required double fromLat,
  required double fromLon,
  required double toLat,
  required double toLon,
}) async {
  final app = await _resolveApp(context);
  if (app == null) return;
  await nav.navigateTransit(fromLat, fromLon, toLat, toLon, app: app);
}

/// Prompts only when there is a real choice to make — with one maps app
/// installed (or on Android) we go straight to it rather than showing a
/// one-option sheet. Returns null when the user dismisses the prompt.
Future<nav.NavigationApp?> _resolveApp(BuildContext context) async {
  final installed = await nav.installedNavigationApps();
  if (installed.length == 1) return installed.first;
  // Nothing detected: let the launch fallback chain resolve it.
  if (installed.isEmpty) return nav.NavigationApp.apple;
  if (!context.mounted) return null;
  return showModalBottomSheet<nav.NavigationApp>(
    context: context,
    backgroundColor: AppColors.bgWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl,
                AppSpacing.xl, AppSpacing.md),
            child: Text(
              'Avaa navigointi',
              style: AppTextStyles.sectionTitle
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
          for (final app in installed)
            _NavAppRow(
              icon: _appLabels[app]!.$2,
              label: _appLabels[app]!.$1,
              onTap: () => Navigator.pop(sheetContext, app),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}

class _NavAppRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavAppRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.itemTitle
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
              const Icon(LucideIcons.chevronRight,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
