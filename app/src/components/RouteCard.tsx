import { View, Text, StyleSheet, Pressable } from 'react-native';
import { Car, TrainFront, Bus, Footprints, TramFront, Ship, Heart, Route as RouteIcon, ChevronRight } from 'lucide-react-native';
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
  onAction?: () => void;
  actionLabel?: string;
  isSelected?: boolean;
}

export function RouteCard({ route, onPress, onLongPress, onAction, actionLabel = 'Näytä reitti', isSelected }: RouteCardProps) {
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

      {/* Right content */}
      <View style={styles.rightContent}>
        {/* Info row */}
        <View style={styles.infoRow}>
          <View style={styles.nameCol}>
            <Text style={styles.facilityName} numberOfLines={1}>
              {route.parking.name}
            </Text>
            <View style={styles.modesRow}>
              {driveLeg && (
                <>
                  <Car size={11} color={colors.textSecondary} />
                  <Text style={styles.modeText}>{driveLeg.durationMinutes} min</Text>
                </>
              )}
              {transitLeg && (
                <>
                  {MODE_ICONS[transitLeg.mode] &&
                    (() => {
                      const Icon = MODE_ICONS[transitLeg.mode]!;
                      return <Icon size={11} color={MODE_COLORS[transitLeg.mode]} />;
                    })()}
                  <Text style={styles.modeText}>{transitLeg.durationMinutes} min</Text>
                </>
              )}
            </View>
          </View>
          {transitLeg && (
            <View style={[styles.transitBadge, { backgroundColor: MODE_COLORS[transitLeg.mode] }]}>
              <Text style={styles.transitBadgeText}>
                {transitLeg.lineName
                  ? `${transitLeg.lineName} ${MODE_LABELS[transitLeg.mode] ?? ''}`.trim()
                  : MODE_LABELS[transitLeg.mode] ?? transitLeg.mode}
              </Text>
            </View>
          )}
          <Text style={styles.totalTime}>{route.totalMinutes} min</Text>
        </View>

        {/* Divider */}
        <View style={styles.divider} />

        {/* Action bar */}
        <View style={styles.actionBar}>
          <Pressable style={styles.routeBtn} onPress={onAction ?? onPress}>
            <RouteIcon size={13} color={colors.primary} />
            <Text style={styles.routeBtnText}>{actionLabel}</Text>
            <ChevronRight size={13} color={colors.primary} />
          </Pressable>
          <Pressable
            style={[styles.favBtn, isFavouriteSpot && styles.favBtnActive]}
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
              size={14}
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
    backgroundColor: '#F5F7FA',
    borderRadius: 14,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#F0F0F0',
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
    width: 56,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 1,
    paddingVertical: 6,
    paddingHorizontal: 4,
  },
  availCount: {
    fontSize: 22,
    fontWeight: '800',
    color: colors.textWhite,
  },
  availCapacity: {
    fontSize: 10,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.8)',
  },
  availLabel: {
    fontSize: 8,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.8)',
    letterSpacing: 0.5,
  },
  rightContent: {
    flex: 1,
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10,
    paddingVertical: 8,
    gap: 8,
  },
  nameCol: {
    flex: 1,
    gap: 2,
  },
  facilityName: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.textPrimary,
  },
  modesRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  modeText: {
    fontSize: 10,
    color: colors.textSecondary,
  },
  transitBadge: {
    borderRadius: 5,
    paddingVertical: 2,
    paddingHorizontal: 6,
  },
  transitBadgeText: {
    fontSize: 8,
    fontWeight: '600',
    color: colors.textWhite,
  },
  totalTime: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.primary,
  },
  divider: {
    height: 1,
    backgroundColor: '#F0F0F0',
  },
  actionBar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    padding: 10,
    paddingVertical: 6,
  },
  routeBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 5,
    height: 28,
    backgroundColor: colors.primaryLight,
    borderRadius: 7,
  },
  routeBtnText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.primary,
  },
  favBtn: {
    width: 28,
    height: 28,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FEF2F2',
    borderRadius: 7,
  },
  favBtnActive: {
    backgroundColor: '#FEE2E2',
  },
});
