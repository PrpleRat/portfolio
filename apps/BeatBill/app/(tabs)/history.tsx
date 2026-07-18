import { useMemo, useState } from 'react';
import {
  ScrollView,
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
} from 'react-native';
import { useRouter } from 'expo-router';
import { colors, radius, spacing } from '@/constants/theme';
import { InvoiceItem } from '@/components/InvoiceItem';
import { useInvoices, useProfile } from '@/hooks/useAppData';
import { effectiveStatus, formatMoney, type InvoiceStatus } from '@/types';

type Filter = 'all' | InvoiceStatus;
type Sort = 'recent' | 'oldest' | 'amount_asc' | 'amount_desc';

const FILTERS: { key: Filter; label: string }[] = [
  { key: 'all', label: 'Toutes' },
  { key: 'paid', label: 'Payées' },
  { key: 'pending', label: 'En attente' },
  { key: 'overdue', label: 'En retard' },
];

const SORTS: { key: Sort; label: string }[] = [
  { key: 'recent', label: 'Plus récentes' },
  { key: 'oldest', label: 'Plus anciennes' },
  { key: 'amount_desc', label: 'Montant ↓' },
  { key: 'amount_asc', label: 'Montant ↑' },
];

export default function HistoryScreen() {
  const router = useRouter();
  const { invoices, allTimeStats } = useInvoices();
  const { profile } = useProfile();
  const [filter, setFilter] = useState<Filter>('all');
  const [sort, setSort] = useState<Sort>('recent');
  const [search, setSearch] = useState('');

  const filtered = useMemo(() => {
    let list = [...invoices];
    if (filter !== 'all') {
      list = list.filter((i) => effectiveStatus(i) === filter);
    }
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (i) =>
          i.clientName.toLowerCase().includes(q) ||
          i.number.toLowerCase().includes(q)
      );
    }
    list.sort((a, b) => {
      switch (sort) {
        case 'oldest':
          return new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
        case 'amount_asc':
          return a.total - b.total;
        case 'amount_desc':
          return b.total - a.total;
        default:
          return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
      }
    });
    return list;
  }, [invoices, filter, sort, search]);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.statsRow}>
        <View style={styles.statBox}>
          <Text style={styles.statLabel}>Total encaissé</Text>
          <Text style={[styles.statValue, styles.green]}>
            {formatMoney(allTimeStats.collected, profile.currency)}
          </Text>
        </View>
        <View style={styles.statBox}>
          <Text style={styles.statLabel}>En attente</Text>
          <Text style={[styles.statValue, styles.orange]}>
            {formatMoney(allTimeStats.pending, profile.currency)}
          </Text>
        </View>
      </View>

      <TextInput
        style={styles.search}
        value={search}
        onChangeText={setSearch}
        placeholder="Rechercher client ou n° facture..."
        placeholderTextColor={colors.textSecondary}
      />

      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.filters}>
        {FILTERS.map((f) => (
          <Pressable
            key={f.key}
            style={[styles.chip, filter === f.key && styles.chipActive]}
            onPress={() => setFilter(f.key)}
          >
            <Text style={[styles.chipText, filter === f.key && styles.chipTextActive]}>
              {f.label}
            </Text>
          </Pressable>
        ))}
      </ScrollView>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.filters}>
        {SORTS.map((s) => (
          <Pressable
            key={s.key}
            style={[styles.chip, sort === s.key && styles.chipActive]}
            onPress={() => setSort(s.key)}
          >
            <Text style={[styles.chipText, sort === s.key && styles.chipTextActive]}>
              {s.label}
            </Text>
          </Pressable>
        ))}
      </ScrollView>

      {filtered.length === 0 ? (
        <Text style={styles.empty}>Aucune facture trouvée</Text>
      ) : (
        filtered.map((inv) => (
          <InvoiceItem
            key={inv.id}
            invoice={inv}
            onPress={() => router.push({ pathname: '/invoice-detail', params: { id: inv.id } })}
          />
        ))
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl },
  statsRow: {
    flexDirection: 'row',
    gap: spacing.md,
    marginBottom: spacing.lg,
  },
  statBox: {
    flex: 1,
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  statLabel: { color: colors.textSecondary, fontSize: 11, marginBottom: 4 },
  statValue: { fontSize: 18, fontWeight: '700' },
  green: { color: colors.accentLight },
  orange: { color: colors.warning },
  search: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    color: colors.text,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  filters: { marginBottom: spacing.sm },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.sm,
    backgroundColor: colors.section,
    marginRight: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  chipActive: {
    backgroundColor: colors.accent,
    borderColor: colors.accent,
  },
  chipText: { color: colors.textSecondary, fontSize: 13 },
  chipTextActive: { color: colors.background, fontWeight: '600' },
  empty: {
    color: colors.textSecondary,
    textAlign: 'center',
    marginTop: spacing.xl,
  },
});
