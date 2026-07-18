import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';

interface Props {
  label: string;
  total: number;
  target?: number;
}

export function TotalIndicator({ label, total, target = 100 }: Props) {
  const isValid = total === target;
  const isOver = total > target;
  const progress = Math.min(total / target, 1);
  const remaining = target - total;

  return (
    <View style={styles.container}>
      <View style={styles.row}>
        <Text style={styles.label}>{label}</Text>
        <View style={styles.statusRow}>
          <Text style={[styles.total, isValid && styles.valid, isOver && styles.over]}>
            {total}% / {target}%
          </Text>
          {isValid ? (
            <Ionicons name="checkmark-circle" size={18} color={colors.success} />
          ) : (
            <Ionicons
              name="alert-circle"
              size={18}
              color={remaining > 0 ? colors.warning : colors.error}
            />
          )}
        </View>
      </View>
      <View style={styles.barBg}>
        <View
          style={[
            styles.barFill,
            { width: `${progress * 100}%` },
            isValid && styles.barValid,
            isOver && styles.barOver,
          ]}
        />
      </View>
      {!isValid && (
        <Text style={styles.hint}>
          {remaining > 0 ? `Il manque ${remaining}%` : `Dépassement de ${Math.abs(remaining)}%`}
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.section,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  label: {
    color: colors.text,
    fontWeight: '600',
    fontSize: 14,
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  total: {
    color: colors.textSecondary,
    fontWeight: '700',
    fontSize: 14,
  },
  valid: { color: colors.success },
  over: { color: colors.error },
  barBg: {
    height: 8,
    backgroundColor: colors.separator,
    borderRadius: radius.sm,
    overflow: 'hidden',
  },
  barFill: {
    height: '100%',
    backgroundColor: colors.accent,
    borderRadius: radius.sm,
  },
  barValid: { backgroundColor: colors.success },
  barOver: { backgroundColor: colors.error },
  hint: {
    color: colors.warning,
    fontSize: 12,
    marginTop: spacing.xs,
  },
});
