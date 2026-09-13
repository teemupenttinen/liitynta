import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

/// Target maps app for a turn-by-turn handoff, chosen at launch time.
///
/// Apple Maps only exists on iOS; on Android [apple] silently resolves to
/// Google Maps via the candidate fallback below.
enum NavigationApp { apple, google }

/// Which maps apps are actually installed, in display order.
///
/// On iOS both schemes are declared in `LSApplicationQueriesSchemes`, so
/// `canLaunchUrl` reports real install state. An empty result is possible
/// (Apple Maps can be deleted); callers should still hand off, since the
/// launch candidates end in a google.com URL that always resolves.
Future<List<NavigationApp>> installedNavigationApps() async {
  final found = <NavigationApp>[];
  for (final app in NavigationApp.values) {
    final probe = _probeUri(app);
    if (probe != null && await canLaunchUrl(probe)) found.add(app);
  }
  return found;
}

Uri? _probeUri(NavigationApp app) {
  switch (app) {
    case NavigationApp.apple:
      return Platform.isIOS ? Uri.parse('maps://') : null;
    case NavigationApp.google:
      return Uri.parse(
          Platform.isIOS ? 'comgooglemaps://' : 'google.navigation:q=0,0');
  }
}

Future<void> navigateTo(
  double lat,
  double lon, {
  String? label,
  NavigationApp app = NavigationApp.apple,
}) async {
  await _launchFirstAvailable(_driveCandidates(lat, lon, label, app));
}

Future<void> navigateTransit(
  double fromLat,
  double fromLon,
  double toLat,
  double toLon, {
  NavigationApp app = NavigationApp.apple,
}) async {
  await _launchFirstAvailable(
      _transitCandidates(fromLat, fromLon, toLat, toLon, app));
}

/// Ordered by preference: the chosen app first, the other native app next, and
/// a google.com URL last so we always hand off somewhere even if neither app
/// is installed.
List<Uri> _driveCandidates(
    double lat, double lon, String? label, NavigationApp app) {
  final encoded = label != null ? Uri.encodeComponent(label) : '';
  final apple = <Uri>[
    if (Platform.isIOS)
      Uri.parse(
        'maps://app?daddr=$lat,$lon&dirflg=d&t=m${encoded.isNotEmpty ? '&q=$encoded' : ''}',
      ),
  ];
  final google = <Uri>[
    if (Platform.isIOS)
      Uri.parse('comgooglemaps://?daddr=$lat,$lon&directionsmode=driving')
    else
      Uri.parse('google.navigation:q=$lat,$lon&mode=d'),
  ];
  final web = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
  );
  return app == NavigationApp.google
      ? [...google, ...apple, web]
      : [...apple, ...google, web];
}

List<Uri> _transitCandidates(double fromLat, double fromLon, double toLat,
    double toLon, NavigationApp app) {
  final apple = <Uri>[
    if (Platform.isIOS)
      Uri.parse(
        'maps://?saddr=$fromLat,$fromLon&daddr=$toLat,$toLon&dirflg=r',
      ),
  ];
  final google = <Uri>[
    if (Platform.isIOS)
      Uri.parse(
        'comgooglemaps://?saddr=$fromLat,$fromLon&daddr=$toLat,$toLon&directionsmode=transit',
      ),
  ];
  final web = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&origin=$fromLat,$fromLon&destination=$toLat,$toLon&travelmode=transit',
  );
  return app == NavigationApp.google
      ? [...google, ...apple, web]
      : [...apple, ...google, web];
}

Future<void> _launchFirstAvailable(List<Uri> candidates) async {
  for (final uri in candidates) {
    if (await canLaunchUrl(uri)) {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    }
  }
}

enum NavigationState { driveToParking, navigateToDestination }

NavigationState getNavigationState(
  double userLat, double userLon,
  double parkingLat, double parkingLon,
  double destLat, double destLon,
) {
  final distToParking = _haversine(userLat, userLon, parkingLat, parkingLon);
  final distToDest = _haversine(userLat, userLon, destLat, destLon);
  const parkingThreshold = 0.3;
  if (distToParking < parkingThreshold || distToDest < distToParking) {
    return NavigationState.navigateToDestination;
  }
  return NavigationState.driveToParking;
}

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
          math.sin(dLon / 2) * math.sin(dLon / 2);
  return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _toRad(double deg) => deg * math.pi / 180;
