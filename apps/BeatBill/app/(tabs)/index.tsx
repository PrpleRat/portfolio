import { ScrollView, View, Text, Pressable, StyleSheet, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { SummaryCard } from '@/components/SummaryCard';
import { InvoiceItem } from '@/components/InvoiceItem';
import { ExpoGoBanner } from '@/components/ExpoGoBanner';
import { useInvoices, useProfile, useAppData } from '@/hooks/useAppData';
import { seedDemoData } from '@/utils/seedDemo';
import { isExpoGo } from '@/utils/expoGo';

export default function HomeScreen() {
  const router = useRouter();
  const { recentInvoices, monthlyStats, loading } = useInvoices();
  const { profile } = useProfile();
  const { refresh } = useAppData();

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator color={colors.accent} size="large" />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.headerRow}>
        <View style={styles.header}>
          <Text style={styles.logo}>BeatBill</Text>
          <Text style={styles.tagline}>Factures pro en 60s</Text>
        </View>
        <Pressable style={styles.searchBtn} onPress={() => router.push('/search')}>
          <Ionicons name="search" size={22} color={colors.accentLight} />
        </Pressable>
      </View>

      <ExpoGoBanner
        onLoadDemo={
          isExpoGo()
            ? async () => {
                await seedDemoData();
                await refresh();
              }
            : undefined
        }
      />

      <SummaryCard
        collected={monthlyStats.collected}
        pending={monthlyStats.pending}
        count={monthlyStats.count}
        currency={profile.currency}
      />

      <Pressable style={styles.cta} onPress={() => router.push('/new-invoice')}>
        <Ionicons name="add" size={22} color={colors.background} />
        <Text style={styles.ctaText}>Nouvelle facture</Text>
      </Pressable>

      <Pressable style={styles.ctaSecondary} onPress={() => router.push('/new-quote')}>
        <Ionicons name="document-outline" size={20} color={colors.accentLight} />
        <Text style={styles.ctaSecondaryText}>Nouveau devis</Text>
      </Pressable>

      <Text style={styles.sectionTitle}>Factures récentes</Text>
      {recentInvoices.length === 0 ? (
        <View style={styles.empty}>
          <Ionicons name="document-text-outline" size={48} color={colors.textSecondary} />
          <Text style={styles.emptyText}>Aucune facture pour l'instant</Text>
          <Text style={styles.emptyHint}>Crée ta première facture en moins d'une minute</Text>
        </View>
      ) : (
        recentInvoices.map((inv) => (
          <InvoiceItem
            key={inv.id}
            invoice={inv}
            onPress={() => router.push({ pathname: '/invoice-detail', params: { id: inv.id } })}
          />
        ))
      )}

      <View style={styles.links}>
        <Pressable onPress={() => router.push('/quotes')}>
          <Text style={styles.link}>Devis</Text>
        </Pressable>
        <Text style={styles.linkSep}>|</Text>
        <Pressable onPress={() => router.push('/reports')}>
          <Text style={styles.link}>Rapports</Text>
        </Pressable>
        <Text style={styles.linkSep}>|</Text>
        <Pressable onPress={() => router.push('/settings')}>
          <Text style={styles.link}>Réglages</Text>
        </Pressable>
      </View>
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
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing.lg,
  },
  header: { flex: 1 },
  searchBtn: {
    padding: spacing.sm,
    backgroundColor: colors.card,
    borderRadius: radius.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  logo: {
    color: colors.text,
    fontSize: 32,
    fontWeight: '800',
    letterSpacing: -0.5,
  },
  tagline: {
    color: colors.textSecondary,
    fontSize: 14,
    marginTop: 4,
  },
  cta: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    marginBottom: spacing.lg,
  },
  ctaText: {
    color: colors.background,
    fontSize: 17,
    fontWeight: '700',
  },
  ctaSecondary: {
    borderRadius: radius.md,
    padding: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.separator,
    backgroundColor: colors.card,
  },
  ctaSecondaryText: {
    color: colors.accentLight,
    fontSize: 15,
    fontWeight: '600',
  },
  sectionTitle: {
    color: colors.textSecondary,
    fontSize: 12,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: spacing.md,
  },
  empty: {
    alignItems: 'center',
    padding: spacing.xl,
    backgroundColor: colors.card,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  emptyText: {
    color: colors.text,
    fontSize: 16,
    fontWeight: '600',
    marginTop: spacing.md,
  },
  emptyHint: {
    color: colors.textSecondary,
    fontSize: 13,
    marginTop: spacing.xs,
    textAlign: 'center',
  },
  links: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: spacing.lg,
    gap: spacing.sm,
  },
  link: {
    color: colors.accentLight,
    fontSize: 14,
  },
  linkSep: { color: colors.textSecondary },
});
