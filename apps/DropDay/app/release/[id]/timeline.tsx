import { ScrollView, View, Text, StyleSheet } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { colors, spacing } from '@/constants/theme';
import { useRelease } from '@/hooks/useReleases';
import { daysUntil, formatDate, releaseProgress } from '@/types';
import { ProgressBar } from '@/components/ProgressBar';
import { TaskItem } from '@/components/TaskItem';
import { TimelineSectionBlock } from '@/components/TimelineSection';
import { getTimelineSection, type TimelineSection } from '@/utils/urgencyLevel';

const SECTION_ORDER: TimelineSection[] = ['today', 'this_week', 'next_week', 'later'];

export default function TimelineScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { release, toggleTask, assignTask, postponeTask } = useRelease(id);

  if (!release) return null;

  const progress = releaseProgress(release);
  const days = daysUntil(release.releaseDate);
  const jLabel = days >= 0 ? `J-${days}` : `J+${Math.abs(days)}`;

  const grouped: Record<TimelineSection, typeof release.tasks> = {
    today: [],
    this_week: [],
    next_week: [],
    later: [],
  };

  const sortedTasks = [...release.tasks].sort(
    (a, b) => new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime()
  );

  for (const task of sortedTasks) {
    grouped[getTimelineSection(task)].push(task);
  }

  // Completed tasks in "later" section at top
  const completed = sortedTasks.filter((t) => t.completed);
  grouped.later = [
    ...completed.filter((t) => !grouped.today.includes(t) && !grouped.this_week.includes(t)),
    ...grouped.later.filter((t) => !t.completed),
  ];

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.hero}>
        <Text style={styles.heroTitle}>
          {release.format.toUpperCase()} « {release.title} » · {jLabel}
        </Text>
        <View style={styles.progressRow}>
          <ProgressBar progress={progress} height={10} />
          <Text style={styles.progressText}>{progress}% complété</Text>
        </View>
        <Text style={styles.releaseDate}>Sortie · {formatDate(release.releaseDate)}</Text>
      </View>

      {SECTION_ORDER.map((section) => {
        const tasks = grouped[section];
        if (tasks.length === 0) return null;
        return (
          <TimelineSectionBlock key={section} section={section}>
            {tasks.map((task) => (
              <TaskItem
                key={task.id}
                task={task}
                releaseTitle={release.title}
                onToggle={() => toggleTask(release.id, task.id)}
                onAssign={(name) => assignTask(release.id, task.id, name)}
                onPostpone={(d) => postponeTask(release.id, task.id, d)}
              />
            ))}
          </TimelineSectionBlock>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
  hero: {
    backgroundColor: colors.card,
    borderRadius: 12,
    padding: spacing.md,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  heroTitle: {
    color: colors.text,
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  progressRow: { marginTop: spacing.md, gap: spacing.xs },
  progressText: { color: colors.textSecondary, fontSize: 13, marginTop: spacing.xs },
  releaseDate: { color: colors.textSecondary, fontSize: 12, marginTop: spacing.sm },
});
