import { View, Text, TextInput, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import type { LineItem } from '@/types';
import { computeLineTotal, formatMoney } from '@/types';
import type { CurrencyCode } from '@/constants/theme';

interface Props {
  item: LineItem;
  index: number;
  currency: CurrencyCode;
  onChange: (index: number, item: LineItem) => void;
  onRemove: (index: number) => void;
  canRemove: boolean;
}

export function LineItemRow({ item, index, currency, onChange, onRemove, canRemove }: Props) {
  const update = (patch: Partial<LineItem>) => {
    const next = { ...item, ...patch };
    next.total = computeLineTotal(next.qty, next.unitPrice);
    onChange(index, next);
  };

  return (
    <View style={styles.row}>
      <TextInput
        style={[styles.input, styles.desc]}
        value={item.description}
        onChangeText={(description) => update({ description })}
        placeholder="Description"
        placeholderTextColor={colors.textSecondary}
      />
      <TextInput
        style={[styles.input, styles.qty]}
        value={String(item.qty)}
        onChangeText={(v) => update({ qty: Math.max(1, parseInt(v, 10) || 1) })}
        keyboardType="number-pad"
      />
      <TextInput
        style={[styles.input, styles.price]}
        value={String(item.unitPrice)}
        onChangeText={(v) => update({ unitPrice: parseFloat(v.replace(',', '.')) || 0 })}
        keyboardType="decimal-pad"
      />
      <Text style={styles.total}>{formatMoney(item.total, currency)}</Text>
      {canRemove && (
        <Pressable onPress={() => onRemove(index)} hitSlop={8}>
          <Ionicons name="trash-outline" size={18} color={colors.error} />
        </Pressable>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    marginBottom: spacing.sm,
  },
  input: {
    backgroundColor: colors.section,
    borderRadius: radius.sm,
    padding: spacing.sm,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  desc: { flex: 1, minWidth: 80 },
  qty: { width: 44, textAlign: 'center' },
  price: { width: 64, textAlign: 'right' },
  total: {
    color: colors.accentLight,
    fontSize: 12,
    fontWeight: '600',
    width: 72,
    textAlign: 'right',
  },
});
