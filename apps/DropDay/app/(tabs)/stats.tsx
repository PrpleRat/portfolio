import { ScrollView, View, Text, StyleSheet, ActivityIndicator } from 'react-native';
import { colors, radius, spacing } from '@/constants/theme';
import { useReleases } from '@/hooks/useReleases';
import { computeGlobalStats } from '@/utils/compareReleases';
import { formatMoney, releaseProgress, streamsWeek1Total } from '@/types';

export default function StatsScreen() {
  const { releases, loading, profile } = useReleases();

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator color={colors.accent} size="large" />
      </View>
    );
  }

  const stats = computeGlobalStats(releases);
  const maxStreams = Math.max(...stats.streamsByRelease.map((s) => s.streams), 1);

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.grid}>
        <StatBox label="Releases" value={String(stats.totalReleases)} />
        <StatBox
          label="Budget promo"
          value={formatMoney(stats.totalBudget, profile.currency)}
        />
        <StatBox label="Discipline moy." value={`${stats.avgCompletion}%`} />
      </View>

      {stats.streamsByRelease.length > 0 && (
        <>
          <Text style={styles.sectionTitle}>Streams par release (J+7)</Text>
          {stats.streamsByRelease.map((item) => (
            <View key={item.title} style={styles.barRow}>
              <Text style={styles.barLabel} numberOfLines={1}>
                {item.title}
              </Text>
              <View style={styles.barTrack}>
                <View
                  style={[
                    styles.barFill,
                    { width: `${(item.streams / maxStreams) * 100}%` },
                  ]}
                />
              </View>
              <Text style={styles.barValue}>{item.streams}</Text>
            </View>
          ))}
        </>
      )}

      {stats.followersEvolution.length > 0 && (
        <>
          <Text style={styles.sectionTitle}>Followers gagnés</Text>
          {stats.followersEvolution.map((item) => (
            <View key={item.title} style={styles.listRow}>
              <Text style={styles.listLabel}>{item.title}</Text>
              <Text style={[styles.listValue, item.gained >= 0 && styles.positive]}>
                {item.gained >= 0 ? '+' : ''}
                {item.gained}
              </Text>
            </View>
          ))}
        </>
      )}

      {stats.bestRelease && (
        <View style={styles.highlight}>
          <Text style={styles.highlightLabel}>🏆 Meilleure release</Text>
          <Text style={styles.highlightTitle}>{stats.bestRelease.title}</Text>
          <Text style={styles.highlightMeta}>
            {streamsWeek1Total(stats.bestRelease.postMortem!)} streams ·{' '}
            {releaseProgress(stats.bestRelease)}% checklist
          </Text>
        </View>
      )}

      {stats.worstRelease && stats.totalReleases > 1 && (
        <View style={[styles.highlight, styles.highlightMuted]}>
          <Text style={styles.highlightLabel}>📉 À améliorer</Text>
          <Text style={styles.highlightTitle}>{stats.worstRelease.title}</Text>
          <Text style={styles.highlightMeta}>
            {streamsWeek1Total(stats.worstRelease.postMortem!)} streams J+7
          </Text>
        </View>
      )}

      {releases.length === 0 && (
        <Text style={styles.empty}>Crée des releases et remplis tes post-mortems pour voir tes stats.</Text>
      )}
    </ScrollView>
  );
}

function StatBox({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.statBox}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
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
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
    marginBottom: spacing.lg,
  },
  statBox: {
    flex: 1,
    minWidth: '30%',
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  statValue: { color: colors.text, fontSize: 20, fontWeight: '800' },
  statLabel: { color: colors.textSecondary, fontSize: 12, marginTop: 4 },
  sectionTitle: {
    color: colors.textSecondary,
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 1,
    marginBottom: spacing.sm,
    marginTop: spacing.md,
  },
  barRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.sm,
  },
  barLabel: { width: 80, color: colors.text, fontSize: 13 },
  barTrack: {
    flex: 1,
    height: 10,
    backgroundColor: colors.future,
    borderRadius: 5,
    overflow: 'hidden',
  },
  barFill: {
    height: '100%',
    backgroundColor: colors.accent,
    borderRadius: 5,
  },
  barValue: { width: 40, color: colors.textSecondary, fontSize: 12, textAlign: 'right' },
  listRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.separator,
  },
  listLabel: { color: colors.text, fontSize: 14 },
  listValue: { color: colors.textSecondary, fontWeight: '600' },
  positive: { color: colors.success },
  highlight: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginTop: spacing.lg,
    borderLeftWidth: 4,
    borderLeftColor: colors.success,
  },
  highlightMuted: { borderLeftColor: colors.warning },
  highlightLabel: { color: colors.textSecondary, fontSize: 12 },
  highlightTitle: { color: colors.text, fontSize: 17, fontWeight: '700', marginTop: 4 },
  highlightMeta: { color: colors.textSecondary, fontSize: 13, marginTop: 4 },
  empty: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.xl },
});
