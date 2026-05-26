import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _options = [
    (WalkingSpeed.slow, 'Hidas', '3,5 km/h', '🚶'),
    (WalkingSpeed.normal, 'Normaali', '5 km/h', '🚶‍♂️'),
    (WalkingSpeed.fast, 'Nopea', '6,5 km/h', '🏃'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeAreaView(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
              child: Text('Asetukset',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
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
                    children: const [
                      Icon(LucideIcons.footprints,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: AppSpacing.sm),
                      Text('Kävelynopeus',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                    children: const [
                      Icon(LucideIcons.parkingSquare,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: AppSpacing.sm),
                      Text('Pysäköinti',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Näytä myös täydet',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                SizedBox(height: 2),
                                Text(
                                  'Näytä liityntäpysäköinnit joissa ei ole vapaita paikkoja',
                                  style: TextStyle(
                                      fontSize: 13,
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
                    children: const [
                      Icon(LucideIcons.heart,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: AppSpacing.sm),
                      Text('Aloitusnäkymä',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Avaa suosikit oletuksena',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                SizedBox(height: 2),
                                Text(
                                  'Sovellus avautuu suoraan suosikit-välilehteen',
                                  style: TextStyle(
                                      fontSize: 13,
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
                    children: const [
                      Icon(Icons.info_outline,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: AppSpacing.sm),
                      Text('Tietoa liityntäpysäköinnistä',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                    child: const Text(
                      'Tämä sovellus hyödyntää julkisia rajapintoja näyttääkseen '
                      'pääkaupunkiseudun liityntäpysäköintien vapaita paikkoja ja '
                      'reittiehdotuksia. Sovellus ei ole HSL:n tuottama eikä siihen '
                      'liittyvä virallinen palvelu. Pysäköintialueiden hinnat ja '
                      'aikarajoitukset voivat vaihdella kohteittain — varmista '
                      'voimassa olevat ehdot HSL:n omilta sivuilta ennen pysäköintiä.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
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
  final String icon;
  final String label;
  final String desc;
  final VoidCallback onTap;
  const _OptionCard({
    required this.active,
    required this.icon,
    required this.label,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: AppSpacing.sm),
            Text(label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.textPrimary,
                )),
            const SizedBox(height: AppSpacing.sm),
            Text(desc,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class SafeAreaView extends StatelessWidget {
  final Widget child;
  const SafeAreaView({super.key, required this.child});
  @override
  Widget build(BuildContext context) => SafeArea(child: child);
}
