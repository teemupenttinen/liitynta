import { create } from 'zustand';
import type { Route, CommutePair, FavouriteParkingSpot, AvailabilityLevel } from '@/types/route';

export interface Facility {
  id: number;
  name: string;
  latitude: number;
  longitude: number;
  capacity: number;
  available?: number;
  availability: AvailabilityLevel;
}

interface AppState {
  // Search
  origin: string;
  destination: string;
  routes: Route[];
  selectedRoute: Route | null;
  isSearching: boolean;

  // Facilities (shared across screens)
  facilities: Facility[];
  setFacilities: (facilities: Facility[]) => void;

  // Favourites
  commutePairs: CommutePair[];
  favouriteParkingSpots: FavouriteParkingSpot[];

  // Settings
  walkingSpeed: 'slow' | 'normal' | 'fast';
  showOnlyAvailable: boolean;

  // Actions
  setOrigin: (origin: string) => void;
  setDestination: (destination: string) => void;
  setRoutes: (routes: Route[]) => void;
  selectRoute: (route: Route | null) => void;
  setIsSearching: (searching: boolean) => void;
  addCommutePair: (pair: CommutePair) => void;
  removeCommutePair: (id: string) => void;
  addFavouriteParkingSpot: (spot: FavouriteParkingSpot) => void;
  removeFavouriteParkingSpot: (id: string) => void;
  setWalkingSpeed: (speed: 'slow' | 'normal' | 'fast') => void;
  setShowOnlyAvailable: (show: boolean) => void;
}

export const useAppStore = create<AppState>((set) => ({
  origin: '',
  destination: '',
  routes: [],
  selectedRoute: null,
  isSearching: false,
  facilities: [],
  setFacilities: (facilities) => set({ facilities }),
  commutePairs: [],
  favouriteParkingSpots: [],
  walkingSpeed: 'normal',
  showOnlyAvailable: true,

  setOrigin: (origin) => set({ origin }),
  setDestination: (destination) => set({ destination }),
  setRoutes: (routes) => set({ routes }),
  selectRoute: (route) => set({ selectedRoute: route }),
  setIsSearching: (isSearching) => set({ isSearching }),

  addCommutePair: (pair) =>
    set((state) => ({ commutePairs: [...state.commutePairs, pair] })),
  removeCommutePair: (id) =>
    set((state) => ({
      commutePairs: state.commutePairs.filter((p) => p.id !== id),
    })),

  addFavouriteParkingSpot: (spot) =>
    set((state) => ({
      favouriteParkingSpots: [...state.favouriteParkingSpots, spot],
    })),
  removeFavouriteParkingSpot: (id) =>
    set((state) => ({
      favouriteParkingSpots: state.favouriteParkingSpots.filter((s) => s.id !== id),
    })),

  setWalkingSpeed: (walkingSpeed) => set({ walkingSpeed }),
  setShowOnlyAvailable: (showOnlyAvailable) => set({ showOnlyAvailable }),
}));
