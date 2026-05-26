import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/route.dart';
import '../services/digitransit.dart';
import '../services/navigation.dart' as nav;
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/time_format.dart';
import '../widgets/autocomplete_input.dart';
import '../widgets/route_card.dart';

const _initialCenter = LatLng(60.21, 25.0);
const double _initialZoom = 10.5;

const Map<TransitMode, Color> _modeLineColors = {
  TransitMode.drive: Color(0xFF0047B3),
  TransitMode.park: Color(0xFF0047B3),
  TransitMode.metro: Color(0xFFFF6319),
  TransitMode.bus: Color(0xFF0078D4),
  TransitMode.tram: Color(0xFF00A651),
  TransitMode.rail: Color(0xFF8B5CF6),
  TransitMode.ferry: Color(0xFF06B6D4),
  TransitMode.walk: Color(0xFF9CA3AF),
};

Color _availColor(AvailabilityLevel a) {
  switch (a) {
    case AvailabilityLevel.high: return AppColors.availHigh;
    case AvailabilityLevel.medium: return AppColors.availMedium;
    case AvailabilityLevel.low: return AppColors.availLow;
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  ({double lat, double lon})? originCoords;
  ({double lat, double lon})? destCoords;
  ({double lat, double lon})? userLocation;
  String? error;
  bool hasSearched = false;
  String? selectedRouteId;
  String? promotedRouteId;
  ParkingFacility? selectedFacility;
  String _lastSearchKey = '';

  // Sheet animation: 0.0 = collapsed, 1.0 = expanded
  late final AnimationController _sheetCtrl;
  bool _isExpanded = false;
  double _dragStartValue = 0;
  final ScrollController _cardsScrollCtrl = ScrollController();

  late AppState _appState;
  int _lastSeenSearchNonce = 0;

  static const double _collapsedHeight = 185;

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 0,
    );
    _appState = context.read<AppState>();
    _lastSeenSearchNonce = _appState.searchRequestNonce;
    _appState.addListener(_handleAppStateChange);
  }

  void _handleAppStateChange() {
    if (_appState.searchRequestNonce != _lastSeenSearchNonce) {
      _lastSeenSearchNonce = _appState.searchRequestNonce;
      setState(() {
        originCoords = null;
        destCoords = null;
        _lastSearchKey = '';
      });
      _handleSearch();
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_handleAppStateChange);
    _sheetCtrl.dispose();
    _cardsScrollCtrl.dispose();
    super.dispose();
  }

  void _snapExpanded() {
    _sheetCtrl.animateTo(1, curve: Curves.easeOutCubic);
    setState(() => _isExpanded = true);
  }

  void _snapCollapsed() {
    _sheetCtrl.animateTo(0, curve: Curves.easeOutCubic);
    setState(() {
      _isExpanded = false;
      if (selectedRouteId != null) {
        promotedRouteId = selectedRouteId;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_cardsScrollCtrl.hasClients) {
        _cardsScrollCtrl.jumpTo(0);
      }
    });
  }

  void _showLocationDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sijaintilupa estetty'),
        content: const Text(
            'Sijaintia tarvitaan reitin suunnitteluun. Salli sijainnin käyttö asetuksista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Peruuta'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text('Avaa asetukset'),
          ),
        ],
      ),
    );
  }

  List<AppRoute> get visibleRoutes {
    final state = context.read<AppState>();
    final base = state.showOnlyAvailable
        ? state.routes.where((r) => (r.parking.available ?? 0) > 0).toList()
        : List<AppRoute>.from(state.routes);
    if (promotedRouteId == null) return base;
    final idx = base.indexWhere((r) => r.id == promotedRouteId);
    if (idx <= 0) return base;
    final promoted = base.removeAt(idx);
    base.insert(0, promoted);
    return base;
  }

  AppRoute? get selectedRoute {
    final vr = visibleRoutes;
    if (vr.isEmpty) return null;
    if (selectedRouteId == null) return vr.first;
    return vr.firstWhere((r) => r.id == selectedRouteId,
        orElse: () => vr.first);
  }

  Future<void> _handleRequestLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) _showLocationDeniedDialog();
      return;
    }
    if (perm == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sijaintilupa hylätty. Voit sallia sen myöhemmin.')));
      }
      return;
    }
    final loc = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
    final coords = (lat: loc.latitude, lon: loc.longitude);
    setState(() {
      originCoords = coords;
      userLocation = coords;
    });

    try {
      final placemarks = await gc.placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final streetBase = (p.thoroughfare ?? p.street ?? '')
            .replaceAll(RegExp(r'\s+\d+\S*$'), '')
            .trim();
        final number = p.subThoroughfare?.trim() ?? '';
        final streetWithNumber =
            [streetBase, number].where((s) => s.isNotEmpty).join(' ');
        final label = [streetWithNumber, p.locality ?? '']
            .where((s) => s.isNotEmpty)
            .join(', ');
        context
            .read<AppState>()
            .setOrigin(label.isEmpty ? 'Oma sijainti' : label);
      } else {
        context.read<AppState>().setOrigin('Oma sijainti');
      }
    } catch (_) {
      context.read<AppState>().setOrigin('Oma sijainti');
    }
    _maybeAutoSearch();
  }

  void _clearSearchResults() {
    final state = context.read<AppState>();
    state.setRoutes([]);
    setState(() {
      hasSearched = false;
      selectedRouteId = null;
      promotedRouteId = null;
      error = null;
      selectedFacility = null;
      _lastSearchKey = '';
    });
    _mapController.move(_initialCenter, _initialZoom);
  }

  Future<void> _handleSearch() async {
    FocusScope.of(context).unfocus();
    final state = context.read<AppState>();
    double? oLat = originCoords?.lat;
    double? oLon = originCoords?.lon;
    double? dLat = destCoords?.lat;
    double? dLon = destCoords?.lon;

    if (oLat == null || dLat == null) {
      if (state.origin.trim().isEmpty || state.destination.trim().isEmpty) {
        return;
      }
      setState(() => error = null);
      state.setIsSearching(true);
      state.setRoutes([]);

      try {
        final results = await Future.wait([
          oLat == null ? geocode(state.origin) : Future.value(<GeocodeSuggestion>[]),
          dLat == null ? geocode(state.destination) : Future.value(<GeocodeSuggestion>[]),
        ]);
        if (oLat == null && results[0].isNotEmpty) {
          oLat = results[0][0].lat;
          oLon = results[0][0].lon;
          setState(() => originCoords = (lat: oLat!, lon: oLon!));
        }
        if (dLat == null && results[1].isNotEmpty) {
          dLat = results[1][0].lat;
          dLon = results[1][0].lon;
          setState(() => destCoords = (lat: dLat!, lon: dLon!));
          state.setDestCoords(dLat, dLon);
        }
        if (oLat == null || dLat == null) {
          setState(() => error = 'Osoitetta ei löytynyt. Tarkista hakusanat.');
          state.setIsSearching(false);
          return;
        }
      } catch (_) {
        setState(() => error = 'Osoitteen haku epäonnistui.');
        state.setIsSearching(false);
        return;
      }
    } else {
      setState(() => error = null);
      state.setIsSearching(true);
      state.setRoutes([]);
      state.setDestCoords(dLat, dLon);
    }

    setState(() => selectedFacility = null);

    try {
      final found = await searchRoutes(
        oLat!, oLon!, dLat!, dLon!,
        walkingSpeed: state.walkingSpeed.key,
        originLabel: state.origin.trim().isEmpty
            ? 'Lähtöpaikka'
            : state.origin.trim(),
        destinationLabel: state.destination.trim().isEmpty
            ? 'Määränpää'
            : state.destination.trim(),
      );
      state.setRoutes(found);
      setState(() {
        hasSearched = true;
        selectedRouteId = found.isNotEmpty ? found.first.id : null;
        promotedRouteId = null;
      });
      if (found.isNotEmpty) {
        final points = <LatLng>[
          LatLng(oLat!, oLon!),
          LatLng(dLat!, dLon!),
          ...found.map((r) =>
              LatLng(r.parking.latitude, r.parking.longitude)),
        ];
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.fromLTRB(40, 160, 40, 300),
          ),
        );
      } else {
        setState(() => error = 'Reittejä ei löytynyt. Kokeile eri osoitteita.');
      }
    } catch (_) {
      setState(() => error = 'Reittihaku epäonnistui. Yritä uudelleen.');
    } finally {
      state.setIsSearching(false);
    }
  }

  void _maybeAutoSearch() {
    if (originCoords != null && destCoords != null) {
      final key =
          '${originCoords!.lat},${originCoords!.lon}-${destCoords!.lat},${destCoords!.lon}';
      if (_lastSearchKey == key) return;
      _lastSearchKey = key;
      _handleSearch();
    }
  }

  void _toggleFavourite() {
    final state = context.read<AppState>();
    if (state.origin.trim().isEmpty || state.destination.trim().isEmpty) return;
    final exists = state.commutePairs.any(
      (p) => p.origin == state.origin && p.destination == state.destination,
    );
    if (!exists) {
      state.addCommutePair(CommutePair(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        origin: state.origin.trim(),
        destination: state.destination.trim(),
        createdAt: DateTime.now(),
      ));
    }
  }

  List<Marker> _buildMarkers(AppState state) {
    final markers = <Marker>[];
    if (hasSearched && originCoords != null) {
      markers.add(Marker(
        point: LatLng(originCoords!.lat, originCoords!.lon),
        width: 28,
        height: 28,
        child: _endpointDot(AppColors.primary),
      ));
    }
    if (hasSearched && destCoords != null) {
      markers.add(Marker(
        point: LatLng(destCoords!.lat, destCoords!.lon),
        width: 28,
        height: 28,
        child: _endpointDot(AppColors.availLow),
      ));
    }
    if (!hasSearched) {
      for (final f in state.facilities.where((f) => (f.available ?? 0) > 0)) {
        final isSel = selectedFacility?.id == f.id;
        markers.add(Marker(
          point: LatLng(f.latitude, f.longitude),
          width: 60,
          height: 72,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => setState(() => selectedFacility = f),
            child: _ParkingPin(
              count: f.available ?? f.capacity,
              availColor: _availColor(f.availability),
              selected: isSel,
            ),
          ),
        ));
      }
    } else {
      final vr = visibleRoutes;
      final sel = selectedRoute;
      final ordered = [
        ...vr.where((r) => r.id != sel?.id),
        ...vr.where((r) => r.id == sel?.id),
      ];
      for (final r in ordered) {
        final isSel = r.id == sel?.id;
        markers.add(Marker(
          key: ValueKey('pin-${r.id}-${isSel ? 'sel' : 'un'}'),
          point: LatLng(r.parking.latitude, r.parking.longitude),
          width: 60,
          height: 72,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                selectedRouteId = r.id;
                promotedRouteId = r.id;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_cardsScrollCtrl.hasClients) {
                  _cardsScrollCtrl.jumpTo(0);
                }
              });
            },
            child: _ParkingPin(
              count: r.parking.available ?? r.parking.capacity,
              availColor: _availColor(r.parking.availability),
              selected: isSel,
              faded: !isSel,
            ),
          ),
        ));
      }
    }
    return markers;
  }

  Widget _endpointDot(Color color) {
    return Center(
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.bgWhite, width: 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1F000000), offset: Offset(0, 2), blurRadius: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSheet(
    AppState state,
    List<AppRoute> vr,
    AppRoute? sel,
    bool hasResults,
    int otherCount,
    bool isFav,
  ) {
    final screenH = MediaQuery.of(context).size.height;
    // Expanded sheet leaves room for the search area + status bar
    final expandedHeight = screenH - 300;
    final travel = expandedHeight - _collapsedHeight;

    return AnimatedBuilder(
      animation: _sheetCtrl,
      builder: (context, _) {
        final translateY = (1 - _sheetCtrl.value) * travel;
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: expandedHeight,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.bgWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadii.xl),
                  topRight: Radius.circular(AppRadii.xl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    offset: Offset(0, -3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (_) {
                      _dragStartValue = _sheetCtrl.value;
                      _sheetCtrl.stop();
                    },
                    onVerticalDragUpdate: (d) {
                      final delta = -(d.primaryDelta ?? 0) / travel;
                      _sheetCtrl.value =
                          (_sheetCtrl.value + delta).clamp(0.0, 1.0);
                    },
                    onVerticalDragEnd: (d) {
                      final velocity = d.primaryVelocity ?? 0;
                      if (velocity < -500) {
                        _snapExpanded();
                      } else if (velocity > 500) {
                        _snapCollapsed();
                      } else if (_sheetCtrl.value > 0.5) {
                        _snapExpanded();
                      } else {
                        _snapCollapsed();
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 24,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: otherCount > 0
                          ? Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (hasResults) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    state.origin.split(',').first,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(LucideIcons.arrowRight,
                                    size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    state.destination.split(',').first,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleFavourite,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    isFav
                                        ? Icons.favorite
                                        : LucideIcons.heart,
                                    size: 16,
                                    color: AppColors.availLow),
                                const SizedBox(width: 6),
                                const Text(
                                  'Suosikki',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Peek hint: toggles expanded/collapsed
                    GestureDetector(
                      onTap: _isExpanded ? _snapCollapsed : _snapExpanded,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _isExpanded
                              ? const [
                                  Icon(LucideIcons.chevronsDown,
                                      size: 16,
                                      color: AppColors.textMuted),
                                  SizedBox(width: 6),
                                  Text('Pienennä',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textMuted)),
                                ]
                              : otherCount > 0
                                  ? [
                                      const Icon(LucideIcons.chevronsUp,
                                          size: 16,
                                          color: AppColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text('$otherCount muuta tulosta',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textMuted)),
                                    ]
                                  : const [],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: _cardsScrollCtrl,
                        physics: _isExpanded
                            ? const ClampingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, 4, AppSpacing.lg, AppSpacing.lg),
                        children: [
                          for (int i = 0; i < vr.length; i++)
                            Padding(
                              padding:
                                  EdgeInsets.only(top: i == 0 ? 0 : 10),
                              child: RouteCard(
                                route: vr[i],
                                isSelected: vr[i].id == sel?.id,
                                onTap: () {
                                  setState(
                                      () => selectedRouteId = vr[i].id);
                                  state.selectRoute(vr[i]);
                                },
                                onLongPress: () {
                                  state.selectRoute(vr[i]);
                                  Navigator.of(context)
                                      .pushNamed('/route-detail');
                                },
                                onAction: () {
                                  state.selectRoute(vr[i]);
                                  Navigator.of(context)
                                      .pushNamed('/route-detail');
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: state.isSearching
                          ? Column(
                              children: const [
                                SizedBox(height: AppSpacing.xl),
                                CircularProgressIndicator(
                                    color: AppColors.primary),
                                SizedBox(height: AppSpacing.md),
                                Text('Haetaan reittejä...',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14)),
                                SizedBox(height: AppSpacing.xl),
                              ],
                            )
                          : Text(
                              error ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.availLow, fontSize: 14),
                            ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Polyline> _buildPolylines() {
    final route = selectedRoute;
    if (!hasSearched || route == null) return [];
    final lines = <Polyline>[];
    for (final leg in route.legs) {
      if (leg.mode == TransitMode.park) continue;
      final g = leg.geometry;
      if (g == null || g.length < 2) continue;
      lines.add(Polyline(
        points: g.map((p) => LatLng(p[0], p[1])).toList(),
        color: _modeLineColors[leg.mode] ?? AppColors.primary,
        strokeWidth: leg.mode == TransitMode.walk ? 3 : 5,
        pattern: leg.mode == TransitMode.walk
            ? const StrokePattern.dotted()
            : const StrokePattern.solid(),
      ));
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final vr = visibleRoutes;
    final sel = selectedRoute;
    final hasResults = hasSearched && vr.isNotEmpty;
    final isFav = state.commutePairs.any(
      (p) => p.origin == state.origin && p.destination == state.destination,
    );
    final otherCount = (vr.length - 1).clamp(0, 99);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              interactionOptions: const InteractionOptions(
                enableMultiFingerGestureRace: true,
                flags: InteractiveFlag.doubleTapDragZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.flingAnimation |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.rotate |
                    InteractiveFlag.scrollWheelZoom,
              ),
              onTap: (_, __) {
                FocusScope.of(context).unfocus();
                if (selectedFacility != null && !hasSearched) {
                  setState(() => selectedFacility = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.liityntaparkki.liityntaparkki',
                maxNativeZoom: 19,
                retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
              ),
              PolylineLayer(polylines: _buildPolylines()),
              MarkerLayer(markers: _buildMarkers(state)),
            ],
          ),

          // Search overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Column(
              children: [
                AutocompleteInput(
                  value: state.origin,
                  onChangeText: state.setOrigin,
                  onSelect: (s) {
                    setState(() => originCoords = (lat: s.lat, lon: s.lon));
                    _maybeAutoSearch();
                  },
                  placeholder: 'Lähtöpaikka',
                  variant: 'origin',
                  onSubmitted: _handleSearch,
                  onRequestLocation: _handleRequestLocation,
                  onClear: () {
                    state.setOrigin('');
                    setState(() => originCoords = null);
                    _clearSearchResults();
                  },
                  focusPoint: userLocation,
                ),
                const SizedBox(height: AppSpacing.sm),
                AutocompleteInput(
                  value: state.destination,
                  onChangeText: state.setDestination,
                  onSelect: (s) {
                    setState(() => destCoords = (lat: s.lat, lon: s.lon));
                    _maybeAutoSearch();
                  },
                  placeholder: 'Määränpää',
                  variant: 'destination',
                  onSubmitted: _handleSearch,
                  onClear: () {
                    state.setDestination('');
                    setState(() => destCoords = null);
                    _clearSearchResults();
                  },
                  focusPoint: userLocation,
                ),
                if (state.facilitiesError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border:
                          Border.all(color: AppColors.availLow, width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertTriangle,
                            size: 18, color: AppColors.availLow),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            state.facilitiesError!,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                        TextButton(
                          onPressed: state.facilitiesLoading
                              ? null
                              : state.loadFacilities,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: state.facilitiesLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary),
                                )
                              : const Text('Yritä uudelleen',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hasSearched && !_isExpanded) ...[
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () {
                      state.setOrigin('');
                      state.setDestination('');
                      setState(() {
                        originCoords = null;
                        destCoords = null;
                      });
                      _clearSearchResults();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(LucideIcons.x,
                              size: 12, color: AppColors.textSecondary),
                          SizedBox(width: 4),
                          Text('Tyhjennä haut',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Facility sheet (pre-search)
          if (!hasSearched && selectedFacility != null && !state.isSearching)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _FacilitySheet(
                facility: selectedFacility!,
                onClose: () => setState(() => selectedFacility = null),
              ),
            ),

          // Results bottom sheet
          if (hasResults || state.isSearching || error != null)
            _buildResultsSheet(state, vr, sel, hasResults, otherCount, isFav),
        ],
      ),
    );
  }
}

class _ParkingPin extends StatelessWidget {
  final int count;
  final Color availColor;
  final bool selected;
  final bool faded;
  const _ParkingPin({
    required this.count,
    required this.availColor,
    this.selected = false,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgSize = selected ? 48.0 : 38.0;
    final bg = selected ? AppColors.primary : availColor;
    return Opacity(
      opacity: faded ? 0.55 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: bgSize,
            height: bgSize,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bgWhite, width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x2E000000),
                    offset: Offset(0, 2),
                    blurRadius: 6),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('P',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textWhite)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.bgWhite,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1F000000),
                    offset: Offset(0, 1),
                    blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: availColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.textWhite
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilitySheet extends StatelessWidget {
  final ParkingFacility facility;
  final VoidCallback onClose;
  const _FacilitySheet({required this.facility, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isFav = state.favouriteParkingSpots
        .any((s) => s.facilityId == facility.id);
    final color = _availColor(facility.availability);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadii.xl),
          topRight: Radius.circular(AppRadii.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary, width: 1),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            (facility.available ?? facility.capacity).toString(),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textWhite),
                          ),
                          if (facility.available != null)
                            Text('/${facility.capacity}',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.8))),
                          Text(
                            facility.available != null ? 'vapaana' : 'paikkaa',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(facility.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text(
                                  formatUpdatedAgo(state.facilitiesUpdatedAt),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                              height: 1, color: AppColors.borderLight),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => nav.navigateTo(
                                      facility.latitude,
                                      facility.longitude,
                                      label: facility.name,
                                    ),
                                    child: Container(
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(LucideIcons.navigation,
                                            size: 13, color: AppColors.primary),
                                        SizedBox(width: 5),
                                        Text('Navigoi parkkiin',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary)),
                                        SizedBox(width: 5),
                                        Icon(LucideIcons.chevronRight,
                                            size: 13, color: AppColors.primary),
                                      ],
                                    ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    final fid = facility.id;
                                    if (isFav) {
                                      state.removeFavouriteParkingSpot(fid);
                                    } else {
                                      state.addFavouriteParkingSpot(
                                        FavouriteParkingSpot(
                                          id: fid,
                                          facilityId: fid,
                                          name: facility.name,
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
                                      isFav
                                          ? Icons.favorite
                                          : LucideIcons.heart,
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
          ),
        ],
      ),
    );
  }
}
