import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

Future<void> navigateTo(double lat, double lon, {String? label}) async {
  final encoded = label != null ? Uri.encodeComponent(label) : '';
  Uri uri;
  if (Platform.isIOS) {
    uri = Uri.parse(
      'maps://app?daddr=$lat,$lon&dirflg=d&t=m${encoded.isNotEmpty ? '&q=$encoded' : ''}',
    );
  } else {
    uri = Uri.parse('google.navigation:q=$lat,$lon&mode=d');
  }
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> navigateTransit(
    double fromLat, double fromLon, double toLat, double toLon) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&origin=$fromLat,$fromLon&destination=$toLat,$toLon&travelmode=transit',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
