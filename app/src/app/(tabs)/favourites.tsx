import { useMemo } from 'react';
import { View, Text, StyleSheet, Pressable } from 'react-native';
import { Heart, MapPin, Navigation, ChevronRight } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { colors, spacing, radii } from '@/lib/theme';
import { useAppStore } from '@/lib/store';
import type { AvailabilityLevel } from '@/types/route';

export default function FavouritesScreen() {
  const { commutePairs, favouriteParkingSpots, removeFavouriteParkingSpot, facilities } = useAppStore();

  const facilityMap = useMemo(() => {
    const map = new Map<string, (typeof facilities)[number]>();
    for (const f of facilities) {
      map.set(String(f.id), f);
    }
    return map;
  }, [facilities]);

  const getAvailColor = (availability: AvailabilityLevel) => {
    if (availability === 'high') return colors.availHigh;
    if (availability === 'medium') return colors.availMedium;
    return colors.availLow;
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Suosikit</Text>
      </View>

      {/* Commute pairs section */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Navigation size={18} color={colors.primary} />
          <Text style={styles.sectionTitle}>Työmatkat</Text>
        </View>

        {commutePairs.length === 0 ? (
          <View style={styles.emptyCard}>
            <Heart size={24} color={colors.textMuted} />
            <Text style={styles.emptyText}>
              Tallenna reittihaku suosikiksi nähdäksesi työmatkasi täällä
            </Text>
          </View>
        ) : (
          commutePairs.map((pair) => (
            <Pressable key={pair.id} style={styles.commuteCard}>
              <View style={styles.commuteContent}>
                <Text style={styles.commuteOrigin}>{pair.origin}</Text>
                <Text style={styles.commuteArrow}>→</Text>
                <Text style={styles.commuteDest}>{pair.destination}</Text>
              </View>
              <ChevronRight size={20} color={colors.textMuted} />
            </Pressable>
          ))
        )}
      </View>

      {/* Favourite parking spots section */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <MapPin size={18} color={colors.primary} />
          <Text style={styles.sectionTitle}>Pysäköintipaikat</Text>
        </View>

        {favouriteParkingSpots.length === 0 ? (
          <View style={styles.emptyCard}>
            <MapPin size={24} color={colors.textMuted} />
            <Text style={styles.emptyText}>
              Tallenna pysäköintipaikka suosikiksi seurataksesi vapaita paikkoja
            </Text>
          </View>
        ) : (
          favouriteParkingSpots.map((spot) => {
            const facility = facilityMap.get(spot.facilityId);
            const avail = facility?.availability ?? 'low';
            const availColor = getAvailColor(avail);

            return (
              <View key={spot.id} style={styles.facilityCard}>
                <View style={[styles.availSidebar, { backgroundColor: availColor }]}>
                  <Text style={styles.availCount}>
                    {facility?.available ?? '–'}
                  </Text>
                  {facility?.available != null && (
                    <Text style={styles.availCapacity}>/{facility.capacity}</Text>
                  )}
                  <Text style={styles.availLabel}>
                    {facility?.available != null ? 'vapaana' : 'paikkaa'}
                  </Text>
                </View>
                <View style={styles.rightContent}>
                  <View style={styles.infoRow}>
                    <Text style={styles.facilityName} numberOfLines={1}>{spot.name}</Text>
                  </View>
                  <View style={styles.divider} />
                  <View style={styles.actionBar}>
                    <Pressable style={styles.routeBtn} onPress={() => {}}>
                      <Navigation size={13} color={colors.primary} />
                      <Text style={styles.routeBtnText}>Navigoi parkkiin</Text>
                      <ChevronRight size={13} color={colors.primary} />
                    </Pressable>
                    <Pressable
                      style={[styles.favBtn, styles.favBtnActive]}
                      onPress={() => removeFavouriteParkingSpot(spot.id)}
                      hitSlop={8}
                    >
                      <Heart size={14} color={colors.availLow} fill={colors.availLow} />
                    </Pressable>
                  </View>
                </View>
              </View>
            );
          })
        )}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.bg },
  header: { padding: spacing.xl, paddingTop: spacing.lg },
  title: { fontSize: 28, fontWeight: '700', color: colors.textPrimary },
  section: { paddingHorizontal: spacing.xl, marginBottom: spacing.xxl },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  sectionTitle: { fontSize: 16, fontWeight: '600', color: colors.textPrimary },
  emptyCard: {
    alignItems: 'center',
    backgroundColor: colors.bgWhite,
    borderRadius: radii.md,
    padding: spacing.xxxl,
    gap: spacing.md,
  },
  emptyText: {
    fontSize: 14,
    color: colors.textMuted,
    textAlign: 'center',
    lineHeight: 20,
  },

  // Commute pair cards
  commuteCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.bgWhite,
    borderRadius: radii.md,
    padding: spacing.lg,
    marginBottom: spacing.sm,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  commuteContent: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  commuteOrigin: { fontSize: 15, fontWeight: '500', color: colors.textPrimary },
  commuteArrow: { fontSize: 15, color: colors.textMuted },
  commuteDest: { fontSize: 15, fontWeight: '500', color: colors.textPrimary },

  // Facility cards
  facilityCard: {
    flexDirection: 'row',
    backgroundColor: '#F5F7FA',
    borderRadius: 14,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: colors.primary,
    marginBottom: spacing.sm,
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
  },
  facilityName: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.textPrimary,
    flex: 1,
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
