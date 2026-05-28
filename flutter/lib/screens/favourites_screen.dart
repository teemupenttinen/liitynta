import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/route.dart';
import '../services/navigation.dart' as nav;
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/time_format.dart';
import '../widgets/buttons.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  Color _availColor(AvailabilityLevel? a) {
    if (a == AvailabilityLevel.high) return AppColors.availHigh;
    if (a == AvailabilityLevel.medium) return AppColors.availMedium;
    if (a == AvailabilityLevel.unknown) return AppColors.availNeutral;
    return AppColors.availLow;
  }

  void _removePair(BuildContext context, CommutePair p) {
    final state = context.read<AppState>();
    state.removeCommutePair(p.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Poistettu: ${p.origin} → ${p.destination}'),
        action: SnackBarAction(
          label: 'Kumoa',
          onPressed: () => state.addCommutePair(p),
        ),
      ));
  }

  void _removeSpot(BuildContext context, FavouriteParkingSpot spot) {
    final state = context.read<AppState>();
    state.removeFavouriteParkingSpot(spot.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Poistettu: ${spot.name}'),
        action: SnackBarAction(
          label: 'Kumoa',
          onPressed: () => state.addFavouriteParkingSpot(spot),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final facilityMap = {for (final f in state.facilities) f.id: f};

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
              child: Text('Suosikit',
                  style: AppTextStyles.pageTitle.copyWith(
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
                    children: [
                      const Icon(LucideIcons.navigation,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Reitit',
                          style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.commutePairs.isEmpty)
                    const _EmptyCard(
                      icon: LucideIcons.heart,
                      text:
                          'Tallenna reittihaku suosikiksi nähdäksesi reittisi täällä',
                    )
                  else
                    ...state.commutePairs.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Dismissible(
                          key: ValueKey('pair-${p.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: AppColors.availLow,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.md),
                            ),
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.only(right: AppSpacing.lg),
                            child: const Icon(LucideIcons.trash2,
                                color: AppColors.textWhite, size: 22),
                          ),
                          onDismissed: (_) => _removePair(context, p),
                          child: Semantics(
                            button: true,
                            label:
                                'Hae reitti: ${p.origin} kohteeseen ${p.destination}',
                            child: Material(
                              color: AppColors.bgWhite,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.md),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () =>
                                    state.requestSearchFromFavourite(p),
                                child: Container(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.lg),
                                  decoration: const BoxDecoration(
                                    boxShadow: AppShadows.card,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(p.origin,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextStyles.itemBody
                                                      .copyWith(
                                                          color: AppColors
                                                              .textPrimary)),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(LucideIcons.arrowRight,
                                                size: 16,
                                                color:
                                                    AppColors.textSecondary),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(p.destination,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextStyles.itemBody
                                                      .copyWith(
                                                          color: AppColors
                                                              .textPrimary)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(LucideIcons.chevronRight,
                                          size: 20,
                                          color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  if (state.commutePairs.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Pyyhkäise vasemmalle poistaaksesi',
                      style: AppTextStyles.labelLight.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
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
                    children: [
                      const Icon(LucideIcons.mapPin,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Liityntäpysäköinnit',
                          style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.textPrimary)),
                      const Spacer(),
                      if (state.favouriteParkingSpots.isNotEmpty)
                        Text(
                          formatUpdatedAgo(state.facilitiesUpdatedAt),
                          style: AppTextStyles.labelLight.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.favouriteParkingSpots.isEmpty)
                    const _EmptyCard(
                      icon: LucideIcons.mapPin,
                      text:
                          'Tallenna liityntäpysäköinti suosikiksi seurataksesi vapaita paikkoja',
                    )
                  else
                    ...state.favouriteParkingSpots.map((spot) {
                      final facility = facilityMap[spot.facilityId];
                      final availLvl =
                          facility?.availability ?? AvailabilityLevel.unknown;
                      final color = _availColor(availLvl);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceTinted,
                            borderRadius:
                                BorderRadius.circular(AppRadii.lg),
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
                                        facility?.available?.toString() ??
                                            '–',
                                        style: AppTextStyles.heroNumber.copyWith(
                                          color: AppColors.textWhite,
                                        ),
                                      ),
                                      if (facility?.available != null)
                                        Text(
                                          '/${facility!.capacity}',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textWhite,
                                          ),
                                        ),
                                      Text(
                                        facility?.available != null
                                            ? 'vapaana'
                                            : 'paikkaa',
                                        style: AppTextStyles.availabilityLabel
                                            .copyWith(
                                          color: AppColors.textWhite,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            12, 10, 12, 6),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(spot.name,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: AppTextStyles.bodyEmphasis
                                                  .copyWith(
                                                color:
                                                    AppColors.textPrimary,
                                              )),
                                        ),
                                      ),
                                      Container(
                                          height: 1,
                                          color: AppColors.borderLight),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: InlineCTAButton(
                                                label: 'Navigoi parkkiin',
                                                semanticLabel:
                                                    'Navigoi parkkiin ${spot.name}',
                                                onTap: facility == null
                                                    ? null
                                                    : () => nav.navigateTo(
                                                          facility.latitude,
                                                          facility.longitude,
                                                          label: spot.name,
                                                        ),
                                              ),
                                            ),
                                            FavouriteToggleButton(
                                              isFavourite: true,
                                              semanticLabel:
                                                  'Poista ${spot.name} suosikeista',
                                              onTap: () =>
                                                  _removeSpot(context, spot),
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
          Icon(icon, size: 24, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.textSecondary,
                height: 20 / 14,
              )),
        ],
      ),
    );
  }
}
