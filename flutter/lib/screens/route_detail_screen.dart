import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

class RouteDetailScreen extends StatefulWidget {
  const RouteDetailScreen({super.key});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  nav.NavigationState _navState = nav.NavigationState.driveToParking;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _subscribeToLocation();
  }

  Future<void> _subscribeToLocation() async {
    final state = context.read<AppState>();
    final route = state.selectedRoute;
    final dLat = state.destLatitude;
    final dLon = state.destLongitude;
    if (route == null || dLat == null || dLon == null) return;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 50,
      ),
    ).listen((pos) {
      final computed = nav.getNavigationState(
        pos.latitude, pos.longitude,
        route.parking.latitude, route.parking.longitude,
        dLat, dLon,
      );
      if (mounted) setState(() => _navState = computed);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Widget _buildHeader() {
    return Container(
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
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.mapPin,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Reittiä ei ole valittu',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Palaa karttanäkymään ja valitse reitti.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md)),
                        ),
                        child: const Text('Takaisin karttaan'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final route = state.selectedRoute;
    if (route == null) return _buildEmptyState();
    final navState = _navState;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Container(
              color: AppColors.bgWhite,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${state.origin.trim().isEmpty ? 'Lähtöpaikka' : state.origin} → ${state.destination.trim().isEmpty ? 'Määränpää' : state.destination}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${route.totalMinutes} min',
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
                  ...route.legs.asMap().entries.map((e) {
                    final idx = e.key;
                    final leg = e.value;
                    final cfg = _modeConfig[leg.mode]!;
                    final prevCfg = idx > 0
                        ? _modeConfig[route.legs[idx - 1].mode]
                        : null;
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 32,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: AppSpacing.lg,
                                  child: prevCfg != null
                                      ? Container(
                                          width: 3, color: prevCfg.color)
                                      : null,
                                ),
                                leg.mode == TransitMode.park
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
                                Expanded(
                                  child: Container(
                                    width: 3,
                                    color: cfg.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                          ),
                        ],
                      ),
                    );
                  }),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 32,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: AppSpacing.lg,
                                child: route.legs.isNotEmpty
                                    ? Container(
                                        width: 3,
                                        color: _modeConfig[
                                                route.legs.last.mode]!
                                            .color,
                                      )
                                    : null,
                              ),
                              const Icon(LucideIcons.mapPin,
                                  size: 20, color: AppColors.primary),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Määränpää',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textMuted)),
                                Text(
                                  state.destination.trim().isEmpty
                                      ? 'Määränpää'
                                      : state.destination,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
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
                        ? 'Aja ${route.parking.name} -parkkiin'
                        : 'Olet pysäköintipaikalla',
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
                        final p = route.parking;
                        final dLat = state.destLatitude;
                        final dLon = state.destLongitude;
                        if (navState ==
                                nav.NavigationState.navigateToDestination &&
                            dLat != null && dLon != null) {
                          nav.navigateTransit(
                              p.latitude, p.longitude, dLat, dLon);
                        } else {
                          nav.navigateTo(p.latitude, p.longitude,
                              label: p.name);
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
                                : 'Navigoi määränpäähän',
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
