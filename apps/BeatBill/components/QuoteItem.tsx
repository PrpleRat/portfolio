import { Pressable, View, Text, StyleSheet } from 'react-native';
import { colors, radius, spacing } from '@/constants/theme';
import { effectiveQuoteStatus, formatDate, formatMoney, quoteStatusLabel } from '@/types';
import type { Quote } from '@/types';

interface Props {
  quote: Quote;
  onPress: () => void;
}

export function QuoteItem({ quote, onPress }: Props) {
  const status = effectiveQuoteStatus(quote);

  return (
    <Pressable style={styles.card} onPress={onPress}>
      <View style={styles.row}>
        <View style={styles.info}>
          <Text style={styles.client}>{quote.clientName}</Text>
          <Text style={styles.meta}>
            {quote.number} · {formatDate(quote.createdAt)}
          </Text>
        </View>
        <View style={styles.right}>
          <Text style={styles.amount}>{formatMoney(quote.total, quote.currency)}</Text>
          <Text style={[styles.badge, status === 'converted' && styles.badgeOk, status === 'expired' && styles.badgeWarn]}>
            {quoteStatusLabel(status)}
          </Text>
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
  row: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  info: { flex: 1, marginRight: spacing.md },
  client: { color: colors.text, fontSize: 16, fontWeight: '600', marginBottom: 4 },
  meta: { color: colors.textSecondary, fontSize: 12 },
  right: { alignItems: 'flex-end', gap: 6 },
  amount: { color: colors.accentLight, fontSize: 16, fontWeight: '700' },
  badge: {
    color: colors.textSecondary,
    fontSize: 10,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  badgeOk: { color: colors.accent },
  badgeWarn: { color: colors.warning },
});
