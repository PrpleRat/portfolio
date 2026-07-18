import { View, Text, StyleSheet } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { colors, spacing } from '@/constants/theme';
import { useRelease, useReleases } from '@/hooks/useReleases';
import { PostMortemForm } from '@/components/PostMortemForm';
import { emptyPostMortem } from '@/types';
import { compareReleaseToHistory, isPostMortemUnlocked, daysSinceRelease } from '@/utils/compareReleases';
import { usePurchase } from '@/hooks/usePurchase';
import { Ionicons } from '@expo/vector-icons';

export default function PostMortemScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { release, savePostMortem } = useRelease(id);
  const { releases } = useReleases();
  const { isPro } = usePurchase(releases.length);
  const [data, setData] = useState(release?.postMortem ?? emptyPostMortem());
  const [saving, setSaving] = useState(false);

  if (!release) return null;

  const unlocked = isPostMortemUnlocked(release);
  const days = daysSinceRelease(release);
  const comparison = compareReleaseToHistory(release, releases);

  if (!isPro && releases.length > 1) {
    return (
      <View style={styles.locked}>
        <Ionicons name="lock-closed" size={48} color={colors.textSecondary} />
        <Text style={styles.lockedTitle}>Post-mortem Pro</Text>
        <Text style={styles.lockedText}>
          Débloque DropDay Pro pour accéder aux bilans et comparaisons.
        </Text>
      </View>
    );
  }

  if (!unlocked) {
    return (
      <View style={styles.locked}>
        <Ionicons name="time-outline" size={48} color={colors.accentLight} />
        <Text style={styles.lockedTitle}>Bilan disponible J+7</Text>
        <Text style={styles.lockedText}>
          Ta release sort le {new Date(release.releaseDate).toLocaleDateString('fr-FR')}.
          {days >= 0
            ? ` Plus que ${Math.max(0, 7 - days)} jours avant le bilan.`
            : ` Sortie il y a ${days} jours — ${days >= 7 ? 'prêt !' : 'encore un peu…'}`}
        </Text>
      </View>
    );
  }

  if (release.postMortem?.filledAt) {
    return (
      <View style={styles.container}>
        <View style={styles.doneBanner}>
          <Text style={styles.doneTitle}>Bilan enregistré</Text>
          <Text style={styles.doneDate}>
            {new Date(release.postMortem.filledAt).toLocaleDateString('fr-FR')}
          </Text>
        </View>
        {comparison.streamsMessage && (
          <Text style={styles.compare}>{comparison.streamsMessage}</Text>
        )}
        {comparison.budgetMessage && (
          <Text style={styles.compare}>{comparison.budgetMessage}</Text>
        )}
        <PostMortemForm
          data={release.postMortem}
          onChange={setData}
          onSave={async () => {
            setSaving(true);
            await savePostMortem(release.id, data);
            setSaving(false);
          }}
          saving={saving}
        />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.intro}>
        « {release.title} » est sortie il y a {days} jours — fais ton bilan !
      </Text>
      {comparison.streamsMessage && (
        <Text style={styles.compare}>{comparison.streamsMessage}</Text>
      )}
      <PostMortemForm
        data={data}
        onChange={setData}
        onSave={async () => {
          setSaving(true);
          await savePostMortem(release.id, data);
          setSaving(false);
        }}
        saving={saving}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  locked: {
    flex: 1,
    backgroundColor: colors.background,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.xl,
  },
  lockedTitle: { color: colors.text, fontSize: 20, fontWeight: '700', marginTop: spacing.md },
  lockedText: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.sm, lineHeight: 22 },
  intro: {
    color: colors.text,
    fontSize: 16,
    padding: spacing.lg,
    lineHeight: 24,
  },
  compare: {
    color: colors.accentLight,
    fontSize: 14,
    paddingHorizontal: spacing.lg,
    marginBottom: spacing.sm,
    fontStyle: 'italic',
  },
  doneBanner: {
    backgroundColor: colors.success + '22',
    padding: spacing.md,
    margin: spacing.lg,
    borderRadius: 12,
    borderLeftWidth: 4,
    borderLeftColor: colors.success,
  },
  doneTitle: { color: colors.success, fontWeight: '700' },
  doneDate: { color: colors.textSecondary, fontSize: 13, marginTop: 4 },
});
