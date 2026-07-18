import { Pressable, View, Text, StyleSheet } from 'react-native';
import { colors, radius, spacing } from '@/constants/theme';
import { StatusBadge } from './StatusBadge';
import { effectiveStatus, formatDate, formatMoney } from '@/types';
import type { Invoice } from '@/types';
import { useProfile } from '@/hooks/useAppData';

interface Props {
  invoice: Invoice;
  onPress: () => void;
}

export function InvoiceItem({ invoice, onPress }: Props) {
  const { profile } = useProfile();
  const status = effectiveStatus(invoice);

  return (
    <Pressable style={styles.card} onPress={onPress}>
      <View style={styles.row}>
        <View style={styles.info}>
          <Text style={styles.client}>{invoice.clientName}</Text>
          <Text style={styles.meta}>
            {invoice.number} · {formatDate(invoice.createdAt)}
          </Text>
        </View>
        <View style={styles.right}>
          <Text style={styles.amount}>{formatMoney(invoice.total, invoice.currency ?? profile.currency)}</Text>
          <StatusBadge status={status} />
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.card,
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
  },
  info: { flex: 1, marginRight: spacing.md },
  client: {
    color: colors.text,
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 4,
  },
  meta: {
    color: colors.textSecondary,
    fontSize: 12,
  },
  right: {
    alignItems: 'flex-end',
    gap: 6,
  },
  amount: {
    color: colors.accentLight,
    fontSize: 16,
    fontWeight: '700',
  },
});
