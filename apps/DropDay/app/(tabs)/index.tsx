import {
  ScrollView,
  View,
  Text,
  Pressable,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { ReleaseCard } from '@/components/ReleaseCard';
import { PaywallModal } from '@/components/PaywallModal';
import { useActiveRelease, useReleases } from '@/hooks/useReleases';
import { usePurchase } from '@/hooks/usePurchase';
import { streamsWeek1Total } from '@/types';

export default function HomeScreen() {
  const router = useRouter();
  const { loading, releases } = useReleases();
  const { current, upcoming, past } = useActiveRelease();
  const { needsPaywall, purchasePro, restorePurchase, priceLabel } = usePurchase(
    releases.length
  );
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [purchaseLoading, setPurchaseLoading] = useState(false);

  const recentPostMortems = past
    .filter((r) => r.postMortem?.filledAt)
    .slice(-3)
    .reverse();

  const handleNewRelease = () => {
    if (needsPaywall) {
      setPaywallOpen(true);
      return;
    }
    router.push('/new-release');
  };

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator color={colors.accent} size="large" />
      </View>
    );
  }

  return (
    <>
      <ScrollView style={styles.container} contentContainerStyle={styles.content}>
        <View style={styles.header}>
          <Text style={styles.logo}>DropDay</Text>
          <Text style={styles.tagline}>Planifie ta sortie comme un pro</Text>
        </View>

        <Text style={styles.sectionTitle}>Release en cours</Text>
        {current ? (
          <ReleaseCard release={current} />
        ) : (
          <View style={styles.emptyCard}>
            <Text style={styles.emptyText}>Aucune release planifiée</Text>
            <Text style={styles.emptyHint}>Crée ta première timeline de sortie</Text>
          </View>
        )}

        {upcoming.length > 0 && (
          <>
            <Text style={styles.sectionTitle}>Prochaines releases</Text>
            {upcoming.map((r) => (
              <ReleaseCard key={r.id} release={r} compact />
            ))}
          </>
        )}

        {recentPostMortems.length > 0 && (
          <>
            <Text style={styles.sectionTitle}>Post-mortems récents</Text>
            {recentPostMortems.map((r) => (
              <Pressable
                key={r.id}
                style={styles.pmCard}
                onPress={() => router.push(`/release/${r.id}/postmortem`)}
              >
                <Text style={styles.pmTitle}>{r.title}</Text>
                <Text style={styles.pmStats}>
                  {streamsWeek1Total(r.postMortem!)} streams J+7 · ★{' '}
                  {r.postMortem!.rating}/5
                </Text>
              </Pressable>
            ))}
          </>
        )}

        <Pressable style={styles.cta} onPress={handleNewRelease}>
          <Ionicons name="add" size={22} color={colors.white} />
          <Text style={styles.ctaText}>Nouvelle release</Text>
        </Pressable>
      </ScrollView>

      <PaywallModal
        visible={paywallOpen}
        priceLabel={priceLabel}
        loading={purchaseLoading}
        onClose={() => setPaywallOpen(false)}
        onPurchase={async () => {
          setPurchaseLoading(true);
          const ok = await purchasePro();
          setPurchaseLoading(false);
          if (ok) {
            setPaywallOpen(false);
            router.push('/new-release');
          }
        }}
        onRestore={async () => {
          setPurchaseLoading(true);
          const ok = await restorePurchase();
          setPurchaseLoading(false);
          if (ok) setPaywallOpen(false);
        }}
      />
    </>
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
  header: { marginBottom: spacing.lg },
  logo: {
    color: colors.text,
    fontSize: 32,
    fontWeight: '800',
    letterSpacing: -0.5,
  },
  tagline: { color: colors.textSecondary, fontSize: 14, marginTop: 4 },
  sectionTitle: {
    color: colors.textSecondary,
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 1,
    marginBottom: spacing.sm,
    marginTop: spacing.md,
  },
  emptyCard: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.lg,
    borderWidth: 1,
    borderColor: colors.separator,
    alignItems: 'center',
  },
  emptyText: { color: colors.text, fontSize: 16, fontWeight: '600' },
  emptyHint: { color: colors.textSecondary, fontSize: 13, marginTop: 4 },
  pmCard: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  pmTitle: { color: colors.text, fontWeight: '600', fontSize: 15 },
  pmStats: { color: colors.textSecondary, fontSize: 13, marginTop: 4 },
  cta: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    marginTop: spacing.lg,
  },
  ctaText: { color: colors.white, fontSize: 17, fontWeight: '700' },
});
