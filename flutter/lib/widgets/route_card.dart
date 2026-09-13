import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/route.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'buttons.dart';

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

const _availabilityWord = <AvailabilityLevel, String>{
  AvailabilityLevel.high: 'Hyvin tilaa',
  AvailabilityLevel.medium: 'Vähän',
  AvailabilityLevel.low: 'Täynnä',
  AvailabilityLevel.unknown: 'Ei tietoa',
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
    final isFav = context.select<AppState, bool>(
      (s) =>
          s.favouriteParkingSpots.any((f) => f.facilityId == route.parking.id),
    );
    final hasAvail = route.parking.available != null;
    final availColor = !hasAvail
        ? AppColors.availNeutral
        : route.parking.availability == AvailabilityLevel.high
            ? AppColors.availHigh
            : route.parking.availability == AvailabilityLevel.medium
                ? AppColors.availMedium
                : AppColors.availLow;
    final availWord = _availabilityWord[route.parking.availability] ?? '';

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

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${route.parking.name}, ${route.totalMinutes} minuuttia, ${availWord.toLowerCase()}'
          '${hasAvail ? ", ${route.parking.available} vapaata paikkaa ${route.parking.capacity}:sta" : ""}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceTinted,
              borderRadius: BorderRadius.circular(AppRadii.lg),
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
                  // Availability column (functional, not decorative)
                  _AvailabilityColumn(
                    available: route.parking.available,
                    capacity: route.parking.capacity,
                    color: availColor,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      route.parking.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyEmphasis.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Shrinks instead of overflowing when a
                                    // wide line badge leaves too little room.
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (driveLeg != null) ...[
                                            const Icon(LucideIcons.car,
                                                size: 12,
                                                color:
                                                    AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                                '${driveLeg.durationMinutes} min',
                                                style: AppTextStyles.captionLight.copyWith(
                                                    color: AppColors
                                                        .textSecondary)),
                                            const SizedBox(width: 10),
                                          ],
                                          if (transitLeg != null) ...[
                                            if (_modeIcons[transitLeg.mode] !=
                                                null)
                                              Icon(
                                                _modeIcons[transitLeg.mode],
                                                size: 12,
                                                color: _modeColors[
                                                    transitLeg.mode],
                                              ),
                                            const SizedBox(width: 4),
                                            Text(
                                                '${transitLeg.durationMinutes} min',
                                                style: AppTextStyles.captionLight.copyWith(
                                                    color: AppColors
                                                        .textSecondary)),
                                            const SizedBox(width: 10),
                                          ],
                                          if (walkMinutes > 0) ...[
                                            const Icon(LucideIcons.footprints,
                                                size: 12,
                                                color: AppColors.walkGray),
                                            const SizedBox(width: 4),
                                            Text('$walkMinutes min',
                                                style: AppTextStyles.captionLight.copyWith(
                                                    color: AppColors
                                                        .textSecondary)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (transitLeg != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 3, horizontal: 7),
                                  decoration: BoxDecoration(
                                    color: _modeColors[transitLeg.mode],
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.xs),
                                  ),
                                  child: Text(
                                    transitLeg.lineName != null
                                        ? '${transitLeg.lineName} ${_modeLabels[transitLeg.mode] ?? ''}'
                                            .trim()
                                        : _modeLabels[transitLeg.mode] ??
                                            transitLeg.mode.name,
                                    style: AppTextStyles.captionStrong.copyWith(
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Text('${route.totalMinutes} min',
                                  style: AppTextStyles.itemPrice.copyWith(
                                    color: AppColors.primary,
                                  )),
                            ],
                          ),
                        ),
                        Container(height: 1, color: AppColors.borderLight),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: InlineCTAButton(
                                  label: actionLabel,
                                  onTap: onAction ?? onTap,
                                  semanticLabel:
                                      '$actionLabel ${route.parking.name}',
                                ),
                              ),
                              FavouriteToggleButton(
                                isFavourite: isFav,
                                semanticLabel: isFav
                                    ? 'Poista ${route.parking.name} suosikeista'
                                    : 'Lisää ${route.parking.name} suosikkeihin',
                                onTap: () {
                                  final s = context.read<AppState>();
                                  if (isFav) {
                                    s.removeFavouriteParkingSpot(
                                        route.parking.id);
                                  } else {
                                    s.addFavouriteParkingSpot(
                                      FavouriteParkingSpot(
                                        id: route.parking.id,
                                        facilityId: route.parking.id,
                                        name: route.parking.name,
                                      ),
                                    );
                                  }
                                },
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
        ),
      ),
    );
  }
}

/// Functional content column on the left of every route card.
/// Carries the availability count + label.
class _AvailabilityColumn extends StatelessWidget {
  final int? available;
  final int capacity;
  final Color color;
  const _AvailabilityColumn({
    required this.available,
    required this.capacity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvail = available != null;
    return Container(
      width: 56,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hasAvail ? available.toString() : capacity.toString(),
            style: AppTextStyles.heroNumber.copyWith(
              color: AppColors.textWhite,
            ),
          ),
          if (hasAvail)
            Text(
              '/$capacity',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textWhite,
              ),
            ),
          Text(
            hasAvail ? 'vapaana' : 'paikkaa',
            style: AppTextStyles.availabilityLabel.copyWith(
              color: AppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}
