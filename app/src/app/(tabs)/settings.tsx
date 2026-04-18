import { View, Text, StyleSheet, Pressable, Switch } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Footprints, ParkingSquare } from "lucide-react-native";
import { colors, spacing, radii } from "@/lib/theme";
import { useAppStore } from "@/lib/store";

const SPEED_OPTIONS = [
  { key: "slow" as const, label: "Hidas", description: "3,5 km/h", icon: "🚶" },
  {
    key: "normal" as const,
    label: "Normaali",
    description: "5 km/h",
    icon: "🚶‍♂️",
  },
  { key: "fast" as const, label: "Nopea", description: "6,5 km/h", icon: "🏃" },
];

export default function SettingsScreen() {
  const {
    walkingSpeed,
    setWalkingSpeed,
    showOnlyAvailable,
    setShowOnlyAvailable,
  } = useAppStore();

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Asetukset</Text>
      </View>

      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Footprints size={18} color={colors.primary} />
          <Text style={styles.sectionTitle}>Kävelynopeus</Text>
        </View>

        <View style={styles.options}>
          {SPEED_OPTIONS.map((option) => (
            <Pressable
              key={option.key}
              style={[
                styles.optionCard,
                walkingSpeed === option.key && styles.optionCardActive,
              ]}
              onPress={() => setWalkingSpeed(option.key)}
            >
              <Text style={styles.optionIcon}>{option.icon}</Text>
              <Text
                style={[
                  styles.optionLabel,
                  walkingSpeed === option.key && styles.optionLabelActive,
                ]}
              >
                {option.label}
              </Text>
              <Text style={styles.optionDesc}>{option.description}</Text>
            </Pressable>
          ))}
        </View>
      </View>

      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <ParkingSquare size={18} color={colors.primary} />
          <Text style={styles.sectionTitle}>Pysäköinti</Text>
        </View>

        <Pressable
          style={styles.toggleRow}
          onPress={() => setShowOnlyAvailable(!showOnlyAvailable)}
        >
          <View style={styles.toggleText}>
            <Text style={styles.toggleLabel}>Näytä myös täydet</Text>
            <Text style={styles.toggleDesc}>
              Näytä liityntäpysäköinnit joissa ei ole vapaita paikkoja
            </Text>
          </View>
          <Switch
            value={!showOnlyAvailable}
            onValueChange={(val) => setShowOnlyAvailable(!val)}
            trackColor={{ false: colors.border, true: colors.primary }}
            thumbColor={colors.bgWhite}
          />
        </Pressable>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.bg },
  header: { padding: spacing.xl, paddingTop: spacing.lg },
  title: { fontSize: 28, fontWeight: "700", color: colors.textPrimary },
  section: { paddingHorizontal: spacing.xl },
  sectionHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: spacing.sm,
    marginBottom: spacing.lg,
  },
  sectionTitle: { fontSize: 16, fontWeight: "600", color: colors.textPrimary },
  options: { flexDirection: "row", gap: spacing.md },
  optionCard: {
    flex: 1,
    alignItems: "center",
    backgroundColor: colors.bgWhite,
    borderRadius: radii.lg,
    padding: spacing.xl,
    gap: spacing.sm,
    borderWidth: 2,
    borderColor: "transparent",
  },
  optionCardActive: {
    borderColor: colors.primary,
    backgroundColor: colors.primaryLight,
  },
  optionIcon: { fontSize: 28 },
  optionLabel: { fontSize: 15, fontWeight: "600", color: colors.textPrimary },
  optionLabelActive: { color: colors.primary },
  optionDesc: { fontSize: 13, color: colors.textSecondary },
  toggleRow: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: colors.bgWhite,
    borderRadius: radii.lg,
    padding: spacing.lg,
    gap: spacing.md,
  },
  toggleText: {
    flex: 1,
    gap: 2,
  },
  toggleLabel: {
    fontSize: 15,
    fontWeight: "600",
    color: colors.textPrimary,
  },
  toggleDesc: {
    fontSize: 13,
    color: colors.textSecondary,
  },
});
