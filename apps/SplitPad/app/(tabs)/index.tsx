import { ScrollView, View, Text, Pressable, StyleSheet, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { SplitItem } from '@/components/SplitItem';
import { PaywallModal } from '@/components/PaywallModal';
import { ExpoGoBanner } from '@/components/ExpoGoBanner';
import { useSplits, useCollaborators, useAppData } from '@/hooks/useAppData';
import { usePurchase } from '@/hooks/usePurchase';
import { seedDemoData } from '@/utils/seedDemo';
import { isExpoGo } from '@/utils/expoGo';

export default function HomeScreen() {
  const router = useRouter();
  const { recentSplits, splitCount, loading } = useSplits();
  const { frequentCollaborators } = useCollaborators();
  const { refresh } = useAppData();
  const { canCreateSplit, purchasePro, restorePurchase, price } = usePurchase();
  const [paywallVisible, setPaywallVisible] = useState(false);
  const [purchasing, setPurchasing] = useState(false);

  const handleNewSplit = () => {
    if (!canCreateSplit(splitCount)) {
      setPaywallVisible(true);
      return;
    }
    router.push('/new-split');
  };

  const handlePurchase = async () => {
    setPurchasing(true);
    try {
      const ok = await purchasePro();
      if (ok) setPaywallVisible(false);
    } finally {
      setPurchasing(false);
    }
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
          <Text style={styles.logo}>SplitPad</Text>
          <Text style={styles.tagline}>Splits en 90 secondes</Text>
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

        <Pressable style={styles.cta} onPress={handleNewSplit}>
          <Ionicons name="add" size={22} color={colors.text} />
          <Text style={styles.ctaText}>Nouveau split sheet</Text>
        </Pressable>

        <Text style={styles.sectionTitle}>Récents</Text>
        {recentSplits.length === 0 ? (
          <View style={styles.empty}>
            <Ionicons name="document-text-outline" size={48} color={colors.textSecondary} />
            <Text style={styles.emptyText}>Crée ton premier split avant de quitter le studio</Text>
          </View>
        ) : (
          recentSplits.map((split) => (
            <SplitItem
              key={split.id}
              split={split}
              onPress={() => router.push({ pathname: '/split-detail', params: { id: split.id } })}
            />
          ))
        )}

        {frequentCollaborators.length > 0 && (
          <>
            <Text style={styles.sectionTitle}>Mes collaborateurs fréquents</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.frequentRow}>
              {frequentCollaborators.map((c) => (
                <Pressable
                  key={c.id}
                  style={styles.avatarCard}
                  onPress={() =>
                    router.push({
                      pathname: '/new-split',
                      params: { addCollab: JSON.stringify(c) },
                    })
                  }
                >
                  <View style={styles.avatar}>
                    <Text style={styles.avatarText}>{c.name.charAt(0).toUpperCase()}</Text>
                  </View>
                  <Text style={styles.avatarName} numberOfLines={1}>
                    {c.name}
                  </Text>
                </Pressable>
              ))}
            </ScrollView>
          </>
        )}
      </ScrollView>

      <PaywallModal
        visible={paywallVisible}
        loading={purchasing}
        price={price}
        onPurchase={handlePurchase}
        onRestore={async () => {
          setPurchasing(true);
          await restorePurchase();
          setPurchasing(false);
          setPaywallVisible(false);
        }}
        onClose={() => setPaywallVisible(false)}
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
    color: colors.text,
    fontSize: 17,
    fontWeight: '700',
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
    color: colors.textSecondary,
    fontSize: 14,
    marginTop: spacing.md,
    textAlign: 'center',
  },
  frequentRow: { marginBottom: spacing.lg },
  avatarCard: {
    alignItems: 'center',
    marginRight: spacing.md,
    width: 72,
  },
  avatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.xs,
  },
  avatarText: {
    color: colors.text,
    fontSize: 22,
    fontWeight: '700',
  },
  avatarName: {
    color: colors.textSecondary,
    fontSize: 11,
    textAlign: 'center',
  },
});
