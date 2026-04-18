import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/route.dart';
import '../services/navigation.dart' as nav;
import '../state/app_state.dart';
import '../theme.dart';

class _ModeConfig {
  final Color color;
  final Color bgColor;
  final String label;
  final IconData icon;
  const _ModeConfig(this.color, this.bgColor, this.label, this.icon);
}

const _modeConfig = <TransitMode, _ModeConfig>{
  TransitMode.drive: _ModeConfig(
      AppColors.driveBlue, Color(0xFFE8F0FE), 'Ajomatka', LucideIcons.car),
  TransitMode.park: _ModeConfig(AppColors.primary, AppColors.primaryLight,
      'Pysäköinti', LucideIcons.mapPin),
  TransitMode.metro: _ModeConfig(AppColors.metroOrange, Color(0xFFFFF3E0),
      'Metro', LucideIcons.train),
  TransitMode.bus: _ModeConfig(AppColors.busBlue, Color(0xFFE3F2FD), 'Bussi',
      LucideIcons.bus),
  TransitMode.tram: _ModeConfig(AppColors.tramGreen, Color(0xFFE8F5E9),
      'Ratikka', LucideIcons.train),
  TransitMode.rail: _ModeConfig(AppColors.railPurple, Color(0xFFF3E5F5), 'Juna',
      LucideIcons.train),
  TransitMode.ferry: _ModeConfig(AppColors.ferryCyan, Color(0xFFE0F7FA),
      'Lautta', LucideIcons.ship),
  TransitMode.walk: _ModeConfig(AppColors.walkGray, Color(0xFFF0F0F0),
      'Kävely', LucideIcons.footprints),
};

class RouteDetailScreen extends StatelessWidget {
  const RouteDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final route = state.selectedRoute;
    const navState = nav.NavigationState.driveToParking;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(LucideIcons.arrowLeft,
                        size: 24, color: AppColors.textWhite),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Text('Reitin tiedot',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite)),
                ],
              ),
            ),
            Container(
              color: AppColors.bgWhite,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${route?.legs.isNotEmpty == true ? route!.legs[0].from : 'Espoo'} → ${route?.parking.name ?? 'P+R'}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text('Espoo → Helsinki keskusta',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${route?.totalMinutes ?? 38} min',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const Text('kokonaisaika',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Text('Reitin vaiheet',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
                  ...(route?.legs ?? []).asMap().entries.map((e) {
                    final idx = e.key;
                    final leg = e.value;
                    final cfg = _modeConfig[leg.mode]!;
                    final isLast = idx == (route?.legs.length ?? 0) - 1;
                    final active = navState ==
                            nav.NavigationState.driveToParking &&
                        leg.mode == TransitMode.drive;
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: active ? AppSpacing.sm : 0,
                        vertical: AppSpacing.lg,
                      ),
                      decoration: active
                          ? BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.md),
                            )
                          : null,
                      child: IntrinsicHeight(
                        child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 32,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: leg.mode == TransitMode.park
                                      ? Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: AppColors.bgWhite,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: AppColors.primary,
                                                width: 3),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Text('P',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary)),
                                        )
                                      : Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                              color: cfg.color,
                                              shape: BoxShape.circle),
                                        ),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        width: 3,
                                        margin: const EdgeInsets.only(top: 4),
                                        color: cfg.color,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (leg.mode == TransitMode.park) ...[
                                  Text('Pysäköinti – ${leg.parking?.name}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                            color: AppColors.availHigh,
                                            shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                          'Vapaana ${leg.parking?.available}/${leg.parking?.capacity}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.availHigh)),
                                    ],
                                  ),
                                ] else ...[
                                  if (leg.lineDescription != null)
                                    Text(
                                        '${leg.lineName} – ${leg.lineDescription}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                AppColors.textSecondary)),
                                  Text(leg.from,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary)),
                                  Text('→ ${leg.to}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('${leg.durationMinutes} min',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: cfg.color)),
                                      const SizedBox(width: AppSpacing.lg),
                                      Text('${leg.distanceKm} km',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color:
                                                  AppColors.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: cfg.bgColor,
                                      borderRadius:
                                          BorderRadius.circular(13),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(cfg.icon,
                                            size: 14, color: cfg.color),
                                        const SizedBox(width: 5),
                                        Text(cfg.label,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: cfg.color)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(
                          width: 32,
                          child: Icon(LucideIcons.mapPin,
                              size: 20, color: AppColors.primary),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Määränpää',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted)),
                              Text('Helsinki keskusta',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.bgWhite,
              padding: const EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom: AppSpacing.xxxl,
              ),
              child: Column(
                children: [
                  Text(
                    navState == nav.NavigationState.driveToParking
                        ? 'Aja ${route?.parking.name ?? 'Itäkeskus P+R'} -parkkiin'
                        : 'Olet lähellä kohdetta',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadii.md)),
                      ),
                      onPressed: () {
                        final p = route?.parking;
                        if (p != null) {
                          nav.navigateTo(p.latitude, p.longitude,
                              label: p.name);
                        } else {
                          nav.navigateTo(60.2095, 25.0828,
                              label: 'Itäkeskus P+R');
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.navigation,
                              size: 20, color: AppColors.textWhite),
                          const SizedBox(width: 10),
                          Text(
                            navState == nav.NavigationState.driveToParking
                                ? 'Aja parkkiin'
                                : 'Navigoi kohteeseen',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textWhite),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
