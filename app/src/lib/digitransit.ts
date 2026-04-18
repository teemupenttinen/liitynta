import type { Route, RouteLeg, ParkingFacility, TransitMode, AvailabilityLevel } from '@/types/route';

// --- API endpoints (direct, no proxy needed in Expo) ---
const DIGITRANSIT_ROUTING_URL = 'https://api.digitransit.fi/routing/v2/hsl/gtfs/v1';
const DIGITRANSIT_GEOCODING_URL = 'https://api.digitransit.fi/geocoding/v1';
const FINTRAFFIC_FACILITIES_URL = 'https://parking.fintraffic.fi/api/v1/facilities.json';
const FINTRAFFIC_UTILIZATIONS_URL = 'https://parking.fintraffic.fi/api/v1/utilizations.json';

const DIGITRANSIT_API_KEY = process.env.EXPO_PUBLIC_DIGITRANSIT_API_KEY ?? '';

const WALK_SPEEDS: Record<string, number> = {
  slow: 0.97,    // 3.5 km/h
  normal: 1.28,  // 4.6 km/h (reference default)
  fast: 1.67,    // 6.0 km/h
};

// --- Geocoding ---

export interface GeocodeSuggestion {
  label: string;
  lat: number;
  lon: number;
}

/**
 * Autocomplete address search (for live suggestions while typing).
 */
export async function autocomplete(
  text: string,
  focusPoint?: { lat: number; lon: number },
): Promise<GeocodeSuggestion[]> {
  if (text.length < 2) return [];

  const params = new URLSearchParams({
    text,
    size: '5',
    'boundary.country': 'FIN',
    lang: 'fi',
  });

  // Bias results toward user's location (closer results ranked higher)
  if (focusPoint) {
    params.set('focus.point.lat', String(focusPoint.lat));
    params.set('focus.point.lon', String(focusPoint.lon));
  }

  const res = await fetch(`${DIGITRANSIT_GEOCODING_URL}/autocomplete?${params}`, {
    headers: { 'digitransit-subscription-key': DIGITRANSIT_API_KEY },
  });

  if (!res.ok) return [];

  const data = await res.json();
  return (data.features ?? []).map((f: any) => ({
    label: f.properties?.label ?? f.properties?.name ?? '',
    lat: f.geometry.coordinates[1],
    lon: f.geometry.coordinates[0],
  }));
}

/**
 * Geocode a Finnish address to coordinates.
 */
export async function geocode(
  query: string,
): Promise<{ lat: number; lon: number; label: string }[]> {
  const params = new URLSearchParams({
    text: query,
    size: '5',
    'boundary.country': 'FIN',
    lang: 'fi',
  });

  const res = await fetch(`${DIGITRANSIT_GEOCODING_URL}/search?${params}`, {
    headers: { 'digitransit-subscription-key': DIGITRANSIT_API_KEY },
  });

  if (!res.ok) return [];

  const data = await res.json();
  return (data.features ?? []).map((f: any) => ({
    lat: f.geometry.coordinates[1],
    lon: f.geometry.coordinates[0],
    label: f.properties?.label ?? f.properties?.name ?? '',
  }));
}

// --- Park & Ride Facilities (Fintraffic) ---

interface RawFacility {
  id: number;
  name: string;
  latitude: number;
  longitude: number;
  capacity: number;
  available?: number;
}

function getCentroid(coordinates: number[][][]): { lat: number; lng: number } {
  const ring = coordinates[0];
  let latSum = 0;
  let lngSum = 0;
  for (const [lng, lat] of ring) {
    latSum += lat;
    lngSum += lng;
  }
  return { lat: latSum / ring.length, lng: lngSum / ring.length };
}

function getAvailabilityLevel(available: number, _capacity: number): AvailabilityLevel {
  if (available > 10) return 'high';
  if (available >= 5) return 'medium';
  return 'low';
}

/**
 * Fetch all P+R facilities with real-time utilization data from Fintraffic.
 */
export async function fetchParkAndRideFacilities(): Promise<RawFacility[]> {
  const [facilitiesRes, utilizationsRes] = await Promise.all([
    fetch(FINTRAFFIC_FACILITIES_URL),
    fetch(FINTRAFFIC_UTILIZATIONS_URL),
  ]);

  if (!facilitiesRes.ok) throw new Error('Liityntaparkkien haku epäonnistui');

  const data = await facilitiesRes.json();

  const utilizations = new Map<number, number>();
  if (utilizationsRes.ok) {
    const utilData: any[] = await utilizationsRes.json();
    for (const u of utilData) {
      if (u.capacityType === 'CAR' && u.usage === 'PARK_AND_RIDE') {
        utilizations.set(u.facilityId, u.spacesAvailable);
      }
    }
  }

  return data.results
    .filter(
      (f: any) =>
        f.status === 'IN_OPERATION' &&
        f.builtCapacity?.CAR &&
        f.builtCapacity.CAR > 0,
    )
    .map((f: any) => {
      const loc = getCentroid(f.location.coordinates);
      return {
        id: f.id,
        name: f.name?.fi || f.name?.en || `P+R ${f.id}`,
        latitude: loc.lat,
        longitude: loc.lng,
        capacity: f.builtCapacity.CAR,
        available: utilizations.get(f.id),
      };
    })
    .filter((f: RawFacility) => f.latitude && f.longitude);
}

/**
 * Fetch real-time parking availability for specific facility IDs.
 */
export async function getParkingAvailability(
  facilityIds: string[],
): Promise<ParkingFacility[]> {
  const facilities = await fetchParkAndRideFacilities();

  const idSet = new Set(facilityIds.map(Number));
  return facilities
    .filter((f) => idSet.has(f.id))
    .map((f) => ({
      id: String(f.id),
      name: f.name,
      available: f.available ?? 0,
      capacity: f.capacity,
      availability: getAvailabilityLevel(f.available ?? 0, f.capacity),
      latitude: f.latitude,
      longitude: f.longitude,
      walkToStationMinutes: 0, // Unknown without routing
    }));
}

// --- Routing (Digitransit GraphQL) ---

function decodePolyline(encoded: string): [number, number][] {
  const points: [number, number][] = [];
  let index = 0;
  let lat = 0;
  let lng = 0;

  while (index < encoded.length) {
    let shift = 0;
    let result = 0;
    let byte: number;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lat += result & 1 ? ~(result >> 1) : result >> 1;

    shift = 0;
    result = 0;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lng += result & 1 ? ~(result >> 1) : result >> 1;

    points.push([lat / 1e5, lng / 1e5]);
  }
  return points;
}

async function queryDigitransit(graphql: string): Promise<any> {
  const res = await fetch(DIGITRANSIT_ROUTING_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'digitransit-subscription-key': DIGITRANSIT_API_KEY,
    },
    body: JSON.stringify({ query: graphql }),
  });

  if (!res.ok) return null;
  return res.json();
}

async function getDrivingRoute(
  fromLat: number,
  fromLon: number,
  toLat: number,
  toLon: number,
): Promise<{ durationMinutes: number; distanceKm: number; geometry: [number, number][] } | null> {
  const query = `{
    plan(
      from: { lat: ${fromLat}, lon: ${fromLon} }
      to: { lat: ${toLat}, lon: ${toLon} }
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
  }`;

  const data = await queryDigitransit(query);
  const itinerary = data?.data?.plan?.itineraries?.[0];
  if (!itinerary) return null;

  const totalDistance = itinerary.legs.reduce(
    (sum: number, leg: any) => sum + leg.distance,
    0,
  );

  const geometry: [number, number][] = itinerary.legs.flatMap((leg: any) =>
    leg.legGeometry?.points ? decodePolyline(leg.legGeometry.points) : [],
  );

  return {
    durationMinutes: Math.round(itinerary.duration / 60),
    distanceKm: Math.round(totalDistance / 100) / 10,
    geometry,
  };
}

interface TransitRouteResult {
  durationMinutes: number;
  legs: {
    mode: string;
    routeShortName?: string;
    from: string;
    to: string;
    durationMinutes: number;
    distanceKm: number;
    geometry: [number, number][];
  }[];
}

async function getTransitRoute(
  fromLat: number,
  fromLon: number,
  toLat: number,
  toLon: number,
  walkSpeed: number = 1.39,
): Promise<TransitRouteResult | null> {
  const query = `{
    plan(
      from: { lat: ${fromLat}, lon: ${fromLon} }
      to: { lat: ${toLat}, lon: ${toLon} }
      numItineraries: 3
      walkSpeed: ${walkSpeed}
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
  }`;

  const data = await queryDigitransit(query);
  const itinerary = data?.data?.plan?.itineraries?.[0];
  if (!itinerary) return null;

  return {
    durationMinutes: Math.round(itinerary.duration / 60),
    legs: itinerary.legs.map((leg: any) => ({
      mode: leg.mode,
      routeShortName: leg.route?.shortName,
      from: leg.from.name,
      to: leg.to.name,
      durationMinutes: Math.round(leg.duration / 60),
      distanceKm: Math.round(leg.distance / 100) / 10,
      geometry: leg.legGeometry?.points ? decodePolyline(leg.legGeometry.points) : [],
    })),
  };
}

// --- Mode mapping ---

function mapTransitMode(apiMode: string): TransitMode {
  switch (apiMode) {
    case 'CAR': return 'drive';
    case 'SUBWAY': return 'metro';
    case 'BUS': return 'bus';
    case 'TRAM': return 'tram';
    case 'RAIL': return 'rail';
    case 'FERRY': return 'ferry';
    case 'WALK': return 'walk';
    default: return 'walk';
  }
}

// --- Main route search orchestrator ---

function haversineDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Search for routes from origin to destination via P+R facilities.
 * Fetches real P+R facilities, calculates driving + transit for each,
 * and returns ranked results.
 */
export async function searchRoutes(
  originLat: number,
  originLon: number,
  destLat: number,
  destLon: number,
  walkingSpeed: 'slow' | 'normal' | 'fast' = 'normal',
): Promise<Route[]> {
  // 1. Fetch all P+R facilities
  const allFacilities = await fetchParkAndRideFacilities();

  // 2. Filter facilities: must be within ~100km of origin and "on the way"
  //    (distance to dest must be less than total origin-dest distance).
  //    Sort by detour distance (least extra distance first), take top 20.
  const originDestDistance = haversineDistance(originLat, originLon, destLat, destLon);
  const MAX_DISTANCE_KM = 100; // ~1 degree

  const nearbyFacilities = allFacilities
    .map((f) => {
      const distFromOrigin = haversineDistance(originLat, originLon, f.latitude, f.longitude);
      const distFromDest = haversineDistance(destLat, destLon, f.latitude, f.longitude);
      const detour = distFromOrigin + distFromDest - originDestDistance;
      return { ...f, distFromOrigin, distFromDest, detour };
    })
    .filter((f) => f.distFromOrigin < MAX_DISTANCE_KM && f.distFromDest < originDestDistance)
    .sort((a, b) => a.detour - b.detour)
    .slice(0, 20);

  if (nearbyFacilities.length === 0) return [];

  // 3. For each facility, calculate driving + transit routes in parallel
  const walkSpeedMs = WALK_SPEEDS[walkingSpeed] ?? 1.39;

  const routePromises = nearbyFacilities.map(async (facility): Promise<Route | null> => {
    const [driving, transit] = await Promise.all([
      getDrivingRoute(originLat, originLon, facility.latitude, facility.longitude),
      getTransitRoute(facility.latitude, facility.longitude, destLat, destLon, walkSpeedMs),
    ]);

    if (!driving || !transit) return null;

    const totalMinutes = driving.durationMinutes + transit.durationMinutes;
    const now = new Date();
    const departure = now.toISOString();
    const arrival = new Date(now.getTime() + totalMinutes * 60000).toISOString();

    // Find the first walk leg to the transit stop to estimate walkToStationMinutes
    const firstWalkLeg = transit.legs.find((l) => l.mode === 'WALK');
    const walkToStationMinutes = firstWalkLeg?.durationMinutes ?? 3;

    const parking: ParkingFacility = {
      id: String(facility.id),
      name: facility.name,
      available: facility.available ?? 0,
      capacity: facility.capacity,
      availability: getAvailabilityLevel(facility.available ?? 0, facility.capacity),
      latitude: facility.latitude,
      longitude: facility.longitude,
      walkToStationMinutes,
    };

    // Build legs: drive → park → transit legs
    const legs: RouteLeg[] = [];

    // Drive leg
    legs.push({
      mode: 'drive',
      from: 'Lähtöpaikka',
      to: facility.name,
      durationMinutes: driving.durationMinutes,
      distanceKm: driving.distanceKm,
      geometry: driving.geometry,
    });

    // Park leg
    legs.push({
      mode: 'park',
      from: facility.name,
      to: facility.name,
      durationMinutes: walkToStationMinutes,
      distanceKm: 0,
      parking,
    });

    // Transit + walk legs
    for (const tLeg of transit.legs) {
      legs.push({
        mode: mapTransitMode(tLeg.mode),
        from: tLeg.from,
        to: tLeg.to,
        durationMinutes: tLeg.durationMinutes,
        distanceKm: tLeg.distanceKm,
        lineName: tLeg.routeShortName,
        geometry: tLeg.geometry,
      });
    }

    return {
      id: `route-${facility.id}`,
      totalMinutes,
      departureTime: departure,
      arrivalTime: arrival,
      legs,
      parking,
    };
  });

  const results = await Promise.all(routePromises);

  // 4. Filter: only keep routes with up to 2 non-walking transit legs (max 1 transfer)
  const validRoutes = results.filter((r): r is Route => {
    if (!r) return false;
    const transitLegs = r.legs.filter(
      (l) => l.mode !== 'drive' && l.mode !== 'park' && l.mode !== 'walk',
    );
    return transitLegs.length >= 1 && transitLegs.length <= 2;
  });

  // 5. Sort by total time with metro bonus (metro routes get 10-min advantage)
  const METRO_BONUS = 10;
  return validRoutes.sort((a, b) => {
    const hasMetroA = a.legs.some((l) => l.mode === 'metro');
    const hasMetroB = b.legs.some((l) => l.mode === 'metro');
    const effectiveA = a.totalMinutes - (hasMetroA ? METRO_BONUS : 0);
    const effectiveB = b.totalMinutes - (hasMetroB ? METRO_BONUS : 0);
    return effectiveA - effectiveB;
  });
}
