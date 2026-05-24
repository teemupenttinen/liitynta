import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/route.dart';
import '../services/navigation.dart' as nav;
import '../state/app_state.dart';
import '../theme.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  Color _availColor(AvailabilityLevel? a) {
    if (a == AvailabilityLevel.high) return AppColors.availHigh;
    if (a == AvailabilityLevel.medium) return AppColors.availMedium;
    return AppColors.availLow;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final facilityMap = {for (final f in state.facilities) f.id.toString(): f};

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
              child: Text('Suosikit',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
            ),
            // Commute pairs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(LucideIcons.navigation,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: AppSpacing.sm),
                      Text('Reitit',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.commutePairs.isEmpty)
                    _EmptyCard(
                      icon: LucideIcons.heart,
                      text: 'Tallenna reittihaku suosikiksi nähdäksesi reittisi täällä',
                    )
                  else
                    ...state.commutePairs.map((p) => Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.bgWhite,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(p.origin,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  AppColors.textPrimary)),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('→',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: AppColors.textMuted)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(p.destination,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  AppColors.textPrimary)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.chevronRight,
                                  size: 20, color: AppColors.textMuted),
                            ],
                          ),
                        )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // Favourite parking spots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(LucideIcons.mapPin,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: AppSpacing.sm),
                      Text('Liityntäpysäköinnit',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.favouriteParkingSpots.isEmpty)
                    _EmptyCard(
                      icon: LucideIcons.mapPin,
                      text:
                          'Tallenna liityntäpysäköinti suosikiksi seurataksesi vapaita paikkoja',
                    )
                  else
                    ...state.favouriteParkingSpots.map((spot) {
                      final facility = facilityMap[spot.facilityId];
                      final availLvl = facility?.availability ??
                          AvailabilityLevel.low;
                      final color = _availColor(availLvl);
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.primary, width: 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                color: color,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 4),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      facility?.available?.toString() ?? '–',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textWhite,
                                      ),
                                    ),
                                    if (facility?.available != null)
                                      Text(
                                        '/${facility!.capacity}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                    Text(
                                      facility?.available != null
                                          ? 'vapaana'
                                          : 'paikkaa',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                        color: Colors.white
                                            .withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      child: Text(spot.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          )),
                                    ),
                                    Container(
                                        height: 1,
                                        color: AppColors.borderLight),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: facility == null
                                                  ? null
                                                  : () => nav.navigateTo(
                                                        facility.latitude,
                                                        facility.longitude,
                                                        label: spot.name,
                                                      ),
                                              child: Container(
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryLight,
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  Icon(LucideIcons.navigation,
                                                      size: 13,
                                                      color:
                                                          AppColors.primary),
                                                  SizedBox(width: 5),
                                                  Text('Navigoi parkkiin',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .primary,
                                                      )),
                                                  SizedBox(width: 5),
                                                  Icon(
                                                      LucideIcons
                                                          .chevronRight,
                                                      size: 13,
                                                      color:
                                                          AppColors.primary),
                                                ],
                                              ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => state
                                                .removeFavouriteParkingSpot(
                                                    spot.id),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.favBgActive,
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                              ),
                                              child: const Icon(
                                                Icons.favorite,
                                                size: 14,
                                                color: AppColors.availLow,
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
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyCard({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 20 / 14,
              )),
        ],
      ),
    );
  }
}
