import { View, Text, StyleSheet } from 'react-native';
import { colors, radius } from '@/constants/theme';
import type { InvoiceStatus } from '@/types';
import { statusLabel } from '@/types';

interface Props {
  status: InvoiceStatus;
}

export function StatusBadge({ status }: Props) {
  const bg =
    status === 'paid' ? colors.accent : status === 'overdue' ? colors.error : colors.warning;
  const textColor = status === 'paid' ? colors.background : colors.text;

  return (
    <View style={[styles.badge, { backgroundColor: bg }]}>
      <Text style={[styles.text, { color: textColor }]}>{statusLabel(status)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: radius.sm,
  },
  text: {
    fontSize: 10,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
});
