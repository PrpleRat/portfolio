import { useMemo, useState } from 'react';
import { FlatList, View, Text, TextInput, Pressable, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { useAppData } from '@/hooks/useAppData';
import { formatMoney } from '@/types';
import { globalSearch } from '@/utils/globalSearch';

export default function SearchScreen() {
  const router = useRouter();
  const { invoices, quotes, clients } = useAppData();
  const [query, setQuery] = useState('');

  const results = useMemo(
    () => globalSearch(query, invoices, quotes, clients),
    [query, invoices, quotes, clients]
  );

  const handlePress = (type: string, id: string) => {
    if (type === 'invoice') router.push({ pathname: '/invoice-detail', params: { id } });
    else if (type === 'quote') router.push({ pathname: '/quote-detail', params: { id } });
    else router.push({ pathname: '/client-detail', params: { id } });
  };

  return (
    <View style={styles.container}>
      <View style={styles.searchBox}>
        <Ionicons name="search" size={20} color={colors.textSecondary} />
        <TextInput
          style={styles.input}
          value={query}
          onChangeText={setQuery}
          placeholder="Facture, devis, client..."
          placeholderTextColor={colors.textSecondary}
          autoFocus
          clearButtonMode="while-editing"
        />
      </View>

      <FlatList
        data={results}
        keyExtractor={(item) => `${item.type}-${item.id}`}
        contentContainerStyle={styles.list}
        keyboardShouldPersistTaps="handled"
        ListEmptyComponent={
          query.trim() ? (
            <Text style={styles.empty}>Aucun résultat pour « {query} »</Text>
          ) : (
            <Text style={styles.hint}>Recherche dans factures, devis et clients</Text>
          )
        }
        renderItem={({ item }) => (
          <Pressable style={styles.row} onPress={() => handlePress(item.type, item.id)}>
            <Ionicons
              name={
                item.type === 'invoice'
                  ? 'document-text-outline'
                  : item.type === 'quote'
                    ? 'document-outline'
                    : 'person-outline'
              }
              size={22}
              color={colors.accent}
            />
            <View style={styles.rowInfo}>
              <Text style={styles.rowTitle}>{item.title}</Text>
              <Text style={styles.rowSub}>{item.subtitle}</Text>
            </View>
            {item.amount != null && item.currency && (
              <Text style={styles.rowAmount}>{formatMoney(item.amount, item.currency)}</Text>
            )}
          </Pressable>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  searchBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    margin: spacing.lg,
    padding: spacing.md,
    backgroundColor: colors.card,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  input: { flex: 1, color: colors.text, fontSize: 16 },
  list: { paddingHorizontal: spacing.lg, paddingBottom: spacing.xl },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    padding: spacing.md,
    backgroundColor: colors.card,
    borderRadius: radius.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  rowInfo: { flex: 1 },
  rowTitle: { color: colors.text, fontWeight: '600', fontSize: 15 },
  rowSub: { color: colors.textSecondary, fontSize: 12, marginTop: 2 },
  rowAmount: { color: colors.accentLight, fontWeight: '700' },
  empty: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.xl },
  hint: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.xl, fontSize: 14 },
});
