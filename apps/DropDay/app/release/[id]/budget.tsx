import { ScrollView, View, Text, StyleSheet } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { colors, radius, spacing } from '@/constants/theme';
import { useRelease } from '@/hooks/useReleases';
import { BudgetRow } from '@/components/BudgetRow';
import { formatMoney, totalActualBudget, totalEstimatedBudget } from '@/types';
import { ProgressBar } from '@/components/ProgressBar';

export default function BudgetScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { release, profile, setTaskActualCost } = useRelease(id);

  if (!release) return null;

  const planned = totalEstimatedBudget(release);
  const actual = totalActualBudget(release);
  const balance = actual - planned;
  const maxBar = Math.max(planned, actual, 1);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.summary}>
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Prévu</Text>
          <Text style={styles.summaryValue}>{formatMoney(planned, profile.currency)}</Text>
        </View>
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Réel</Text>
          <Text style={styles.summaryValue}>{formatMoney(actual, profile.currency)}</Text>
        </View>
        <View style={[styles.summaryRow, styles.balanceRow]}>
          <Text style={styles.summaryLabel}>Solde</Text>
          <Text
            style={[
              styles.balanceValue,
              { color: balance > 0 ? colors.error : balance < 0 ? colors.success : colors.text },
            ]}
          >
            {balance >= 0 ? '+' : ''}
            {formatMoney(balance, profile.currency)}
          </Text>
        </View>
      </View>

      <Text style={styles.chartTitle}>Prévu vs Réel</Text>
      <View style={styles.chart}>
        <View style={styles.barGroup}>
          <Text style={styles.barLabel}>Prévu</Text>
          <ProgressBar
            progress={(planned / maxBar) * 100}
            height={16}
            color={colors.future}
          />
        </View>
        <View style={styles.barGroup}>
          <Text style={styles.barLabel}>Réel</Text>
          <ProgressBar
            progress={(actual / maxBar) * 100}
            height={16}
            color={balance > planned ? colors.error : colors.success}
          />
        </View>
      </View>

      <View style={styles.tableHeader}>
        <Text style={[styles.col, styles.colWide]}>Poste</Text>
        <Text style={styles.col}>Prévu</Text>
        <Text style={styles.col}>Réel</Text>
        <Text style={styles.col}>Δ</Text>
      </View>

      {release.tasks
        .filter((t) => t.estimatedCost > 0 || t.actualCost)
        .map((t) => (
          <BudgetRow
            key={t.id}
            label={t.title}
            planned={t.estimatedCost}
            actual={t.actualCost}
            currency={profile.currency}
            editable
            onActualChange={(cost) => setTaskActualCost(release.id, t.id, cost)}
          />
        ))}

      {release.tasks.every((t) => t.estimatedCost === 0 && !t.actualCost) && (
        <Text style={styles.empty}>
          Aucun budget défini. Retourne à la création ou saisis les coûts réels ici.
        </Text>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
  summary: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: spacing.xs,
  },
  balanceRow: {
    borderTopWidth: 1,
    borderTopColor: colors.separator,
    marginTop: spacing.sm,
    paddingTop: spacing.sm,
  },
  summaryLabel: { color: colors.textSecondary, fontSize: 15 },
  summaryValue: { color: colors.text, fontSize: 15, fontWeight: '600' },
  balanceValue: { fontSize: 17, fontWeight: '800' },
  chartTitle: {
    color: colors.textSecondary,
    fontSize: 12,
    fontWeight: '700',
    marginTop: spacing.lg,
    marginBottom: spacing.sm,
  },
  chart: { gap: spacing.sm },
  barGroup: { gap: spacing.xs },
  barLabel: { color: colors.textSecondary, fontSize: 12 },
  tableHeader: {
    flexDirection: 'row',
    marginTop: spacing.lg,
    paddingBottom: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.separator,
  },
  col: { flex: 1, color: colors.textSecondary, fontSize: 11, fontWeight: '700' },
  colWide: { flex: 2 },
  empty: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.xl },
});
