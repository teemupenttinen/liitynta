import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/route.dart';

const _proxyBase = String.fromEnvironment('PROXY_URL');
const _appToken = String.fromEnvironment('APP_TOKEN');

const _routingUrl = '$_proxyBase/routing';
const _geocodingUrl = '$_proxyBase/geocoding/v1';
const _facilitiesUrl = '$_proxyBase/facilities';
const _utilizationsUrl = '$_proxyBase/utilizations';

const Map<String, double> _walkSpeeds = {
  'slow': 0.97,
  'normal': 1.28,
  'fast': 1.67,
};

class GeocodeSuggestion {
  final String label;
  final double lat;
  final double lon;
  const GeocodeSuggestion({required this.label, required this.lat, required this.lon});
}

Map<String, String> _authHeaders([Map<String, String>? extra]) => {
      'X-App-Token': _appToken,
      if (extra != null) ...extra,
    };

const _httpTimeout = Duration(seconds: 10);
const _maxRetries = 2;

Future<http.Response> _httpGet(Uri uri, {Map<String, String>? headers}) =>
    _withRetry(() => http.get(uri, headers: headers));

Future<http.Response> _httpPost(Uri uri,
        {Map<String, String>? headers, Object? body}) =>
    _withRetry(() => http.post(uri, headers: headers, body: body));

Future<http.Response> _withRetry(Future<http.Response> Function() send) async {
  Object? lastError;
  for (int i = 0; i <= _maxRetries; i++) {
    try {
      final res = await send().timeout(_httpTimeout);
      // Retry on 5xx; return 4xx as-is so callers can react to them
      if (res.statusCode >= 500 && i < _maxRetries) {
        await Future.delayed(Duration(milliseconds: 300 * (1 << i)));
        continue;
      }
      return res;
    } catch (e) {
      lastError = e;
      if (i < _maxRetries) {
        await Future.delayed(Duration(milliseconds: 300 * (1 << i)));
      }
    }
  }
  throw lastError ?? Exception('HTTP request failed');
}

// Fallback focus point used when the user's GPS location is unavailable
const _helsinkiCenter = (lat: 60.1699, lon: 24.9384);

Future<List<GeocodeSuggestion>> autocomplete(
  String text, {
  ({double lat, double lon})? focusPoint,
}) async {
  if (text.length < 2) return [];
  final focus = focusPoint ?? _helsinkiCenter;
  final params = <String, String>{
    'text': text,
    'size': '5',
    'lang': 'fi',
    'boundary.country': 'FIN',
    'focus.point.lat': focus.lat.toString(),
    'focus.point.lon': focus.lon.toString(),
  };
  final uri = Uri.parse('$_geocodingUrl/autocomplete').replace(queryParameters: params);
  final res = await _httpGet(uri, headers: _authHeaders());
  if (res.statusCode != 200) return [];
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final features = (data['features'] as List?) ?? [];
  return features.map((f) {
    final props = f['properties'] as Map<String, dynamic>? ?? {};
    final coords = (f['geometry']?['coordinates'] as List?) ?? [0, 0];
    return GeocodeSuggestion(
      label: (props['label'] ?? props['name'] ?? '') as String,
      lat: (coords[1] as num).toDouble(),
      lon: (coords[0] as num).toDouble(),
    );
  }).toList();
}

Future<List<GeocodeSuggestion>> geocode(String query) async {
  final params = <String, String>{
    'text': query,
    'size': '5',
    'boundary.country': 'FIN',
    'lang': 'fi',
  };
  final uri = Uri.parse('$_geocodingUrl/search').replace(queryParameters: params);
  final res = await _httpGet(uri, headers: _authHeaders());
  if (res.statusCode != 200) return [];
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final features = (data['features'] as List?) ?? [];
  return features.map((f) {
    final props = f['properties'] as Map<String, dynamic>? ?? {};
    final coords = (f['geometry']?['coordinates'] as List?) ?? [0, 0];
    return GeocodeSuggestion(
      label: (props['label'] ?? props['name'] ?? '') as String,
      lat: (coords[1] as num).toDouble(),
      lon: (coords[0] as num).toDouble(),
    );
  }).toList();
}

class RawFacility {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int capacity;
  final int? available;
  RawFacility({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.available,
  });
}

({double lat, double lng}) _centroid(List coordinates) {
  final ring = coordinates[0] as List;
  double latSum = 0, lngSum = 0;
  for (final p in ring) {
    final pt = p as List;
    lngSum += (pt[0] as num).toDouble();
    latSum += (pt[1] as num).toDouble();
  }
  return (lat: latSum / ring.length, lng: lngSum / ring.length);
}

AvailabilityLevel availabilityLevel(int? available, int _capacity) {
  if (available == null) return AvailabilityLevel.unknown;
  if (available > 10) return AvailabilityLevel.high;
  if (available >= 5) return AvailabilityLevel.medium;
  return AvailabilityLevel.low;
}

Future<List<RawFacility>> fetchParkAndRideFacilities() async {
  final results = await Future.wait([
    _httpGet(Uri.parse(_facilitiesUrl), headers: _authHeaders()),
    _httpGet(Uri.parse(_utilizationsUrl), headers: _authHeaders()),
  ]);
  final facilitiesRes = results[0];
  final utilizationsRes = results[1];

  if (facilitiesRes.statusCode != 200) {
    throw Exception('Liityntäpysäköintien haku epäonnistui');
  }

  final data = jsonDecode(facilitiesRes.body) as Map<String, dynamic>;
  final utilizations = <int, int>{};
  if (utilizationsRes.statusCode == 200) {
    final util = jsonDecode(utilizationsRes.body) as List;
    for (final u in util) {
      final m = u as Map<String, dynamic>;
      if (m['capacityType'] == 'CAR' && m['usage'] == 'PARK_AND_RIDE') {
        utilizations[m['facilityId'] as int] = m['spacesAvailable'] as int;
      }
    }
  }

  final List list = (data['results'] as List?) ?? [];
  return list.where((f) {
    final built = (f['builtCapacity'] as Map?)?['CAR'];
    return f['status'] == 'IN_OPERATION' && built != null && (built as int) > 0;
  }).map((f) {
    final loc = _centroid((f['location']?['coordinates'] as List?) ?? []);
    final nameMap = f['name'] as Map<String, dynamic>? ?? {};
    return RawFacility(
      id: f['id'] as int,
      name: (nameMap['fi'] ?? nameMap['en'] ?? 'P+R ${f['id']}') as String,
      latitude: loc.lat,
      longitude: loc.lng,
      capacity: (f['builtCapacity']?['CAR'] as num).toInt(),
      available: utilizations[f['id'] as int],
    );
  }).where((f) => f.latitude != 0 && f.longitude != 0).toList();
}

// --- Polyline decoder (Google encoded polyline format) ---
List<List<double>> decodePolyline(String encoded) {
  final points = <List<double>>[];
  int index = 0;
  int lat = 0, lng = 0;
  while (index < encoded.length) {
    int shift = 0, result = 0, b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    points.add([lat / 1e5, lng / 1e5]);
  }
  return points;
}

Future<Map<String, dynamic>?> _queryDigitransit(String graphql) async {
  final res = await _httpPost(
    Uri.parse(_routingUrl),
    headers: _authHeaders({'Content-Type': 'application/json'}),
    body: jsonEncode({'query': graphql}),
  );
  if (res.statusCode != 200) return null;
  return jsonDecode(res.body) as Map<String, dynamic>;
}

class _DrivingResult {
  final int durationMinutes;
  final double distanceKm;
  final List<List<double>> geometry;
  _DrivingResult(this.durationMinutes, this.distanceKm, this.geometry);
}

Future<_DrivingResult?> _getDrivingRoute(
  double fromLat, double fromLon, double toLat, double toLon) async {
  final query = '''{
    plan(
      from: { lat: $fromLat, lon: $fromLon }
      to: { lat: $toLat, lon: $toLon }
      numItineraries: 1
      transportModes: [{ mode: CAR }]
    ) {
      itineraries {
        duration
        legs {
          distance
          legGeometry { points }
        }
      }
    }
  }''';
  final data = await _queryDigitransit(query);
  final its = ((data?['data']?['plan']?['itineraries']) as List?) ?? [];
  if (its.isEmpty) return null;
  final it = its.first as Map<String, dynamic>;
  final legs = (it['legs'] as List?) ?? [];
  final totalDist = legs.fold<double>(0, (s, l) => s + ((l['distance'] as num?)?.toDouble() ?? 0));
  final geom = <List<double>>[];
  for (final l in legs) {
    final pts = l['legGeometry']?['points'] as String?;
    if (pts != null) geom.addAll(decodePolyline(pts));
  }
  return _DrivingResult(
    ((it['duration'] as num) / 60).round(),
    (totalDist / 100).round() / 10,
    geom,
  );
}

class _TransitLeg {
  final String mode;
  final String? routeShortName;
  final String from;
  final String to;
  final int durationMinutes;
  final double distanceKm;
  final List<List<double>> geometry;
  _TransitLeg({
    required this.mode,
    required this.routeShortName,
    required this.from,
    required this.to,
    required this.durationMinutes,
    required this.distanceKm,
    required this.geometry,
  });
}

class _TransitResult {
  final int durationMinutes;
  final List<_TransitLeg> legs;
  _TransitResult(this.durationMinutes, this.legs);
}

Future<_TransitResult?> _getTransitRoute(
  double fromLat, double fromLon, double toLat, double toLon,
  {double walkSpeed = 1.39}) async {
  final query = '''{
    plan(
      from: { lat: $fromLat, lon: $fromLon }
      to: { lat: $toLat, lon: $toLon }
      numItineraries: 3
      walkSpeed: $walkSpeed
      transportModes: [
        { mode: WALK }
        { mode: TRANSIT }
      ]
    ) {
      itineraries {
        startTime
        endTime
        duration
        legs {
          mode
          route { shortName }
          from { name }
          to { name }
          duration
          distance
          legGeometry { points }
        }
      }
    }
  }''';
  final data = await _queryDigitransit(query);
  final its = ((data?['data']?['plan']?['itineraries']) as List?) ?? [];
  if (its.isEmpty) return null;
  final it = its.first as Map<String, dynamic>;
  final legs = ((it['legs'] as List?) ?? []).map((l) {
    final m = l as Map<String, dynamic>;
    final pts = m['legGeometry']?['points'] as String?;
    return _TransitLeg(
      mode: m['mode'] as String,
      routeShortName: m['route']?['shortName'] as String?,
      from: (m['from']?['name'] ?? '') as String,
      to: (m['to']?['name'] ?? '') as String,
      durationMinutes: ((m['duration'] as num) / 60).round(),
      distanceKm: ((m['distance'] as num) / 100).round() / 10,
      geometry: pts != null ? decodePolyline(pts) : <List<double>>[],
    );
  }).toList();
  return _TransitResult(((it['duration'] as num) / 60).round(), legs);
}

TransitMode _mapMode(String apiMode) {
  switch (apiMode) {
    case 'CAR': return TransitMode.drive;
    case 'SUBWAY': return TransitMode.metro;
    case 'BUS': return TransitMode.bus;
    case 'TRAM': return TransitMode.tram;
    case 'RAIL': return TransitMode.rail;
    case 'FERRY': return TransitMode.ferry;
    case 'WALK':
    default: return TransitMode.walk;
  }
}

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) * math.sin(dLon / 2);
  return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

Future<List<AppRoute>> searchRoutes(
  double originLat,
  double originLon,
  double destLat,
  double destLon, {
  String walkingSpeed = 'normal',
  String originLabel = 'Lähtöpaikka',
  String destinationLabel = 'Määränpää',
}) async {
  final allFacilities = await fetchParkAndRideFacilities();
  final originDestDist = _haversine(originLat, originLon, destLat, destLon);
  const maxDistanceKm = 100.0;

  final enriched = allFacilities.map((f) {
    final dOrig = _haversine(originLat, originLon, f.latitude, f.longitude);
    final dDest = _haversine(destLat, destLon, f.latitude, f.longitude);
    final detour = dOrig + dDest - originDestDist;
    return _FacilityRank(f, dOrig, dDest, detour);
  }).where((r) => r.distFromOrigin < maxDistanceKm && r.distFromDest < originDestDist).toList()
    ..sort((a, b) => a.detour.compareTo(b.detour));

  final nearby = enriched.take(20).toList();
  if (nearby.isEmpty) return [];

  final walkSpeedMs = _walkSpeeds[walkingSpeed] ?? 1.39;

  final routes = await Future.wait(nearby.map((r) async {
    final f = r.f;
    final results = await Future.wait([
      _getDrivingRoute(originLat, originLon, f.latitude, f.longitude),
      _getTransitRoute(f.latitude, f.longitude, destLat, destLon, walkSpeed: walkSpeedMs),
    ]);
    final driving = results[0] as _DrivingResult?;
    final transit = results[1] as _TransitResult?;
    if (driving == null || transit == null) return null;

    final totalMinutes = driving.durationMinutes + transit.durationMinutes;
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: totalMinutes));
    final firstWalk = transit.legs.where((l) => l.mode == 'WALK').cast<_TransitLeg?>().firstWhere(
          (_) => true,
          orElse: () => null,
        );
    final walkToStationMinutes = firstWalk?.durationMinutes ?? 3;

    final parking = ParkingFacility(
      id: f.id.toString(),
      name: f.name,
      available: f.available,
      capacity: f.capacity,
      availability: availabilityLevel(f.available, f.capacity),
      latitude: f.latitude,
      longitude: f.longitude,
      walkToStationMinutes: walkToStationMinutes,
    );

    final rawLegs = <RouteLeg>[
      RouteLeg(
        mode: TransitMode.drive,
        from: originLabel,
        to: f.name,
        durationMinutes: driving.durationMinutes,
        distanceKm: driving.distanceKm,
        geometry: driving.geometry,
      ),
      RouteLeg(
        mode: TransitMode.park,
        from: f.name,
        to: f.name,
        durationMinutes: walkToStationMinutes,
        distanceKm: 0,
        parking: parking,
      ),
      ...transit.legs.map((t) => RouteLeg(
            mode: _mapMode(t.mode),
            from: t.from,
            to: t.to,
            durationMinutes: t.durationMinutes,
            distanceKm: t.distanceKm,
            lineName: t.routeShortName,
            geometry: t.geometry,
          )),
    ];

    String normalizeEndpoint(String s) {
      if (s == 'Origin') return originLabel;
      if (s == 'Destination') return destinationLabel;
      return s;
    }

    final legs = <RouteLeg>[];
    for (int i = 0; i < rawLegs.length; i++) {
      final l = rawLegs[i];
      if (l.mode == TransitMode.walk) {
        final from = i > 0 ? rawLegs[i - 1].to : l.from;
        final to =
            i < rawLegs.length - 1 ? rawLegs[i + 1].from : l.to;
        legs.add(RouteLeg(
          mode: l.mode,
          from: normalizeEndpoint(from),
          to: normalizeEndpoint(to),
          durationMinutes: l.durationMinutes,
          distanceKm: l.distanceKm,
          lineName: l.lineName,
          lineDescription: l.lineDescription,
          parking: l.parking,
          geometry: l.geometry,
        ));
      } else {
        legs.add(l);
      }
    }

    return AppRoute(
      id: 'route-${f.id}',
      totalMinutes: totalMinutes,
      departureTime: now,
      arrivalTime: arrival,
      legs: legs,
      parking: parking,
    );
  }));

  final valid = routes.whereType<AppRoute>().where((r) {
    final transitLegs = r.legs.where((l) =>
      l.mode != TransitMode.drive && l.mode != TransitMode.park && l.mode != TransitMode.walk).length;
    return transitLegs >= 1 && transitLegs <= 2;
  }).toList();

  const metroBonus = 10;
  valid.sort((a, b) {
    final aMetro = a.legs.any((l) => l.mode == TransitMode.metro);
    final bMetro = b.legs.any((l) => l.mode == TransitMode.metro);
    final eA = a.totalMinutes - (aMetro ? metroBonus : 0);
    final eB = b.totalMinutes - (bMetro ? metroBonus : 0);
    return eA.compareTo(eB);
  });
  return valid;
}

class _FacilityRank {
  final RawFacility f;
  final double distFromOrigin;
  final double distFromDest;
  final double detour;
  _FacilityRank(this.f, this.distFromOrigin, this.distFromDest, this.detour);
}
