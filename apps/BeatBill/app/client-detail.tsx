import { ScrollView, View, Text, StyleSheet } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { colors, radius, spacing } from '@/constants/theme';
import { InvoiceItem } from '@/components/InvoiceItem';
import { useClients, useProfile } from '@/hooks/useAppData';
import { formatMoney } from '@/types';

export default function ClientDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { clients } = useClients();
  const { profile } = useProfile();

  const client = clients.find((c) => c.id === id);

  if (!client) {
    return (
      <View style={styles.centered}>
        <Text style={styles.notFound}>Client introuvable</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.name}>{client.name}</Text>
        <Text style={styles.email}>{client.email}</Text>
        <Text style={styles.stats}>
          {client.invoiceCount} facture(s) · Total encaissé{' '}
          {formatMoney(client.totalCollected, profile.currency)}
        </Text>
      </View>

      <Text style={styles.sectionTitle}>Factures</Text>
      {client.invoices.length === 0 ? (
        <Text style={styles.empty}>Aucune facture avec ce client</Text>
      ) : (
        client.invoices.map((inv) => (
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
  centered: {
    flex: 1,
    backgroundColor: colors.background,
    alignItems: 'center',
    justifyContent: 'center',
  },
  notFound: { color: colors.textSecondary },
  header: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.lg,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  name: { color: colors.text, fontSize: 24, fontWeight: '700' },
  email: { color: colors.textSecondary, fontSize: 14, marginTop: 4 },
  stats: { color: colors.accentLight, fontSize: 14, fontWeight: '600', marginTop: spacing.md },
  sectionTitle: {
    color: colors.textSecondary,
    fontSize: 12,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: spacing.md,
  },
  empty: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.lg },
});
