import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _options = [
    (WalkingSpeed.slow, 'Hidas', '3,5 km/h', LucideIcons.footprints, 22.0),
    (WalkingSpeed.normal, 'Normaali', '5 km/h', LucideIcons.footprints, 28.0),
    (WalkingSpeed.fast, 'Nopea', '6,5 km/h', LucideIcons.footprints, 34.0),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
              child: Text('Asetukset',
                  style: AppTextStyles.pageTitle.copyWith(
                    color: AppColors.textPrimary,
                  )),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.footprints,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Kävelynopeus',
                          style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      for (int i = 0; i < _options.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _OptionCard(
                            active: state.walkingSpeed == _options[i].$1,
                            icon: _options[i].$4,
                            iconSize: _options[i].$5,
                            label: _options[i].$2,
                            desc: _options[i].$3,
                            onTap: () =>
                                state.setWalkingSpeed(_options[i].$1),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      const Icon(LucideIcons.parkingSquare,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Pysäköinti',
                          style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  InkWell(
                    onTap: () => state
                        .setShowOnlyAvailable(!state.showOnlyAvailable),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Näytä kaikki paikat',
                                    style: AppTextStyles.itemTitle.copyWith(
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text(
                                  'Näytä liityntäpysäköinnit joissa ei ole vapaita paikkoja tai joista ei ole saatavilla reaaliaikaista tietoa',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: !state.showOnlyAvailable,
                            onChanged: (v) =>
                                state.setShowOnlyAvailable(!v),
                            activeColor: AppColors.bgWhite,
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.border,
                            inactiveThumbColor: AppColors.bgWhite,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      const Icon(LucideIcons.heart,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Aloitusnäkymä',
                          style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  InkWell(
                    onTap: () =>
                        state.setOpenOnFavourites(!state.openOnFavourites),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Avaa suosikit oletuksena',
                                    style: AppTextStyles.itemTitle.copyWith(
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text(
                                  'Sovellus avautuu suoraan suosikit-välilehteen',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: state.openOnFavourites,
                            onChanged: state.setOpenOnFavourites,
                            activeColor: AppColors.bgWhite,
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.border,
                            inactiveThumbColor: AppColors.bgWhite,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Tietoa liityntäpysäköinnistä',
                          style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                    ),
                    child: Text(
                      'Tämä sovellus hyödyntää julkisia rajapintoja näyttääkseen '
                      'pääkaupunkiseudun liityntäpysäköintien vapaita paikkoja ja '
                      'reittiehdotuksia. Sovellus ei ole HSL:n tuottama eikä siihen '
                      'liittyvä virallinen palvelu. Pysäköintialueiden hinnat ja '
                      'aikarajoitukset voivat vaihdella kohteittain. Varmista '
                      'voimassa olevat ehdot HSL:n omilta sivuilta ennen pysäköintiä.',
                      style: AppTextStyles.paragraph.copyWith(
                        color: AppColors.textSecondary,
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


class _OptionCard extends StatelessWidget {
  final bool active;
  final IconData icon;
  final double iconSize;
  final String label;
  final String desc;
  final VoidCallback onTap;
  const _OptionCard({
    required this.active,
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: '$label, $desc',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryLight : AppColors.bgWhite,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: iconSize,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(label,
                  style: AppTextStyles.itemTitle.copyWith(
                    color: active ? AppColors.primary : AppColors.textPrimary,
                  )),
              const SizedBox(height: AppSpacing.xs),
              Text(desc,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

