import { useMemo, useState } from 'react';
import { ScrollView, View, Text, Pressable, StyleSheet } from 'react-native';
import { colors, radius, spacing, CURRENCIES } from '@/constants/theme';
import { useInvoices } from '@/hooks/useAppData';
import { formatMoney } from '@/types';
import { computePeriodReport, computeYearlyBreakdown } from '@/utils/reports';
import type { CurrencyCode } from '@/constants/theme';

export default function ReportsScreen() {
  const { invoices } = useInvoices();
  const years = useMemo(() => {
    const set = new Set(invoices.map((i) => new Date(i.createdAt).getFullYear()));
    const current = new Date().getFullYear();
    set.add(current);
    return [...set].sort((a, b) => b - a);
  }, [invoices]);

  const [year, setYear] = useState(years[0] ?? new Date().getFullYear());
  const [mode, setMode] = useState<'monthly' | 'annual'>('monthly');

  const annualReport = useMemo(() => computePeriodReport(invoices, year), [invoices, year]);
  const monthlyReports = useMemo(() => computeYearlyBreakdown(invoices, year), [invoices, year]);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.section}>Période</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.yearRow}>
        {years.map((y) => (
          <Pressable
            key={y}
            style={[styles.chip, year === y && styles.chipActive]}
            onPress={() => setYear(y)}
          >
            <Text style={[styles.chipText, year === y && styles.chipTextActive]}>{y}</Text>
          </Pressable>
        ))}
      </ScrollView>

      <View style={styles.modeRow}>
        <Pressable
          style={[styles.modeBtn, mode === 'monthly' && styles.modeBtnActive]}
          onPress={() => setMode('monthly')}
        >
          <Text style={[styles.modeText, mode === 'monthly' && styles.modeTextActive]}>Mensuel</Text>
        </Pressable>
        <Pressable
          style={[styles.modeBtn, mode === 'annual' && styles.modeBtnActive]}
          onPress={() => setMode('annual')}
        >
          <Text style={[styles.modeText, mode === 'annual' && styles.modeTextActive]}>Annuel</Text>
        </Pressable>
      </View>

      {mode === 'annual' ? (
        <ReportCard
          title={`Rapport ${year}`}
          invoiceCount={annualReport.invoiceCount}
          paidCount={annualReport.paidCount}
          pendingCount={annualReport.pendingCount}
          byCurrency={annualReport.byCurrency}
        />
      ) : (
        monthlyReports.map((report) => (
          <ReportCard
            key={report.month}
            title={report.label}
            invoiceCount={report.invoiceCount}
            paidCount={report.paidCount}
            pendingCount={report.pendingCount}
            byCurrency={report.byCurrency}
            compact={report.invoiceCount === 0}
          />
        ))
      )}
    </ScrollView>
  );
}

function ReportCard({
  title,
  invoiceCount,
  paidCount,
  pendingCount,
  byCurrency,
  compact,
}: {
  title: string;
  invoiceCount: number;
  paidCount: number;
  pendingCount: number;
  byCurrency: Record<CurrencyCode, { collected: number; pending: number; total: number }>;
  compact?: boolean;
}) {
  if (compact) return null;

  return (
    <View style={styles.card}>
      <Text style={styles.cardTitle}>{title}</Text>
      <Text style={styles.stats}>
        {invoiceCount} facture{invoiceCount > 1 ? 's' : ''} · {paidCount} payée{paidCount > 1 ? 's' : ''} ·{' '}
        {pendingCount} en attente
      </Text>
      {CURRENCIES.map((c) => {
        const data = byCurrency[c.code];
        if (!data || data.total === 0) return null;
        return (
          <View key={c.code} style={styles.currencyBlock}>
            <Text style={styles.currencyLabel}>{c.label}</Text>
            <View style={styles.row}>
              <Text style={styles.label}>Encaissé</Text>
              <Text style={styles.valueOk}>{formatMoney(data.collected, c.code)}</Text>
            </View>
            <View style={styles.row}>
              <Text style={styles.label}>En attente</Text>
              <Text style={styles.value}>{formatMoney(data.pending, c.code)}</Text>
            </View>
            <View style={styles.row}>
              <Text style={styles.label}>Total</Text>
              <Text style={styles.valueBold}>{formatMoney(data.total, c.code)}</Text>
            </View>
          </View>
        );
      })}
      {invoiceCount === 0 && (
        <Text style={styles.empty}>Aucune facture sur cette période</Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
  section: {
    color: colors.textSecondary,
    fontSize: 12,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: spacing.sm,
  },
  yearRow: { marginBottom: spacing.md },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.sm,
    backgroundColor: colors.card,
    marginRight: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  chipActive: { backgroundColor: colors.accent, borderColor: colors.accent },
  chipText: { color: colors.textSecondary, fontWeight: '600' },
  chipTextActive: { color: colors.background },
  modeRow: { flexDirection: 'row', gap: spacing.sm, marginBottom: spacing.lg },
  modeBtn: {
    flex: 1,
    padding: spacing.md,
    borderRadius: radius.sm,
    backgroundColor: colors.card,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.separator,
  },
  modeBtnActive: { backgroundColor: colors.section, borderColor: colors.accent },
  modeText: { color: colors.textSecondary, fontWeight: '600' },
  modeTextActive: { color: colors.accentLight },
  card: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  cardTitle: { color: colors.text, fontSize: 16, fontWeight: '700', marginBottom: spacing.xs },
  stats: { color: colors.textSecondary, fontSize: 12, marginBottom: spacing.md },
  currencyBlock: {
    marginTop: spacing.sm,
    paddingTop: spacing.sm,
    borderTopWidth: 1,
    borderTopColor: colors.separator,
  },
  currencyLabel: { color: colors.textSecondary, fontSize: 11, marginBottom: spacing.xs, textTransform: 'uppercase' },
  row: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 4 },
  label: { color: colors.textSecondary, fontSize: 13 },
  value: { color: colors.text, fontSize: 13 },
  valueOk: { color: colors.accentLight, fontSize: 13, fontWeight: '600' },
  valueBold: { color: colors.text, fontSize: 13, fontWeight: '700' },
  empty: { color: colors.textSecondary, fontSize: 13, fontStyle: 'italic' },
});
