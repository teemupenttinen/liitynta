import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'buttons.dart';

/// Manual refresh for parking availability. The 2-minute poll in [AppState]
/// continues as before. This button only adds an extra load on demand.
class ParkingRefreshButton extends StatelessWidget {
  const ParkingRefreshButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.facilitiesLoading) {
      return Semantics(
        label: 'Päivitetään pysäköintitietoja',
        child: const SizedBox(
          width: kMinTouchTarget,
          height: kMinTouchTarget,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        ),
      );
    }
    return IconTapTarget(
      icon: LucideIcons.refreshCw,
      iconSize: 18,
      color: AppColors.primary,
      semanticLabel: 'Päivitä pysäköintitiedot',
      onTap: state.loadFacilities,
    );
  }
}
