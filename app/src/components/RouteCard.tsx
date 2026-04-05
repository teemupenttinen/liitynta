import { View, Text, StyleSheet, Pressable } from 'react-native';
import { Car, TrainFront, Bus, Footprints, TramFront, Ship, Heart } from 'lucide-react-native';
import { colors, spacing, radii } from '@/lib/theme';
import { useAppStore } from '@/lib/store';
import type { Route, TransitMode } from '@/types/route';

const MODE_COLORS: Record<TransitMode, string> = {
  drive: colors.driveBlue,
  park: colors.primary,
  metro: colors.metroOrange,
  bus: colors.busBlue,
  tram: colors.tramGreen,
  rail: colors.railPurple,
  ferry: colors.ferryCyan,
  walk: colors.walkGray,
};

const MODE_ICONS: Partial<Record<TransitMode, typeof Car>> = {
  drive: Car,
  metro: TrainFront,
  bus: Bus,
  tram: TramFront,
  rail: TrainFront,
  ferry: Ship,
  walk: Footprints,
};

const MODE_LABELS: Partial<Record<TransitMode, string>> = {
  metro: 'M Metro',
  bus: 'Bussi',
  tram: 'Ratikka',
  rail: 'Juna',
  ferry: 'Lautta',
};

interface RouteCardProps {
  route: Route;
  onPress: () => void;
  onLongPress?: () => void;
  isBest?: boolean;
  isSelected?: boolean;
}

export function RouteCard({ route, onPress, onLongPress, isBest, isSelected }: RouteCardProps) {
  const { favouriteParkingSpots, addFavouriteParkingSpot, removeFavouriteParkingSpot } = useAppStore();
  const isFavouriteSpot = favouriteParkingSpots.some((s) => s.facilityId === route.parking.id);
  const hasAvailability = route.parking.availability != null;
  const availColor = !hasAvailability
    ? colors.availNeutral
    : route.parking.availability === 'high'
      ? colors.availHigh
      : route.parking.availability === 'medium'
        ? colors.availMedium
        : colors.availLow;

  // Find driving and main transit legs for the summary
  const driveLeg = route.legs.find((l) => l.mode === 'drive');
  const transitLeg = route.legs.find(
    (l) => l.mode !== 'drive' && l.mode !== 'park' && l.mode !== 'walk',
  );

  return (
    <Pressable
      style={[
        styles.card,
        isSelected && styles.cardSelected,
      ]}
      onPress={onPress}
      onLongPress={onLongPress}
    >
      {/* Availability sidebar */}
      <View style={[styles.availSidebar, { backgroundColor: availColor }]}>
        <Text style={styles.availCount}>
          {hasAvailability ? route.parking.available : route.parking.capacity}
        </Text>
        {hasAvailability && (
          <Text style={styles.availCapacity}>/{route.parking.capacity}</Text>
        )}
        <Text style={styles.availLabel}>
          {hasAvailability ? 'vapaana' : 'paikkaa'}
        </Text>
      </View>

      {/* Content */}
      <View style={styles.content}>
        {/* Top row: facility name + total time */}
        <View style={styles.topRow}>
          <Text style={styles.facilityName} numberOfLines={1}>
            {route.parking.name}
          </Text>
          <Text style={styles.totalTime}>{route.totalMinutes} min</Text>
        </View>

        {/* Middle row: mode icons with durations */}
        <View style={styles.modesRow}>
          {driveLeg && (
            <>
              <Car size={12} color={colors.textSecondary} />
              <Text style={styles.modeText}>
                {driveLeg.durationMinutes} min · {driveLeg.distanceKm} km
              </Text>
            </>
          )}
          {transitLeg && (
            <>
              {MODE_ICONS[transitLeg.mode] &&
                (() => {
                  const Icon = MODE_ICONS[transitLeg.mode]!;
                  return (
                    <Icon
                      size={12}
                      color={MODE_COLORS[transitLeg.mode]}
                    />
                  );
                })()}
              <Text style={styles.modeText}>
                {transitLeg.durationMinutes} min
              </Text>
            </>
          )}
        </View>

        {/* Bottom row: badges + favourite heart */}
        <View style={styles.badgeRow}>
          <View style={styles.badges}>
            {isBest && (
              <View style={[styles.badge, { backgroundColor: colors.primary }]}>
                <Text style={styles.badgeText}>NOPEIN</Text>
              </View>
            )}
            {transitLeg && (
              <View
                style={[
                  styles.badge,
                  { backgroundColor: MODE_COLORS[transitLeg.mode] },
                ]}
              >
                <Text style={styles.badgeText}>
                  {transitLeg.lineName
                    ? `${transitLeg.lineName} ${MODE_LABELS[transitLeg.mode] ?? ''}`
                        .trim()
                    : MODE_LABELS[transitLeg.mode] ?? transitLeg.mode}
                </Text>
              </View>
            )}
          </View>
          <Pressable
            onPress={() => {
              if (isFavouriteSpot) {
                removeFavouriteParkingSpot(route.parking.id);
              } else {
                addFavouriteParkingSpot({
                  id: route.parking.id,
                  facilityId: route.parking.id,
                  name: route.parking.name,
                });
              }
            }}
            hitSlop={8}
          >
            <Heart
              size={16}
              color={isFavouriteSpot ? colors.availLow : colors.textMuted}
              fill={isFavouriteSpot ? colors.availLow : 'none'}
            />
          </Pressable>
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    backgroundColor: colors.bg,
    borderRadius: 14,
    overflow: 'hidden',
    borderWidth: 2,
    borderColor: colors.borderLight,
  },
  cardSelected: {
    borderColor: colors.primary,
    shadowColor: colors.primary,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 4,
  },
  availSidebar: {
    width: 72,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2,
    paddingVertical: 10,
    paddingHorizontal: 6,
  },
  availCount: {
    fontSize: 28,
    fontWeight: '800',
    color: colors.textWhite,
  },
  availCapacity: {
    fontSize: 12,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.8)',
  },
  availLabel: {
    fontSize: 9,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.8)',
    letterSpacing: 0.5,
  },
  content: {
    flex: 1,
    padding: 10,
    paddingLeft: 12,
    gap: 6,
  },
  topRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  facilityName: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textPrimary,
    flex: 1,
  },
  totalTime: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.primary,
    marginLeft: 8,
  },
  modesRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  modeText: {
    fontSize: 11,
    color: colors.textSecondary,
    marginLeft: -8,
  },
  badgeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  badges: {
    flexDirection: 'row' as const,
    alignItems: 'center' as const,
    gap: 6,
  },
  badge: {
    borderRadius: 5,
    paddingVertical: 2,
    paddingHorizontal: 7,
  },
  badgeText: {
    fontSize: 9,
    fontWeight: '600',
    color: colors.textWhite,
  },
});
