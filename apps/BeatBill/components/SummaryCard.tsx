import { View, Text, StyleSheet } from 'react-native';
import { colors, radius, spacing } from '@/constants/theme';
import { formatMoney } from '@/types';
import type { CurrencyCode } from '@/constants/theme';

interface Props {
  collected: number;
  pending: number;
  count: number;
  currency: CurrencyCode;
}

export function SummaryCard({ collected, pending, count, currency }: Props) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Ce mois</Text>
      <View style={styles.stats}>
        <View style={styles.stat}>
          <Text style={styles.label}>Encaissé</Text>
          <Text style={[styles.value, styles.green]}>{formatMoney(collected, currency)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.stat}>
          <Text style={styles.label}>En attente</Text>
          <Text style={[styles.value, styles.orange]}>{formatMoney(pending, currency)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.stat}>
          <Text style={styles.label}>Factures</Text>
          <Text style={styles.value}>{count}</Text>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.lg,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  title: {
    color: colors.textSecondary,
    fontSize: 12,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: spacing.md,
  },
  stats: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  stat: { flex: 1, alignItems: 'center' },
  label: {
    color: colors.textSecondary,
    fontSize: 11,
    marginBottom: 4,
  },
  value: {
    color: colors.text,
    fontSize: 18,
    fontWeight: '700',
  },
  green: { color: colors.accentLight },
  orange: { color: colors.warning },
  divider: {
    width: 1,
    height: 40,
    backgroundColor: colors.separator,
  },
});
