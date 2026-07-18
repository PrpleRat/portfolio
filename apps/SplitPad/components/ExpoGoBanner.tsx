import { View, Text, StyleSheet, Pressable } from 'react-native';
import { colors, radius, spacing } from '@/constants/theme';
import { isExpoGo } from '@/utils/expoGo';

interface Props {
  onLoadDemo?: () => void;
}

export function ExpoGoBanner({ onLoadDemo }: Props) {
  if (!isExpoGo()) return null;

  return (
    <View style={styles.banner}>
      <Text style={styles.title}>Mode Expo Go</Text>
      <Text style={styles.text}>
        Les splits sont dans BeatDeal — SplitPad sert de demo Expo Go
      </Text>
      {onLoadDemo && (
        <Pressable style={styles.btn} onPress={onLoadDemo}>
          <Text style={styles.btnText}>Charger la démo</Text>
        </Pressable>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  banner: {
    backgroundColor: colors.section,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.accent,
  },
  title: {
    color: colors.accentLight,
    fontWeight: '700',
    fontSize: 13,
    marginBottom: 4,
  },
  text: {
    color: colors.textSecondary,
    fontSize: 12,
    lineHeight: 18,
  },
  btn: {
    marginTop: spacing.sm,
    alignSelf: 'flex-start',
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    backgroundColor: colors.accent,
    borderRadius: radius.sm,
  },
  btnText: {
    color: colors.text,
    fontWeight: '700',
    fontSize: 13,
  },
});
