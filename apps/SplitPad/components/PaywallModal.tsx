import {
  Modal,
  View,
  Text,
  Pressable,
  StyleSheet,
  ActivityIndicator,
  ScrollView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';

interface Props {
  visible: boolean;
  loading?: boolean;
  price: string;
  onPurchase: () => void;
  onRestore: () => void;
  onClose: () => void;
}

export function PaywallModal({ visible, loading, price, onPurchase, onRestore, onClose }: Props) {
  return (
    <Modal visible={visible} animationType="slide" transparent onRequestClose={onClose}>
      <View style={styles.overlay}>
        <View style={styles.sheet}>
          <Pressable style={styles.close} onPress={onClose}>
            <Ionicons name="close" size={24} color={colors.textSecondary} />
          </Pressable>

          <Text style={styles.title}>SplitPad Pro</Text>
          <Text style={styles.subtitle}>Splits illimités · PDF pro · Carnet de collabs</Text>

          <ScrollView style={styles.bullets}>
            {[
              'Splits illimités',
              'Carnet de collaborateurs illimité',
              'Historique complet',
            ].map((item) => (
              <View key={item} style={styles.bulletRow}>
                <Ionicons name="checkmark-circle" size={20} color={colors.accent} />
                <Text style={styles.bulletText}>{item}</Text>
              </View>
            ))}
          </ScrollView>

          <Pressable style={styles.cta} onPress={onPurchase} disabled={loading}>
            {loading ? (
              <ActivityIndicator color={colors.text} />
            ) : (
              <Text style={styles.ctaText}>Débloquer pour {price}</Text>
            )}
          </Pressable>

          <Pressable onPress={onRestore} disabled={loading}>
            <Text style={styles.restore}>Restaurer l'achat</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.85)',
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: colors.card,
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
    padding: spacing.lg,
    paddingBottom: spacing.xl,
  },
  close: {
    alignSelf: 'flex-end',
    marginBottom: spacing.sm,
  },
  title: {
    color: colors.text,
    fontSize: 28,
    fontWeight: '700',
    textAlign: 'center',
  },
  subtitle: {
    color: colors.textSecondary,
    fontSize: 14,
    textAlign: 'center',
    marginTop: spacing.sm,
    marginBottom: spacing.lg,
  },
  bullets: { maxHeight: 160, marginBottom: spacing.lg },
  bulletRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  bulletText: {
    color: colors.text,
    fontSize: 16,
  },
  cta: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  ctaText: {
    color: colors.text,
    fontSize: 17,
    fontWeight: '700',
  },
  restore: {
    color: colors.accentLight,
    textAlign: 'center',
    fontSize: 14,
  },
});
