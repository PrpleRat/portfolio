import { Pressable, View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import type { Split } from '@/types';
import { formatDate } from '@/types';

interface Props {
  split: Split;
  onPress: () => void;
}

export function SplitItem({ split, onPress }: Props) {
  const isComplete = split.status === 'complete';

  return (
    <Pressable style={styles.card} onPress={onPress}>
      <View style={styles.row}>
        <View style={styles.info}>
          <Text style={styles.title} numberOfLines={1}>
            {split.title}
          </Text>
          <Text style={styles.meta}>
            {split.collaborators.length} collab. · {formatDate(split.createdAt)}
          </Text>
        </View>
        <View style={styles.right}>
          {isComplete ? (
            <Ionicons name="checkmark-circle" size={22} color={colors.success} />
          ) : (
            <Ionicons name="time-outline" size={22} color={colors.warning} />
          )}
          <Ionicons name="chevron-forward" size={18} color={colors.textSecondary} />
        </View>
      </View>
    </Pressable>
  );
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
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  info: { flex: 1, marginRight: spacing.sm },
  title: {
    color: colors.text,
    fontSize: 16,
    fontWeight: '600',
  },
  meta: {
    color: colors.textSecondary,
    fontSize: 12,
    marginTop: 4,
  },
  right: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
});
