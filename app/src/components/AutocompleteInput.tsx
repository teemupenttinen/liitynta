import { useState, useCallback, useRef, useEffect } from 'react';
import {
  View,
  TextInput,
  Text,
  Pressable,
  StyleSheet,
  FlatList,
  Keyboard,
} from 'react-native';
import { CircleDot, MapPin, LocateFixed } from 'lucide-react-native';
import { colors, spacing, radii } from '@/lib/theme';
import { autocomplete, type GeocodeSuggestion } from '@/lib/digitransit';

interface AutocompleteInputProps {
  value: string;
  onChangeText: (text: string) => void;
  onSelect: (suggestion: GeocodeSuggestion) => void;
  placeholder: string;
  variant: 'origin' | 'destination';
  onSubmitEditing?: () => void;
  onRequestLocation?: () => void;
  focusPoint?: { lat: number; lon: number };
}

export function AutocompleteInput({
  value,
  onChangeText,
  onSelect,
  placeholder,
  variant,
  onSubmitEditing,
  onRequestLocation,
  focusPoint,
}: AutocompleteInputProps) {
  const [suggestions, setSuggestions] = useState<GeocodeSuggestion[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const selectedRef = useRef(false);

  const handleChangeText = useCallback(
    (text: string) => {
      selectedRef.current = false;
      onChangeText(text);

      if (debounceRef.current) clearTimeout(debounceRef.current);

      if (text.length < 2) {
        setSuggestions([]);
        setShowSuggestions(false);
        return;
      }

      debounceRef.current = setTimeout(async () => {
        const results = await autocomplete(text, focusPoint);
        if (!selectedRef.current) {
          setSuggestions(results);
          setShowSuggestions(results.length > 0);
        }
      }, 300);
    },
    [onChangeText, focusPoint],
  );

  const handleSelect = useCallback(
    (suggestion: GeocodeSuggestion) => {
      selectedRef.current = true;
      onChangeText(suggestion.label);
      onSelect(suggestion);
      setSuggestions([]);
      setShowSuggestions(false);
      Keyboard.dismiss();
    },
    [onChangeText, onSelect],
  );

  const handleFocus = useCallback(() => {
    if (suggestions.length > 0 && !selectedRef.current) {
      setShowSuggestions(true);
    }
  }, [suggestions]);

  const handleBlur = useCallback(() => {
    // Delay hiding so tap on suggestion registers
    setTimeout(() => setShowSuggestions(false), 200);
  }, []);

  useEffect(() => {
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, []);

  const Icon = variant === 'origin' ? CircleDot : MapPin;
  const iconColor = variant === 'origin' ? colors.primary : '#E85A4F';

  return (
    <View style={styles.wrapper}>
      <View style={styles.field}>
        <Icon size={20} color={iconColor} />
        <TextInput
          style={styles.input}
          placeholder={placeholder}
          placeholderTextColor={colors.textMuted}
          value={value}
          onChangeText={handleChangeText}
          onFocus={handleFocus}
          onBlur={handleBlur}
          onSubmitEditing={onSubmitEditing}
          returnKeyType="search"
        />
        {variant === 'origin' && onRequestLocation && (
          <Pressable onPress={onRequestLocation} hitSlop={8}>
            <LocateFixed size={20} color={colors.textMuted} />
          </Pressable>
        )}
      </View>
      {showSuggestions && (
        <View style={styles.dropdown}>
          {suggestions.map((item, index) => (
            <Pressable
              key={`${item.label}-${index}`}
              style={styles.suggestionItem}
              onPress={() => handleSelect(item)}
            >
              <MapPin size={14} color={colors.textMuted} />
              <Text style={styles.suggestionText} numberOfLines={1}>
                {item.label}
              </Text>
            </Pressable>
          ))}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    zIndex: 1,
  },
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.bgWhite,
    borderRadius: radii.md,
    paddingHorizontal: spacing.lg,
    height: 48,
    gap: spacing.md,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.07,
    shadowRadius: 8,
    elevation: 4,
  },
  input: {
    flex: 1,
    fontSize: 15,
    color: colors.textPrimary,
  },
  dropdown: {
    position: 'absolute',
    top: 52,
    left: 0,
    right: 0,
    backgroundColor: colors.bgWhite,
    borderRadius: radii.md,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.12,
    shadowRadius: 12,
    elevation: 8,
    overflow: 'hidden',
  },
  suggestionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    gap: spacing.sm,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: colors.borderLight,
  },
  suggestionText: {
    flex: 1,
    fontSize: 14,
    color: colors.textPrimary,
  },
});
