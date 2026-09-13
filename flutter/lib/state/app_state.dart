import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route.dart';
import '../services/digitransit.dart';

enum WalkingSpeed { slow, normal, fast }

extension WalkingSpeedX on WalkingSpeed {
  String get key => name;
}

const _kCommutePairs = 'commute_pairs';
const _kFavParkingSpots = 'favourite_parking_spots';
const _kWalkingSpeed = 'walking_speed';
const _kShowOnlyAvailable = 'show_only_available';
const _kOpenOnFavourites = 'open_on_favourites';

class AppState extends ChangeNotifier {
  // Search
  String origin = '';
  String destination = '';
  List<AppRoute> routes = [];
  AppRoute? selectedRoute;
  bool isSearching = false;
  // Departure time for route searches. Null means "leave now".
  DateTime? departAt;

  // Facilities cache
  List<ParkingFacility> facilities = [];
  DateTime? facilitiesUpdatedAt;
  bool facilitiesLoading = false;
  String? facilitiesError;
  Timer? _facilitiesPollTimer;
  static const _facilitiesPollInterval = Duration(minutes: 2);

  // Favourites
  List<CommutePair> commutePairs = [];
  List<FavouriteParkingSpot> favouriteParkingSpots = [];

  // Search coordinates
  double? destLatitude;
  double? destLongitude;

  // Settings
  WalkingSpeed walkingSpeed = WalkingSpeed.normal;
  bool showOnlyAvailable = true;
  bool openOnFavourites = false;

  // Navigation
  int activeTabIndex = 0;
  int _searchRequestNonce = 0;
  int get searchRequestNonce => _searchRequestNonce;

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    final pairsJson = _prefs!.getString(_kCommutePairs);
    if (pairsJson != null) {
      final list = jsonDecode(pairsJson) as List;
      commutePairs = list
          .map((e) => CommutePair(
                id: e['id'] as String,
                origin: e['origin'] as String,
                destination: e['destination'] as String,
                createdAt: DateTime.parse(e['createdAt'] as String),
              ))
          .toList();
    }

    final spotsJson = _prefs!.getString(_kFavParkingSpots);
    if (spotsJson != null) {
      final list = jsonDecode(spotsJson) as List;
      favouriteParkingSpots = list
          .map((e) => FavouriteParkingSpot(
                id: e['id'] as String,
                facilityId: e['facilityId'] as String,
                name: e['name'] as String,
              ))
          .toList();
    }

    final speed = _prefs!.getString(_kWalkingSpeed);
    if (speed != null) {
      walkingSpeed = WalkingSpeed.values.firstWhere(
        (s) => s.name == speed,
        orElse: () => WalkingSpeed.normal,
      );
    }

    final showAvail = _prefs!.getBool(_kShowOnlyAvailable);
    if (showAvail != null) showOnlyAvailable = showAvail;

    final openFav = _prefs!.getBool(_kOpenOnFavourites);
    if (openFav != null) openOnFavourites = openFav;
    activeTabIndex = openOnFavourites ? 1 : 0;

    notifyListeners();
    startFacilitiesPolling();
  }

  void startFacilitiesPolling() {
    if (_facilitiesPollTimer != null) return;
    loadFacilities();
    _facilitiesPollTimer = Timer.periodic(
      _facilitiesPollInterval,
      (_) => loadFacilities(),
    );
  }

  Future<void> loadFacilities() async {
    if (facilitiesLoading) return;
    facilitiesLoading = true;
    facilitiesError = null;
    notifyListeners();
    try {
      final raw = await fetchParkAndRideFacilities();
      final facs = raw.map((f) {
        return ParkingFacility(
          id: f.id.toString(),
          name: f.name,
          latitude: f.latitude,
          longitude: f.longitude,
          capacity: f.capacity,
          available: f.available,
          availability: availabilityLevel(f.available, f.capacity),
        );
      }).toList();
      facilities = facs;
      facilitiesUpdatedAt = DateTime.now();
    } catch (_) {
      facilitiesError = 'Parkkipaikkojen lataus epäonnistui. Tarkista yhteys.';
    } finally {
      facilitiesLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _facilitiesPollTimer?.cancel();
    super.dispose();
  }

  void _persistCommutePairs() {
    _prefs?.setString(
        _kCommutePairs,
        jsonEncode(commutePairs
            .map((p) => {
                  'id': p.id,
                  'origin': p.origin,
                  'destination': p.destination,
                  'createdAt': p.createdAt.toIso8601String(),
                })
            .toList()));
  }

  void _persistFavParkingSpots() {
    _prefs?.setString(
        _kFavParkingSpots,
        jsonEncode(favouriteParkingSpots
            .map((s) => {
                  'id': s.id,
                  'facilityId': s.facilityId,
                  'name': s.name,
                })
            .toList()));
  }

  void setOrigin(String v) { origin = v; notifyListeners(); }
  void setDestination(String v) { destination = v; notifyListeners(); }
  void setDestCoords(double? lat, double? lon) {
    destLatitude = lat;
    destLongitude = lon;
    notifyListeners();
  }
  void setRoutes(List<AppRoute> r) { routes = r; notifyListeners(); }
  void selectRoute(AppRoute? r) { selectedRoute = r; notifyListeners(); }
  void setIsSearching(bool v) { isSearching = v; notifyListeners(); }
  void setDepartAt(DateTime? v) { departAt = v; notifyListeners(); }

  void addCommutePair(CommutePair p) {
    commutePairs = [...commutePairs, p];
    _persistCommutePairs();
    notifyListeners();
  }

  void removeCommutePair(String id) {
    commutePairs = commutePairs.where((p) => p.id != id).toList();
    _persistCommutePairs();
    notifyListeners();
  }

  void addFavouriteParkingSpot(FavouriteParkingSpot s) {
    favouriteParkingSpots = [...favouriteParkingSpots, s];
    _persistFavParkingSpots();
    notifyListeners();
  }

  void removeFavouriteParkingSpot(String id) {
    favouriteParkingSpots =
        favouriteParkingSpots.where((s) => s.id != id).toList();
    _persistFavParkingSpots();
    notifyListeners();
  }

  void setWalkingSpeed(WalkingSpeed s) {
    walkingSpeed = s;
    _prefs?.setString(_kWalkingSpeed, s.name);
    notifyListeners();
  }

  void setShowOnlyAvailable(bool v) {
    showOnlyAvailable = v;
    _prefs?.setBool(_kShowOnlyAvailable, v);
    notifyListeners();
  }

  void setOpenOnFavourites(bool v) {
    openOnFavourites = v;
    _prefs?.setBool(_kOpenOnFavourites, v);
    notifyListeners();
  }

  void setActiveTab(int i) {
    activeTabIndex = i;
    notifyListeners();
  }

  /// Populate origin + destination from a saved favourite and signal MapScreen
  /// to run a search. Switches the active tab to the map.
  void requestSearchFromFavourite(CommutePair p) {
    origin = p.origin;
    destination = p.destination;
    destLatitude = null;
    destLongitude = null;
    routes = [];
    activeTabIndex = 0;
    _searchRequestNonce++;
    notifyListeners();
  }
}
