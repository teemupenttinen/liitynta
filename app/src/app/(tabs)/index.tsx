import { useRef, useCallback, useMemo, useState, useEffect } from 'react';
import {
  View,
  StyleSheet,
  Text,
  ActivityIndicator,
  Pressable,
  Keyboard,
  ScrollView,
  useWindowDimensions,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from 'react-native-reanimated';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { Heart, ChevronsUp, ChevronsDown, ArrowRight } from 'lucide-react-native';
import { useRouter } from 'expo-router';
import { colors, spacing, radii } from '@/lib/theme';
import { useAppStore } from '@/lib/store';
import { RouteCard } from '@/components/RouteCard';
import { AutocompleteInput } from '@/components/AutocompleteInput';
import { MapView, Marker, Polyline } from '@/components/Map';
import { geocode, searchRoutes, type GeocodeSuggestion } from '@/lib/digitransit';
import * as Location from 'expo-location';
import type { TransitMode } from '@/types/route';

/** Helsinki region default */
const INITIAL_REGION = {
  latitude: 60.21,
  longitude: 25.0,
  latitudeDelta: 0.15,
  longitudeDelta: 0.15,
};

/** Polyline colors per transport mode */
const MODE_LINE_COLORS: Record<TransitMode, string> = {
  drive: '#0047b3',
  park: '#0047b3',
  metro: '#FF6319',
  bus: '#0078D4',
  tram: '#00A651',
  rail: '#8B5CF6',
  ferry: '#06B6D4',
  walk: '#9CA3AF',
};

const HANDLE_HEIGHT = 24;
const SPRING_CONFIG = { damping: 50, stiffness: 400, overshootClamping: true };

export default function MapScreen() {
  const router = useRouter();
  const mapRef = useRef<any>(null);
  const { height: screenHeight } = useWindowDimensions();
  const {
    origin,
    destination,
    routes,
    setOrigin,
    setDestination,
    setRoutes,
    setIsSearching,
    isSearching,
    selectRoute,
    walkingSpeed,
    addCommutePair,
    commutePairs,
    showOnlyAvailable,
  } = useAppStore();

  const [isExpanded, setIsExpanded] = useState(false);

  // Sheet heights
  const collapsedHeight = 185;
  const expandedHeight = screenHeight - 300; // leave space for search area + status bar

  // Animate translateY instead of height so content is always laid out
  // and the sheet slides up as a unit (no "pop-in" effect).
  const collapsedTranslateY = expandedHeight - collapsedHeight;
  const sheetTranslateY = useSharedValue(collapsedTranslateY);
  const startTranslateY = useSharedValue(collapsedTranslateY);

  const panGesture = Gesture.Pan()
    .onStart(() => {
      startTranslateY.value = sheetTranslateY.value;
    })
    .onUpdate((e) => {
      const newY = startTranslateY.value + e.translationY;
      sheetTranslateY.value = Math.max(
        0,
        Math.min(collapsedTranslateY, newY),
      );
    })
    .onEnd((e) => {
      const mid = collapsedTranslateY / 2;
      if (sheetTranslateY.value < mid || e.velocityY < -500) {
        sheetTranslateY.value = withSpring(0, SPRING_CONFIG);
        setIsExpanded(true);
      } else {
        sheetTranslateY.value = withSpring(collapsedTranslateY, SPRING_CONFIG);
        setIsExpanded(false);
      }
    })
    .runOnJS(true);

  const animatedSheetStyle = useAnimatedStyle(() => ({
    height: expandedHeight,
    transform: [{ translateY: sheetTranslateY.value }],
  }));

  const snapToCollapsed = useCallback(() => {
    sheetTranslateY.value = withSpring(collapsedTranslateY, SPRING_CONFIG);
    setIsExpanded(false);
  }, [collapsedTranslateY, sheetTranslateY]);

  const snapToExpanded = useCallback(() => {
    sheetTranslateY.value = withSpring(0, SPRING_CONFIG);
    setIsExpanded(true);
  }, [sheetTranslateY]);

  const [originCoords, setOriginCoords] = useState<{ lat: number; lon: number } | null>(null);
  const [destCoords, setDestCoords] = useState<{ lat: number; lon: number } | null>(null);
  const [userLocation, setUserLocation] = useState<{ lat: number; lon: number } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [hasSearched, setHasSearched] = useState(false);
  const [selectedRouteId, setSelectedRouteId] = useState<string | null>(null);

  // Filter routes: hide those with 0 available spots when setting is on
  const visibleRoutes = useMemo(() => {
    if (!showOnlyAvailable) return routes;
    return routes.filter((r) => r.parking.available > 0);
  }, [routes, showOnlyAvailable]);

  // The selected route (first visible route by default after search)
  const selectedRoute = useMemo(() => {
    if (!selectedRouteId) return visibleRoutes[0] ?? null;
    return visibleRoutes.find((r) => r.id === selectedRouteId) ?? visibleRoutes[0] ?? null;
  }, [visibleRoutes, selectedRouteId]);

  // Derive P+R markers from visible routes
  const prMarkers = useMemo(() => {
    const selId = selectedRoute?.id;
    return visibleRoutes.map((r) => ({
      id: r.parking.id,
      routeId: r.id,
      name: r.parking.name,
      latitude: r.parking.latitude,
      longitude: r.parking.longitude,
      available: r.parking.available,
      capacity: r.parking.capacity,
      availability: r.parking.availability,
      isSelected: r.id === selId,
    }));
  }, [visibleRoutes, selectedRoute]);

  // Precompute polyline data
  const polylines = useMemo(() => {
    if (!selectedRoute) return [];
    let idx = 0;
    return selectedRoute.legs
      .filter((leg) => leg.geometry && leg.geometry.length >= 2 && leg.mode !== 'park')
      .map((leg) => ({
        key: `pl-${idx++}`,
        coordinates: leg.geometry!.map(([lat, lon]) => ({
          latitude: lat,
          longitude: lon,
        })),
        strokeColor: MODE_LINE_COLORS[leg.mode],
        strokeWidth: leg.mode === 'walk' ? 3 : 5,
        lineDashPattern: leg.mode === 'walk' ? [1, 6] as number[] : undefined,
      }));
  }, [selectedRoute]);

  const isFavourited = useMemo(() => {
    return commutePairs.some(
      (p) => p.origin === origin && p.destination === destination,
    );
  }, [commutePairs, origin, destination]);

  const handleOriginSelect = useCallback(
    (s: GeocodeSuggestion) => {
      setOriginCoords({ lat: s.lat, lon: s.lon });
    },
    [],
  );

  const handleDestSelect = useCallback(
    (s: GeocodeSuggestion) => {
      setDestCoords({ lat: s.lat, lon: s.lon });
    },
    [],
  );

  const handleRequestLocation = useCallback(async () => {
    const { status } = await Location.requestForegroundPermissionsAsync();
    if (status !== 'granted') return;

    const loc = await Location.getCurrentPositionAsync({
      accuracy: Location.Accuracy.Balanced,
    });

    const coords = { lat: loc.coords.latitude, lon: loc.coords.longitude };
    setOriginCoords(coords);
    setUserLocation(coords);

    const [address] = await Location.reverseGeocodeAsync({
      latitude: coords.lat,
      longitude: coords.lon,
    });
    if (address) {
      const label = [address.street, address.streetNumber, address.city]
        .filter(Boolean)
        .join(' ');
      setOrigin(label || 'Oma sijainti');
    } else {
      setOrigin('Oma sijainti');
    }
  }, [setOrigin]);

  const handleSearch = useCallback(async () => {
    Keyboard.dismiss();

    let origLat = originCoords?.lat;
    let origLon = originCoords?.lon;
    let destLat = destCoords?.lat;
    let destLon = destCoords?.lon;

    if (!origLat || !destLat) {
      if (!origin.trim() || !destination.trim()) return;

      setError(null);
      setIsSearching(true);
      setRoutes([]);

      try {
        const [originResults, destResults] = await Promise.all([
          origLat ? Promise.resolve([]) : geocode(origin),
          destLat ? Promise.resolve([]) : geocode(destination),
        ]);

        if (!origLat && originResults.length > 0) {
          origLat = originResults[0].lat;
          origLon = originResults[0].lon;
          setOriginCoords({ lat: origLat, lon: origLon });
        }
        if (!destLat && destResults.length > 0) {
          destLat = destResults[0].lat;
          destLon = destResults[0].lon;
          setDestCoords({ lat: destLat, lon: destLon });
        }

        if (!origLat || !origLon || !destLat || !destLon) {
          setError('Osoitetta ei löytynyt. Tarkista hakusanat.');
          setIsSearching(false);
          return;
        }
      } catch {
        setError('Osoitteen haku epäonnistui.');
        setIsSearching(false);
        return;
      }
    } else {
      setError(null);
      setIsSearching(true);
      setRoutes([]);
    }

    try {
      const foundRoutes = await searchRoutes(
        origLat!,
        origLon!,
        destLat!,
        destLon!,
        walkingSpeed,
      );

      setRoutes(foundRoutes);
      setHasSearched(true);
      setSelectedRouteId(foundRoutes[0]?.id ?? null);

      if (foundRoutes.length > 0) {
        snapToCollapsed();

        const allCoords = [
          { latitude: origLat!, longitude: origLon! },
          { latitude: destLat!, longitude: destLon! },
          ...foundRoutes.map((r) => ({
            latitude: r.parking.latitude,
            longitude: r.parking.longitude,
          })),
        ];
        mapRef.current?.fitToCoordinates(allCoords, {
          edgePadding: { top: 140, right: 40, bottom: 280, left: 40 },
          animated: true,
        });
      } else {
        setError('Reittejä ei löytynyt. Kokeile eri osoitteita.');
      }
    } catch {
      setError('Reittihaku epäonnistui. Yritä uudelleen.');
    } finally {
      setIsSearching(false);
    }
  }, [origin, destination, originCoords, destCoords, walkingSpeed, setIsSearching, setRoutes, snapToCollapsed]);

  // Auto-search when both coordinates are set (from autocomplete or location)
  const lastSearchKey = useRef('');
  useEffect(() => {
    if (originCoords && destCoords && !isSearching) {
      const key = `${originCoords.lat},${originCoords.lon}-${destCoords.lat},${destCoords.lon}`;
      if (lastSearchKey.current === key) return;
      lastSearchKey.current = key;
      handleSearch();
    }
  }, [originCoords, destCoords]);

  const handleSelectRoute = useCallback(
    (routeId: string) => {
      setSelectedRouteId(routeId);
      const route = visibleRoutes.find((r) => r.id === routeId);
      if (route) selectRoute(route);
    },
    [visibleRoutes, selectRoute],
  );

  const handleOpenRouteDetail = useCallback(
    (routeId: string) => {
      const route = visibleRoutes.find((r) => r.id === routeId);
      if (route) selectRoute(route);
      router.push(`/route-detail?id=${routeId}`);
    },
    [router, visibleRoutes, selectRoute],
  );

  const handleToggleFavourite = useCallback(() => {
    if (!origin.trim() || !destination.trim()) return;
    if (!isFavourited) {
      addCommutePair({
        id: `${Date.now()}`,
        origin: origin.trim(),
        destination: destination.trim(),
        createdAt: new Date().toISOString(),
      });
    }
  }, [origin, destination, isFavourited, addCommutePair]);

  const getAvailColor = (availability: string) => {
    if (availability === 'high') return colors.availHigh;
    if (availability === 'medium') return colors.availMedium;
    return colors.availLow;
  };

  const hasResults = hasSearched && visibleRoutes.length > 0;
  const otherRouteCount = Math.max(0, visibleRoutes.length - 1);
  const showSheet = hasResults || isSearching || error;

  return (
    <View style={styles.container}>
      <MapView ref={mapRef} style={styles.map} initialRegion={INITIAL_REGION}>
        {/* Route polylines for selected route */}
        {hasSearched &&
          polylines.map((pl) => (
            <Polyline
              key={pl.key}
              coordinates={pl.coordinates}
              strokeColor={pl.strokeColor}
              strokeWidth={pl.strokeWidth}
              lineDashPattern={pl.lineDashPattern}
            />
          ))}

        {/* Origin marker */}
        {hasSearched && originCoords && (
          <Marker
            coordinate={{
              latitude: originCoords.lat,
              longitude: originCoords.lon,
            }}
            anchor={{ x: 0.5, y: 0.5 }}
          >
            <View style={styles.originMarker}>
              <View style={styles.originDot} />
            </View>
          </Marker>
        )}

        {/* Destination marker */}
        {hasSearched && destCoords && (
          <Marker
            coordinate={{
              latitude: destCoords.lat,
              longitude: destCoords.lon,
            }}
            anchor={{ x: 0.5, y: 0.5 }}
          >
            <View style={styles.destMarker}>
              <View style={styles.destDot} />
            </View>
          </Marker>
        )}

        {/* P+R markers — only shown after search */}
        {hasSearched &&
          prMarkers.map((marker) => (
            <Marker
              key={marker.id}
              coordinate={{
                latitude: marker.latitude,
                longitude: marker.longitude,
              }}
              anchor={{ x: 0.5, y: 1 }}
              onPress={() => handleSelectRoute(marker.routeId)}
              zIndex={marker.isSelected ? 10 : 1}
            >
              <View
                style={[
                  styles.pinContainer,
                  !marker.isSelected && styles.pinUnselected,
                ]}
              >
                <View
                  style={[
                    marker.isSelected ? styles.pinBgSelected : styles.pinBg,
                    {
                      backgroundColor: marker.isSelected
                        ? colors.primary
                        : getAvailColor(marker.availability),
                    },
                  ]}
                >
                  <Text style={styles.pinIcon}>P</Text>
                </View>
                <View
                  style={[
                    styles.pinTriangle,
                    {
                      borderTopColor: marker.isSelected
                        ? colors.primary
                        : getAvailColor(marker.availability),
                    },
                  ]}
                />
                <View
                  style={[
                    styles.pinLabel,
                    {
                      backgroundColor: marker.isSelected
                        ? colors.primary
                        : colors.bgWhite,
                    },
                  ]}
                >
                  <View
                    style={[
                      styles.pinLabelDot,
                      { backgroundColor: getAvailColor(marker.availability) },
                    ]}
                  />
                  <Text
                    style={[
                      styles.pinLabelText,
                      {
                        color: marker.isSelected
                          ? colors.textWhite
                          : colors.textPrimary,
                      },
                    ]}
                  >
                    {marker.available}
                  </Text>
                </View>
              </View>
            </Marker>
          ))}
      </MapView>

      {/* Search fields overlay */}
      <View style={styles.searchOverlay}>
        <View style={{ zIndex: 2 }}>
          <AutocompleteInput
            value={origin}
            onChangeText={setOrigin}
            onSelect={handleOriginSelect}
            placeholder="Lähtöpaikka"
            variant="origin"
            onSubmitEditing={handleSearch}
            onRequestLocation={handleRequestLocation}
            focusPoint={userLocation ?? undefined}
          />
        </View>
        <View style={{ zIndex: 1 }}>
          <AutocompleteInput
            value={destination}
            onChangeText={setDestination}
            onSelect={handleDestSelect}
            placeholder="Määränpää"
            variant="destination"
            onSubmitEditing={handleSearch}
            focusPoint={userLocation ?? undefined}
          />
        </View>
      </View>

      {/* Bottom Sheet */}
      {showSheet && (
        <Animated.View
          style={[
            styles.sheet,
            { bottom: 0 },
            animatedSheetStyle,
          ]}
        >
          {/* Drag handle */}
          <GestureDetector gesture={panGesture}>
            <View style={styles.handleArea}>
              <View style={styles.handleIndicator} />
            </View>
          </GestureDetector>

          {hasResults ? (
            <>
              <View style={styles.summaryRow}>
                <View style={styles.summaryLeft}>
                  <Text style={styles.summaryCity}>{origin.split(',')[0]}</Text>
                  <ArrowRight size={14} color={colors.textMuted} />
                  <Text style={styles.summaryCity}>{destination.split(',')[0]}</Text>
                </View>
                <Pressable style={styles.summaryRight} onPress={handleToggleFavourite}>
                  <Heart
                    size={16}
                    color={colors.availLow}
                    fill={isFavourited ? colors.availLow : 'none'}
                  />
                  <Text style={styles.favText}>Suosikki</Text>
                </Pressable>
              </View>

              {/* Toggle hint */}
              <Pressable style={styles.peekHint} onPress={isExpanded ? snapToCollapsed : snapToExpanded}>
                {isExpanded ? (
                  <>
                    <ChevronsDown size={16} color={colors.textMuted} />
                    <Text style={styles.peekText}>Pienennä</Text>
                  </>
                ) : otherRouteCount > 0 ? (
                  <>
                    <ChevronsUp size={16} color={colors.textMuted} />
                    <Text style={styles.peekText}>
                      {otherRouteCount} muuta tulosta
                    </Text>
                  </>
                ) : null}
              </Pressable>

              <ScrollView
                style={styles.cardsScroll}
                contentContainerStyle={styles.cardsContent}
                showsVerticalScrollIndicator={false}
                scrollEnabled={isExpanded}
              >
                {visibleRoutes.map((route, index) => (
                  <View key={route.id} style={index > 0 ? { marginTop: 10 } : undefined}>
                    <RouteCard
                      route={route}
                      onPress={() => handleSelectRoute(route.id)}
                      onLongPress={() => handleOpenRouteDetail(route.id)}
                      isBest={index === 0}
                      isSelected={route.id === selectedRoute?.id}
                    />
                  </View>
                ))}
              </ScrollView>
            </>
          ) : (
            <View style={styles.emptyContent}>
              {isSearching && (
                <View style={styles.loadingContainer}>
                  <ActivityIndicator size="large" color={colors.primary} />
                  <Text style={styles.loadingText}>Haetaan reittejä...</Text>
                </View>
              )}
              {error && <Text style={styles.errorText}>{error}</Text>}
            </View>
          )}
        </Animated.View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  map: { flex: 1 },

  // Search overlay
  searchOverlay: {
    position: 'absolute',
    top: 60,
    left: spacing.lg,
    right: spacing.lg,
    gap: spacing.sm,
    zIndex: 10,
  },

  // Map markers
  originMarker: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  originDot: {
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: colors.primary,
    borderWidth: 3,
    borderColor: colors.bgWhite,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.12,
    shadowRadius: 4,
    elevation: 4,
  },
  destMarker: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  destDot: {
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: colors.availLow,
    borderWidth: 3,
    borderColor: colors.bgWhite,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.12,
    shadowRadius: 4,
    elevation: 4,
  },

  // P+R pin markers
  pinContainer: {
    alignItems: 'center',
  },
  pinUnselected: {
    opacity: 0.55,
  },
  pinBg: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: colors.bgWhite,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.18,
    shadowRadius: 6,
    elevation: 4,
  },
  pinBgSelected: {
    width: 54,
    height: 54,
    borderRadius: 27,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 3,
    borderColor: colors.bgWhite,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.25,
    shadowRadius: 10,
    elevation: 6,
  },
  pinIcon: {
    fontSize: 18,
    fontWeight: '800',
    color: colors.textWhite,
  },
  pinTriangle: {
    width: 0,
    height: 0,
    borderLeftWidth: 6,
    borderRightWidth: 6,
    borderTopWidth: 8,
    borderLeftColor: 'transparent',
    borderRightColor: 'transparent',
    marginTop: -2,
  },
  pinLabel: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    borderRadius: 10,
    paddingVertical: 3,
    paddingHorizontal: 8,
    marginTop: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.12,
    shadowRadius: 4,
    elevation: 2,
  },
  pinLabelDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  pinLabelText: {
    fontSize: 11,
    fontWeight: '700',
  },

  // Bottom sheet
  sheet: {
    position: 'absolute',
    left: 0,
    right: 0,
    backgroundColor: colors.bgWhite,
    borderTopLeftRadius: radii.xl,
    borderTopRightRadius: radii.xl,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -3 },
    shadowOpacity: 0.12,
    shadowRadius: 8,
    elevation: 8,
  },
  handleArea: {
    alignItems: 'center',
    justifyContent: 'center',
    height: HANDLE_HEIGHT,
    paddingVertical: 8,
  },
  handleIndicator: {
    backgroundColor: colors.border,
    width: 40,
    height: 4,
    borderRadius: 2,
  },

  // Summary row
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 4,
    paddingBottom: 8,
  },
  summaryLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  summaryCity: {
    fontSize: 13,
    fontWeight: '500',
    color: colors.textSecondary,
  },
  summaryRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  favText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.primary,
  },

  // Collapsed: single card
  collapsedCard: {
    paddingHorizontal: spacing.lg,
    paddingTop: 4,
    paddingBottom: 4,
  },

  // Expanded: scrollable cards
  cardsScroll: {
    flex: 1,
  },
  cardsContent: {
    paddingHorizontal: spacing.lg,
    paddingTop: 4,
    paddingBottom: spacing.lg,
  },

  // Peek hint
  peekHint: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingTop: 4,
    paddingBottom: 0,
    paddingHorizontal: spacing.lg,
  },
  peekText: {
    fontSize: 12,
    fontWeight: '500',
    color: colors.textMuted,
  },

  // Empty state
  emptyContent: {
    padding: spacing.lg,
  },
  loadingContainer: {
    alignItems: 'center',
    gap: spacing.md,
    paddingVertical: spacing.xl,
  },
  loadingText: {
    color: colors.textSecondary,
    fontSize: 14,
  },
  errorText: {
    color: colors.availLow,
    fontSize: 14,
    textAlign: 'center',
    paddingVertical: spacing.md,
  },
});
