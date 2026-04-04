import { View, Text, StyleSheet, Pressable } from 'react-native';
import { Heart, MapPin, Navigation, ChevronRight } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { colors, spacing, radii } from '@/lib/theme';
import { useAppStore } from '@/lib/store';

export default function FavouritesScreen() {
  const { commutePairs, favouriteParkingSpots } = useAppStore();

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
            <Pressable key={pair.id} style={styles.card}>
              <View style={styles.cardContent}>
                <Text style={styles.cardOrigin}>{pair.origin}</Text>
                <Text style={styles.cardArrow}>→</Text>
                <Text style={styles.cardDest}>{pair.destination}</Text>
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
          favouriteParkingSpots.map((spot) => (
            <Pressable key={spot.id} style={styles.card}>
              <View style={styles.cardContent}>
                <Text style={styles.cardOrigin}>{spot.name}</Text>
              </View>
              <ChevronRight size={20} color={colors.textMuted} />
            </Pressable>
          ))
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
  card: {
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
  cardContent: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  cardOrigin: { fontSize: 15, fontWeight: '500', color: colors.textPrimary },
  cardArrow: { fontSize: 15, color: colors.textMuted },
  cardDest: { fontSize: 15, fontWeight: '500', color: colors.textPrimary },
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
});
