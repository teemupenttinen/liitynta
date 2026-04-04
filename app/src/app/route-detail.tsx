import { View, Text, StyleSheet, ScrollView, Pressable } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter } from 'expo-router';
import {
  ArrowLeft,
  Car,
  TrainFront,
  Footprints,
  MapPin,
  Navigation,
} from 'lucide-react-native';
import { colors, spacing, radii } from '@/lib/theme';
import { useAppStore } from '@/lib/store';
import { navigateTo, getNavigationState } from '@/lib/navigation';
import type { TransitMode } from '@/types/route';

const MODE_CONFIG: Record<TransitMode, { color: string; bgColor: string; label: string; icon: any }> = {
  drive: { color: colors.driveBlue, bgColor: '#E8F0FE', label: 'Ajomatka', icon: Car },
  park: { color: colors.primary, bgColor: colors.primaryLight, label: 'Pysäköinti', icon: MapPin },
  metro: { color: colors.metroOrange, bgColor: '#FFF3E0', label: 'Metro', icon: TrainFront },
  bus: { color: colors.busBlue, bgColor: '#E3F2FD', label: 'Bussi', icon: TrainFront },
  tram: { color: colors.tramGreen, bgColor: '#E8F5E9', label: 'Ratikka', icon: TrainFront },
  rail: { color: colors.railPurple, bgColor: '#F3E5F5', label: 'Juna', icon: TrainFront },
  ferry: { color: colors.ferryCyan, bgColor: '#E0F7FA', label: 'Lautta', icon: TrainFront },
  walk: { color: colors.walkGray, bgColor: '#F0F0F0', label: 'Kävely', icon: Footprints },
};

export default function RouteDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { selectedRoute } = useAppStore();

  // TODO: Determine from user location
  const navState = 'drive_to_parking' as const;

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      {/* Header */}
      <View style={styles.header}>
        <Pressable onPress={() => router.back()}>
          <ArrowLeft size={24} color={colors.textWhite} />
        </Pressable>
        <Text style={styles.headerTitle}>Reitin tiedot</Text>
      </View>

      {/* Route summary */}
      <View style={styles.summary}>
        <View style={styles.summaryLeft}>
          <Text style={styles.summaryRoute}>
            {selectedRoute?.legs[0]?.from ?? 'Espoo'} → {selectedRoute?.parking?.name ?? 'P+R'}
          </Text>
          <Text style={styles.summarySubtitle}>
            Espoo → Helsinki keskusta
          </Text>
        </View>
        <View style={styles.summaryRight}>
          <Text style={styles.summaryTime}>
            {selectedRoute?.totalMinutes ?? 38} min
          </Text>
          <Text style={styles.summaryLabel}>kokonaisaika</Text>
        </View>
      </View>

      {/* Legs */}
      <ScrollView style={styles.scroll} contentContainerStyle={styles.scrollContent}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Reitin vaiheet</Text>
        </View>

        {(selectedRoute?.legs ?? []).map((leg, index) => {
          const config = MODE_CONFIG[leg.mode];
          const Icon = config.icon;
          const isLast = index === (selectedRoute?.legs?.length ?? 0) - 1;

          return (
            <View
              key={index}
              style={[
                styles.leg,
                navState === 'drive_to_parking' &&
                  leg.mode === 'drive' &&
                  styles.activeLeg,
              ]}
            >
              {/* Timeline */}
              <View style={styles.timeline}>
                {leg.mode === 'park' ? (
                  <View style={styles.parkDot}>
                    <Text style={styles.parkDotText}>P</Text>
                  </View>
                ) : (
                  <View
                    style={[styles.dot, { backgroundColor: config.color }]}
                  />
                )}
                {!isLast && (
                  <View
                    style={[styles.line, { backgroundColor: config.color }]}
                  />
                )}
              </View>

              {/* Content */}
              <View style={styles.legContent}>
                {leg.mode === 'park' ? (
                  <>
                    <Text style={styles.legTitle}>
                      Pysäköinti – {leg.parking?.name}
                    </Text>
                    <View style={styles.availRow}>
                      <View
                        style={[
                          styles.availDot,
                          { backgroundColor: colors.availHigh },
                        ]}
                      />
                      <Text style={[styles.availText, { color: colors.availHigh }]}>
                        Vapaana {leg.parking?.available}/{leg.parking?.capacity}
                      </Text>
                    </View>
                  </>
                ) : (
                  <>
                    {leg.lineDescription && (
                      <Text style={styles.lineDesc}>
                        {leg.lineName} – {leg.lineDescription}
                      </Text>
                    )}
                    <Text style={styles.legFrom}>{leg.from}</Text>
                    <Text style={styles.legTo}>→ {leg.to}</Text>
                    <View style={styles.statsRow}>
                      <Text style={[styles.statTime, { color: config.color }]}>
                        {leg.durationMinutes} min
                      </Text>
                      <Text style={styles.statDist}>{leg.distanceKm} km</Text>
                    </View>
                    <View style={[styles.badge, { backgroundColor: config.bgColor }]}>
                      <Icon size={14} color={config.color} />
                      <Text style={[styles.badgeText, { color: config.color }]}>
                        {config.label}
                      </Text>
                    </View>
                  </>
                )}
              </View>
            </View>
          );
        })}

        {/* Destination */}
        <View style={styles.leg}>
          <View style={styles.timeline}>
            <MapPin size={20} color={colors.primary} />
          </View>
          <View style={styles.legContent}>
            <Text style={styles.destLabel}>Määränpää</Text>
            <Text style={styles.destName}>Helsinki keskusta</Text>
          </View>
        </View>
      </ScrollView>

      {/* Contextual navigation CTA */}
      <View style={styles.cta}>
        <Text style={styles.ctaContext}>
          {navState === 'drive_to_parking'
            ? `Aja ${selectedRoute?.parking?.name ?? 'Itäkeskus P+R'} -parkkiin`
            : 'Olet lähellä kohdetta'}
        </Text>
        <Pressable
          style={styles.ctaButton}
          onPress={() => {
            // TODO: Use actual parking/destination coordinates
            navigateTo(60.2095, 25.0828, 'Itäkeskus P+R');
          }}
        >
          <Navigation size={20} color={colors.textWhite} />
          <Text style={styles.ctaButtonText}>
            {navState === 'drive_to_parking' ? 'Aja parkkiin' : 'Navigoi kohteeseen'}
          </Text>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.bg },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primary,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.lg,
    gap: spacing.md,
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: colors.textWhite,
  },
  summary: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.bgWhite,
    padding: spacing.xl,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 2,
  },
  summaryLeft: { flex: 1 },
  summaryRoute: { fontSize: 16, fontWeight: '700', color: colors.textPrimary },
  summarySubtitle: { fontSize: 13, color: colors.textSecondary, marginTop: 2 },
  summaryRight: { alignItems: 'flex-end' },
  summaryTime: { fontSize: 24, fontWeight: '700', color: colors.primary },
  summaryLabel: { fontSize: 11, color: colors.textMuted },
  scroll: { flex: 1 },
  scrollContent: { padding: spacing.xl },
  sectionHeader: { marginBottom: spacing.lg },
  sectionTitle: { fontSize: 14, fontWeight: '600', color: colors.textSecondary },
  leg: {
    flexDirection: 'row',
    gap: spacing.md,
    paddingVertical: spacing.lg,
  },
  activeLeg: {
    backgroundColor: colors.primaryLight,
    borderRadius: radii.md,
    marginHorizontal: -spacing.sm,
    paddingHorizontal: spacing.sm,
  },
  timeline: {
    width: 32,
    alignItems: 'center',
    gap: 4,
  },
  dot: { width: 14, height: 14, borderRadius: 7 },
  parkDot: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 3,
    borderColor: colors.primary,
    backgroundColor: colors.bgWhite,
    alignItems: 'center',
    justifyContent: 'center',
  },
  parkDotText: { fontSize: 10, fontWeight: '700', color: colors.primary },
  line: { flex: 1, width: 3, borderRadius: 2 },
  legContent: { flex: 1, gap: 4 },
  legTitle: { fontSize: 14, fontWeight: '600', color: colors.textPrimary },
  lineDesc: { fontSize: 13, fontWeight: '500', color: colors.textSecondary },
  legFrom: { fontSize: 14, fontWeight: '500', color: colors.textPrimary },
  legTo: { fontSize: 14, fontWeight: '500', color: colors.textPrimary },
  statsRow: { flexDirection: 'row', gap: spacing.lg, marginTop: 4 },
  statTime: { fontSize: 13, fontWeight: '600' },
  statDist: { fontSize: 13, color: colors.textSecondary },
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    borderRadius: 13,
    paddingVertical: 4,
    paddingHorizontal: 10,
    gap: 5,
    marginTop: 4,
  },
  badgeText: { fontSize: 12, fontWeight: '600' },
  availRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  availDot: { width: 10, height: 10, borderRadius: 5 },
  availText: { fontSize: 13, fontWeight: '500' },
  destLabel: { fontSize: 12, fontWeight: '500', color: colors.textMuted },
  destName: { fontSize: 15, fontWeight: '600', color: colors.textPrimary },
  cta: {
    backgroundColor: colors.bgWhite,
    padding: spacing.xl,
    paddingBottom: spacing.xxxl,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 12,
    elevation: 8,
    gap: spacing.sm,
    alignItems: 'center',
  },
  ctaContext: { fontSize: 13, fontWeight: '500', color: colors.textMuted },
  ctaButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary,
    borderRadius: radii.md,
    paddingVertical: 14,
    gap: 10,
    width: '100%',
  },
  ctaButtonText: {
    fontSize: 17,
    fontWeight: '600',
    color: colors.textWhite,
  },
});
