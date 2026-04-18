import 'package:flutter/foundation.dart';
import '../models/route.dart';

enum WalkingSpeed { slow, normal, fast }

extension WalkingSpeedX on WalkingSpeed {
  String get key => name;
}

class AppState extends ChangeNotifier {
  // Search
  String origin = '';
  String destination = '';
  List<AppRoute> routes = [];
  AppRoute? selectedRoute;
  bool isSearching = false;

  // Facilities cache
  List<Facility> facilities = [];

  // Favourites
  List<CommutePair> commutePairs = [];
  List<FavouriteParkingSpot> favouriteParkingSpots = [];

  // Settings
  WalkingSpeed walkingSpeed = WalkingSpeed.normal;
  bool showOnlyAvailable = true;

  void setOrigin(String v) { origin = v; notifyListeners(); }
  void setDestination(String v) { destination = v; notifyListeners(); }
  void setRoutes(List<AppRoute> r) { routes = r; notifyListeners(); }
  void selectRoute(AppRoute? r) { selectedRoute = r; notifyListeners(); }
  void setIsSearching(bool v) { isSearching = v; notifyListeners(); }
  void setFacilities(List<Facility> f) { facilities = f; notifyListeners(); }

  void addCommutePair(CommutePair p) {
    commutePairs = [...commutePairs, p];
    notifyListeners();
  }

  void removeCommutePair(String id) {
    commutePairs = commutePairs.where((p) => p.id != id).toList();
    notifyListeners();
  }

  void addFavouriteParkingSpot(FavouriteParkingSpot s) {
    favouriteParkingSpots = [...favouriteParkingSpots, s];
    notifyListeners();
  }

  void removeFavouriteParkingSpot(String id) {
    favouriteParkingSpots = favouriteParkingSpots.where((s) => s.id != id).toList();
    notifyListeners();
  }

  void setWalkingSpeed(WalkingSpeed s) { walkingSpeed = s; notifyListeners(); }
  void setShowOnlyAvailable(bool v) { showOnlyAvailable = v; notifyListeners(); }
}
