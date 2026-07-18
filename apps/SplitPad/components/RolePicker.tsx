import { ScrollView, Pressable, Text, StyleSheet } from 'react-native';
import { ROLES } from '@/constants/theme';
import { colors, radius, spacing } from '@/constants/theme';

interface Props {
  value: string;
  onChange: (role: string) => void;
}

export function RolePicker({ value, onChange }: Props) {
  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.scroll}>
      {ROLES.map((role) => (
        <Pressable
          key={role}
          style={[styles.chip, value === role && styles.chipActive]}
          onPress={() => onChange(role)}
        >
          <Text style={[styles.chipText, value === role && styles.chipTextActive]}>{role}</Text>
        </Pressable>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scroll: { marginTop: spacing.xs },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.sm,
    borderWidth: 1,
    borderColor: colors.separator,
    marginRight: spacing.sm,
    backgroundColor: colors.card,
  },
  chipActive: {
    backgroundColor: colors.accent,
    borderColor: colors.accent,
  },
  chipText: {
    color: colors.textSecondary,
    fontSize: 13,
  },
  chipTextActive: {
    color: colors.text,
    fontWeight: '600',
  },
});
