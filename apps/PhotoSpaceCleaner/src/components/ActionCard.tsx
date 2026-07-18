import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { colors } from '../constants/theme';
import type { MediaFilter } from '../types/media';

type Props = {
  title: string;
  subtitle: string;
  icon: keyof typeof Ionicons.glyphMap;
  filter?: MediaFilter;
  shuffle?: boolean;
  route?: '/heavy' | '/queue' | '/files';
  accent?: string;
  badge?: string;
};

export function ActionCard({ title, subtitle, icon, filter, shuffle, route, accent = colors.accent, badge }: Props) {
  const onPress = () => {
    if (route) {
      router.push(route);
      return;
    }
    if (filter) {
      router.push({
        pathname: '/swipe',
        params: { filter, ...(shuffle ? { shuffle: '1' } : {}) },
      });
    }
  };

  return (
    <Pressable style={({ pressed }) => [styles.card, pressed && styles.pressed]} onPress={onPress}>
      <LinearGradient colors={[accent + '33', colors.surface]} style={styles.gradient}>
        <View style={styles.iconWrap}>
          <Ionicons name={icon} size={24} color={accent} />
        </View>
        <View style={styles.textWrap}>
          <Text style={styles.title}>{title}</Text>
          <Text style={styles.subtitle}>{subtitle}</Text>
        </View>
        {badge ? (
          <View style={styles.badge}>
            <Text style={styles.badgeText}>{badge}</Text>
          </View>
        ) : (
          <Ionicons name="chevron-forward" size={20} color={colors.textMuted} />
        )}
      </LinearGradient>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: 18,
    overflow: 'hidden',
    marginBottom: 12,
    borderWidth: 1,
    borderColor: colors.border,
  },
  pressed: { opacity: 0.85 },
  gradient: { flexDirection: 'row', alignItems: 'center', padding: 16, gap: 14 },
  iconWrap: {
    width: 48,
    height: 48,
    borderRadius: 14,
    backgroundColor: colors.surfaceLight,
    alignItems: 'center',
    justifyContent: 'center',
  },
  textWrap: { flex: 1 },
  title: { color: colors.text, fontSize: 17, fontWeight: '700', marginBottom: 2 },
  subtitle: { color: colors.textMuted, fontSize: 13, lineHeight: 18 },
  badge: {
    backgroundColor: colors.delete,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 12,
  },
  badgeText: { color: colors.text, fontWeight: '700', fontSize: 12 },
});
