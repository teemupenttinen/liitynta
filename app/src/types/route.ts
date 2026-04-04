export type TransitMode = 'drive' | 'park' | 'metro' | 'bus' | 'tram' | 'rail' | 'ferry' | 'walk';

export type AvailabilityLevel = 'high' | 'medium' | 'low';

export interface ParkingFacility {
  id: string;
  name: string;
  available: number;
  capacity: number;
  availability: AvailabilityLevel;
  latitude: number;
  longitude: number;
  walkToStationMinutes: number;
}

export interface RouteLeg {
  mode: TransitMode;
  from: string;
  to: string;
  durationMinutes: number;
  distanceKm: number;
  /** Transit line name, e.g. "M1" */
  lineName?: string;
  /** Full line description, e.g. "Vuosaari → Ruoholahti" */
  lineDescription?: string;
  /** Parking facility details (only for 'park' legs) */
  parking?: ParkingFacility;
  /** Polyline geometry for drawing on map: [lat, lon][] */
  geometry?: [number, number][];
}

export interface Route {
  id: string;
  totalMinutes: number;
  departureTime: string;
  arrivalTime: string;
  legs: RouteLeg[];
  parking: ParkingFacility;
}

export interface CommutePair {
  id: string;
  origin: string;
  destination: string;
  createdAt: string;
}

export interface FavouriteParkingSpot {
  id: string;
  facilityId: string;
  name: string;
}
