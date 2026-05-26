import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/route.dart';
import '../state/app_state.dart';
import '../theme.dart';

const _modeColors = <TransitMode, Color>{
  TransitMode.drive: AppColors.driveBlue,
  TransitMode.park: AppColors.primary,
  TransitMode.metro: AppColors.metroOrange,
  TransitMode.bus: AppColors.busBlue,
  TransitMode.tram: AppColors.tramGreen,
  TransitMode.rail: AppColors.railPurple,
  TransitMode.ferry: AppColors.ferryCyan,
  TransitMode.walk: AppColors.walkGray,
};

const _modeIcons = <TransitMode, IconData>{
  TransitMode.drive: LucideIcons.car,
  TransitMode.metro: LucideIcons.train,
  TransitMode.bus: LucideIcons.bus,
  TransitMode.tram: LucideIcons.train,
  TransitMode.rail: LucideIcons.train,
  TransitMode.ferry: LucideIcons.ship,
  TransitMode.walk: LucideIcons.footprints,
};

const _modeLabels = <TransitMode, String>{
  TransitMode.metro: 'M Metro',
  TransitMode.bus: 'Bussi',
  TransitMode.tram: 'Ratikka',
  TransitMode.rail: 'Juna',
  TransitMode.ferry: 'Lautta',
};

class RouteCard extends StatelessWidget {
  final AppRoute route;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAction;
  final String actionLabel;
  final bool isSelected;

  const RouteCard({
    super.key,
    required this.route,
    required this.onTap,
    this.onLongPress,
    this.onAction,
    this.actionLabel = 'Näytä reitti',
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isFav = state.favouriteParkingSpots
        .any((s) => s.facilityId == route.parking.id);
    final hasAvail = route.parking.available != null;
    final availColor = !hasAvail
        ? AppColors.availNeutral
        : route.parking.availability == AvailabilityLevel.high
            ? AppColors.availHigh
            : route.parking.availability == AvailabilityLevel.medium
                ? AppColors.availMedium
                : AppColors.availLow;

    final driveLeg = route.legs.cast<RouteLeg?>().firstWhere(
          (l) => l?.mode == TransitMode.drive,
          orElse: () => null,
        );
    final transitLeg = route.legs.cast<RouteLeg?>().firstWhere(
          (l) =>
              l?.mode != TransitMode.drive &&
              l?.mode != TransitMode.park &&
              l?.mode != TransitMode.walk,
          orElse: () => null,
        );
    final walkMinutes = route.legs
        .where((l) => l.mode == TransitMode.walk)
        .fold<int>(0, (sum, l) => sum + l.durationMinutes);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Availability sidebar
              Container(
                width: 56,
                color: availColor,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hasAvail
                          ? route.parking.available.toString()
                          : route.parking.capacity.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textWhite,
                      ),
                    ),
                    if (hasAvail)
                      Text(
                        '/${route.parking.capacity}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    Text(
                      hasAvail ? 'vapaana' : 'paikkaa',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Right content
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  route.parking.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (driveLeg != null) ...[
                                      const Icon(LucideIcons.car,
                                          size: 11,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text('${driveLeg.durationMinutes} min',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color:
                                                  AppColors.textSecondary)),
                                      const SizedBox(width: 8),
                                    ],
                                    if (transitLeg != null) ...[
                                      if (_modeIcons[transitLeg.mode] != null)
                                        Icon(
                                          _modeIcons[transitLeg.mode],
                                          size: 11,
                                          color: _modeColors[transitLeg.mode],
                                        ),
                                      const SizedBox(width: 4),
                                      Text('${transitLeg.durationMinutes} min',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color:
                                                  AppColors.textSecondary)),
                                      const SizedBox(width: 8),
                                    ],
                                    if (walkMinutes > 0) ...[
                                      const Icon(LucideIcons.footprints,
                                          size: 11,
                                          color: AppColors.walkGray),
                                      const SizedBox(width: 4),
                                      Text('$walkMinutes min',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color:
                                                  AppColors.textSecondary)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (transitLeg != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 6),
                              decoration: BoxDecoration(
                                color: _modeColors[transitLeg.mode],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                transitLeg.lineName != null
                                    ? '${transitLeg.lineName} ${_modeLabels[transitLeg.mode] ?? ''}'
                                        .trim()
                                    : _modeLabels[transitLeg.mode] ??
                                        transitLeg.mode.name,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textWhite,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text('${route.totalMinutes} min',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              )),
                        ],
                      ),
                    ),
                    Container(height: 1, color: AppColors.borderLight),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: onAction ?? onTap,
                              child: Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.mapPin,
                                        size: 13, color: AppColors.primary),
                                    const SizedBox(width: 5),
                                    Text(actionLabel,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        )),
                                    const SizedBox(width: 5),
                                    const Icon(LucideIcons.chevronRight,
                                        size: 13, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if (isFav) {
                                state.removeFavouriteParkingSpot(
                                    route.parking.id);
                              } else {
                                state.addFavouriteParkingSpot(
                                  FavouriteParkingSpot(
                                    id: route.parking.id,
                                    facilityId: route.parking.id,
                                    name: route.parking.name,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isFav
                                    ? AppColors.favBgActive
                                    : AppColors.favBg,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Icon(
                                isFav ? Icons.favorite : LucideIcons.heart,
                                size: 14,
                                color: isFav
                                    ? AppColors.availLow
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
