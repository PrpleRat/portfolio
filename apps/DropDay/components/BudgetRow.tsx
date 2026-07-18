import { View, Text, TextInput, StyleSheet } from 'react-native';
import { colors, radius, spacing } from '@/constants/theme';
import { formatMoney } from '@/types';

interface BudgetRowProps {
  label: string;
  planned: number;
  actual: number | null;
  currency: 'EUR' | 'USD';
  onActualChange?: (value: number | null) => void;
  editable?: boolean;
}

export function BudgetRow({
  label,
  planned,
  actual,
  currency,
  onActualChange,
  editable,
}: BudgetRowProps) {
  const diff = (actual ?? 0) - planned;
  const diffColor = diff > 0 ? colors.error : diff < 0 ? colors.success : colors.textSecondary;

  return (
    <View style={styles.row}>
      <Text style={styles.label} numberOfLines={2}>
        {label}
      </Text>
      <Text style={styles.planned}>{formatMoney(planned, currency)}</Text>
      {editable && onActualChange ? (
        <TextInput
          style={styles.input}
          keyboardType="numeric"
          placeholder="—"
          placeholderTextColor={colors.textSecondary}
          value={actual !== null ? String(actual) : ''}
          onChangeText={(v) => {
            const n = parseFloat(v.replace(',', '.'));
            onActualChange(v.trim() === '' ? null : Number.isNaN(n) ? null : n);
          }}
        />
      ) : (
        <Text style={styles.actual}>{actual !== null ? formatMoney(actual, currency) : '—'}</Text>
      )}
      <Text style={[styles.diff, { color: diffColor }]}>
        {actual !== null ? (diff >= 0 ? '+' : '') + formatMoney(diff, currency) : '—'}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.separator,
    gap: spacing.xs,
  },
  label: { flex: 2, color: colors.text, fontSize: 14 },
  planned: { flex: 1, color: colors.textSecondary, fontSize: 13, textAlign: 'right' },
  actual: { flex: 1, color: colors.text, fontSize: 13, textAlign: 'right' },
  input: {
    flex: 1,
    color: colors.text,
    fontSize: 13,
    textAlign: 'right',
    backgroundColor: colors.background,
    borderRadius: radius.sm,
    padding: spacing.xs,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  diff: { flex: 1, fontSize: 12, textAlign: 'right', fontWeight: '600' },
});
