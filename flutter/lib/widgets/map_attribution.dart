import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

// The OSM and OpenMapTiles terms require a credit that is visible on the map
// without any user action, so this text stays on screen at all times.
const _credit = '© Digitransit © OpenMapTiles © OpenStreetMap';

const _sources = [
  (
    title: '© OpenStreetMap-tekijät',
    detail: 'Karttatiedot, ODbL-lisenssi',
    url: 'https://www.openstreetmap.org/copyright',
  ),
  (
    title: '© OpenMapTiles',
    detail: 'Karttatiilien tietomalli',
    url: 'https://openmaptiles.org/',
  ),
  (
    title: '© Digitransit',
    detail: 'Taustakartta, reitit ja osoitehaku, CC BY 4.0',
    url: 'https://digitransit.fi/en/developers/apis/7-terms-of-use/',
  ),
  (
    title: 'HSL',
    detail: 'Karttatyyli, CC BY 4.0',
    url: 'https://github.com/HSLdevcom/hsl-map-style',
  ),
  (
    title: '© Fintraffic',
    detail: 'Pysäköintipaikat ja vapaat paikat, CC BY 4.0',
    url: 'https://parking.fintraffic.fi/docs/index.html',
  ),
];

/// Map credit for the bottom right corner of the visible map. Tapping it
/// lists the data sources with links to their licences.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$_credit. Näytä tietolähteet',
      excludeSemantics: true,
      child: GestureDetector(
        // Translucent: the padding makes the tap target bigger, but a drag
        // that starts in it still pans the map underneath.
        behavior: HitTestBehavior.translucent,
        onTap: () => _showSources(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.bgWhite.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Text(
              _credit,
              style: AppTextStyles.captionLight
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showSources(BuildContext context) {
  return showModalBottomSheet<void>(
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
              'Tietolähteet',
              style: AppTextStyles.sectionTitle
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
          for (final s in _sources)
            _SourceRow(title: s.title, detail: s.detail, url: s.url),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}

class _SourceRow extends StatelessWidget {
  final String title;
  final String detail;
  final String url;
  const _SourceRow({
    required this.title,
    required this.detail,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: '$title, $detail',
      excludeSemantics: true,
      child: InkWell(
        onTap: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.itemTitle
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(LucideIcons.externalLink,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
