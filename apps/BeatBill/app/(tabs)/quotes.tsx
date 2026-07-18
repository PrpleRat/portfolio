import { FlatList, View, Text, Pressable, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { QuoteItem } from '@/components/QuoteItem';
import { useQuotes } from '@/hooks/useAppData';

export default function QuotesScreen() {
  const router = useRouter();
  const { quotes } = useQuotes();

  return (
    <View style={styles.container}>
      <Pressable style={styles.cta} onPress={() => router.push('/new-quote')}>
        <Ionicons name="add" size={22} color={colors.background} />
        <Text style={styles.ctaText}>Nouveau devis</Text>
      </Pressable>

      <FlatList
        data={quotes}
        keyExtractor={(q) => q.id}
        contentContainerStyle={styles.list}
        ListEmptyComponent={
          <View style={styles.empty}>
            <Ionicons name="document-outline" size={48} color={colors.textSecondary} />
            <Text style={styles.emptyText}>Aucun devis</Text>
            <Text style={styles.emptyHint}>Crée un devis et convertis-le en facture en un clic</Text>
          </View>
        }
        renderItem={({ item }) => (
          <QuoteItem
            quote={item}
            onPress={() => router.push({ pathname: '/quote-detail', params: { id: item.id } })}
          />
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  cta: {
    margin: spacing.lg,
    marginBottom: spacing.sm,
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
  },
  ctaText: { color: colors.background, fontSize: 16, fontWeight: '700' },
  list: { paddingHorizontal: spacing.lg, paddingBottom: spacing.xl },
  empty: {
    alignItems: 'center',
    padding: spacing.xl,
    backgroundColor: colors.card,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.separator,
    marginTop: spacing.md,
  },
  emptyText: { color: colors.text, fontSize: 16, fontWeight: '600', marginTop: spacing.md },
  emptyHint: { color: colors.textSecondary, fontSize: 13, marginTop: spacing.xs, textAlign: 'center' },
});
