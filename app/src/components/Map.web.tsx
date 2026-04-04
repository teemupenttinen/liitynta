import { View, Text, StyleSheet } from 'react-native';
import { colors } from '@/lib/theme';

/** Placeholder map for web — react-native-maps is native-only */
export function MapView({ children, style, ...props }: any) {
  return (
    <View style={[styles.container, style]}>
      <Text style={styles.text}>Kartta näkyy vain mobiilissa</Text>
      {children}
    </View>
  );
}

export function Marker(_props: any) {
  return null;
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#e8e8e8',
    alignItems: 'center',
    justifyContent: 'center',
  },
  text: {
    color: colors.textMuted,
    fontSize: 14,
  },
});
