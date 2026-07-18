import { View, Text, StyleSheet } from 'react-native';
import { colors, radius, spacing } from '@/constants/theme';
import type { UrgencyLevel } from '@/utils/urgencyLevel';
import { urgencyColor } from '@/utils/urgencyLevel';

interface UrgencyBadgeProps {
  level: UrgencyLevel;
  label?: string;
}

const LEVEL_TEXT: Record<UrgencyLevel, string> = {
  overdue: 'EN RETARD',
  urgent: 'URGENT',
  soon: 'BIENTÔT',
  ok: 'OK',
  future: 'PLANIFIÉ',
  done: 'FAIT',
};

export function UrgencyBadge({ level, label }: UrgencyBadgeProps) {
  const text = label ?? LEVEL_TEXT[level];
  const bg = urgencyColor(level);
  return (
    <View style={[styles.badge, { backgroundColor: bg + '33', borderColor: bg }]}>
      <Text style={[styles.text, { color: bg }]}>{text}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    alignSelf: 'flex-start',
    paddingHorizontal: spacing.sm,
    paddingVertical: 2,
    borderRadius: radius.sm,
    borderWidth: 1,
  },
  text: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
});
