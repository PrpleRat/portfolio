import { View, Text, StyleSheet } from 'react-native';
import { colors, spacing } from '@/constants/theme';
import type { TimelineSection } from '@/utils/urgencyLevel';
import { SECTION_LABELS } from '@/utils/urgencyLevel';
import type { ReactNode } from 'react';

interface TimelineSectionProps {
  section: TimelineSection;
  children: ReactNode;
}

export function TimelineSectionBlock({ section, children }: TimelineSectionProps) {
  if (!children) return null;
  return (
    <View style={styles.block}>
      <View style={styles.header}>
        <Text style={styles.label}>{SECTION_LABELS[section]}</Text>
        <View style={styles.line} />
      </View>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  block: { marginBottom: spacing.lg },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.sm,
  },
  label: {
    color: colors.textSecondary,
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 1,
  },
  line: {
    flex: 1,
    height: 1,
    backgroundColor: colors.separator,
  },
});
