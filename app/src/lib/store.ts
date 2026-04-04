import { create } from 'zustand';
import type { Route, CommutePair, FavouriteParkingSpot } from '@/types/route';

interface AppState {
  // Search
  origin: string;
  destination: string;
  routes: Route[];
  selectedRoute: Route | null;
  isSearching: boolean;

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
  commutePairs: [],
  favouriteParkingSpots: [],
  walkingSpeed: 'normal',
  showOnlyAvailable: false,

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
