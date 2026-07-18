import { View, Text, Pressable, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import type { Release } from '@/types';
import { daysUntil, formatDate, releaseProgress } from '@/types';
import { ProgressBar } from '@/components/ProgressBar';
import { getUrgencyLevel, urgencyLabel } from '@/utils/urgencyLevel';

interface ReleaseCardProps {
  release: Release;
  compact?: boolean;
}

export function ReleaseCard({ release, compact }: ReleaseCardProps) {
  const router = useRouter();
  const progress = releaseProgress(release);
  const days = daysUntil(release.releaseDate);
  const jLabel = days >= 0 ? `J-${days}` : `J+${Math.abs(days)}`;

  const nextTask = release.tasks
    .filter((t) => !t.completed)
    .sort((a, b) => new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime())[0];

  return (
    <Pressable
      style={[styles.card, compact && styles.compact]}
      onPress={() => router.push(`/release/${release.id}/timeline`)}
    >
      <View style={styles.header}>
        <View style={[styles.artwork, { backgroundColor: release.artworkColor ?? colors.accent }]}>
          <Text style={styles.emoji}>🎵</Text>
        </View>
        <View style={styles.info}>
          <Text style={styles.title} numberOfLines={1}>
            {release.title}
          </Text>
          <Text style={styles.meta}>
            {formatDate(release.releaseDate)} · {jLabel}
          </Text>
        </View>
        <Ionicons name="chevron-forward" size={20} color={colors.textSecondary} />
      </View>

      {!compact && (
        <>
          <View style={styles.progressRow}>
            <ProgressBar progress={progress} />
            <Text style={styles.progressText}>{progress}%</Text>
          </View>
          {nextTask && (
            <View style={styles.nextTask}>
              <UrgencyDot level={getUrgencyLevel(nextTask)} />
              <Text style={styles.nextLabel} numberOfLines={1}>
                {urgencyLabel(nextTask)} — {nextTask.title}
              </Text>
            </View>
          )}
        </>
      )}
    </Pressable>
  );
}

function UrgencyDot({ level }: { level: ReturnType<typeof getUrgencyLevel> }) {
  const color =
    level === 'overdue'
      ? colors.error
      : level === 'urgent'
        ? colors.warning
        : level === 'done'
          ? colors.success
          : colors.accent;
  return <View style={[styles.dot, { backgroundColor: color }]} />;
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  compact: {
    padding: spacing.sm,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  artwork: {
    width: 48,
    height: 48,
    borderRadius: radius.sm,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emoji: { fontSize: 22 },
  info: { flex: 1 },
  title: {
    color: colors.text,
    fontSize: 17,
    fontWeight: '700',
  },
  meta: {
    color: colors.textSecondary,
    fontSize: 13,
    marginTop: 2,
  },
  progressRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginTop: spacing.md,
  },
  progressText: {
    color: colors.textSecondary,
    fontSize: 13,
    fontWeight: '600',
    minWidth: 36,
  },
  nextTask: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginTop: spacing.sm,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  nextLabel: {
    color: colors.textSecondary,
    fontSize: 13,
    flex: 1,
  },
});
