enum TransitMode { drive, park, metro, bus, tram, rail, ferry, walk }

enum AvailabilityLevel { high, medium, low, unknown }

class ParkingFacility {
  final String id;
  final String name;
  final int? available;
  final int capacity;
  final AvailabilityLevel availability;
  final double latitude;
  final double longitude;
  final int walkToStationMinutes;

  const ParkingFacility({
    required this.id,
    required this.name,
    required this.available,
    required this.capacity,
    required this.availability,
    required this.latitude,
    required this.longitude,
    this.walkToStationMinutes = 0,
  });
}

class RouteLeg {
  final TransitMode mode;
  final String from;
  final String to;
  final int durationMinutes;
  final double distanceKm;
  final String? lineName;
  final String? lineDescription;
  final ParkingFacility? parking;
  final List<List<double>>? geometry; // [lat, lon]

  const RouteLeg({
    required this.mode,
    required this.from,
    required this.to,
    required this.durationMinutes,
    required this.distanceKm,
    this.lineName,
    this.lineDescription,
    this.parking,
    this.geometry,
  });
}

class AppRoute {
  final String id;
  final int totalMinutes;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final List<RouteLeg> legs;
  final ParkingFacility parking;

  const AppRoute({
    required this.id,
    required this.totalMinutes,
    required this.departureTime,
    required this.arrivalTime,
    required this.legs,
    required this.parking,
  });
}

class CommutePair {
  final String id;
  final String origin;
  final String destination;
  final DateTime createdAt;

  const CommutePair({
    required this.id,
    required this.origin,
    required this.destination,
    required this.createdAt,
  });
}

class FavouriteParkingSpot {
  final String id;
  final String facilityId;
  final String name;

  const FavouriteParkingSpot({
    required this.id,
    required this.facilityId,
    required this.name,
  });
}

