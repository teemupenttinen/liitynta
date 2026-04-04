import { Linking, Platform } from 'react-native';

/**
 * Open native maps app for navigation to a destination.
 * Corresponds to the "Aja parkkiin" / "Navigoi kohteeseen" buttons.
 */
export function navigateTo(lat: number, lon: number, label?: string) {
  const encodedLabel = label ? encodeURIComponent(label) : '';

  if (Platform.OS === 'ios') {
    // Apple Maps with driving directions
    Linking.openURL(
      `maps://app?daddr=${lat},${lon}&dirflg=d&t=m${encodedLabel ? `&q=${encodedLabel}` : ''}`,
    );
  } else {
    // Google Maps
    Linking.openURL(
      `google.navigation:q=${lat},${lon}&mode=d`,
    );
  }
}

/**
 * Open transit directions in Google Maps or HSL app.
 */
export function navigateTransit(
  fromLat: number,
  fromLon: number,
  toLat: number,
  toLon: number,
) {
  const url = `https://www.google.com/maps/dir/?api=1&origin=${fromLat},${fromLon}&destination=${toLat},${toLon}&travelmode=transit`;
  Linking.openURL(url);
}

/**
 * Determine which navigation CTA to show based on user's location
 * relative to the parking spot and destination.
 */
export function getNavigationState(
  userLat: number,
  userLon: number,
  parkingLat: number,
  parkingLon: number,
  destLat: number,
  destLon: number,
): 'drive_to_parking' | 'navigate_to_destination' {
  const distToParking = haversine(userLat, userLon, parkingLat, parkingLon);
  const distToDest = haversine(userLat, userLon, destLat, destLon);
  const parkingThreshold = 0.3; // 300m

  if (distToParking < parkingThreshold || distToDest < distToParking) {
    return 'navigate_to_destination';
  }
  return 'drive_to_parking';
}

function haversine(
  lat1: number, lon1: number,
  lat2: number, lon2: number,
): number {
  const R = 6371; // km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}
