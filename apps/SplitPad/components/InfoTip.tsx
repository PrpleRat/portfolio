import { useState } from 'react';
import { Modal, Pressable, Text, View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';

interface Props {
  title: string;
  text: string;
  size?: number;
}

export function InfoTip({ title, text, size = 18 }: Props) {
  const [visible, setVisible] = useState(false);

  return (
    <>
      <Pressable onPress={() => setVisible(true)} hitSlop={10} style={styles.btn}>
        <Ionicons name="help-circle-outline" size={size} color={colors.accentLight} />
      </Pressable>

      <Modal visible={visible} animationType="fade" transparent onRequestClose={() => setVisible(false)}>
        <Pressable style={styles.overlay} onPress={() => setVisible(false)}>
          <Pressable style={styles.box} onPress={(e) => e.stopPropagation()}>
            <Text style={styles.title}>{title}</Text>
            <Text style={styles.text}>{text}</Text>
            <Pressable style={styles.closeBtn} onPress={() => setVisible(false)}>
              <Text style={styles.closeText}>Compris</Text>
            </Pressable>
          </Pressable>
        </Pressable>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  btn: {
    marginLeft: spacing.xs,
  },
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.75)',
    justifyContent: 'center',
    padding: spacing.lg,
  },
  box: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.lg,
    borderWidth: 1,
    borderColor: colors.accent,
  },
  title: {
    color: colors.accentLight,
    fontSize: 17,
    fontWeight: '700',
    marginBottom: spacing.md,
  },
  text: {
    color: colors.text,
    fontSize: 14,
    lineHeight: 22,
  },
  closeBtn: {
    marginTop: spacing.lg,
    alignSelf: 'flex-end',
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
    backgroundColor: colors.accent,
    borderRadius: radius.sm,
  },
  closeText: {
    color: colors.text,
    fontWeight: '700',
  },
});
