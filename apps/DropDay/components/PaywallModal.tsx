import {
  View,
  Text,
  Modal,
  Pressable,
  StyleSheet,
  ScrollView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';

interface PaywallModalProps {
  visible: boolean;
  priceLabel: string;
  onClose: () => void;
  onPurchase: () => void;
  onRestore: () => void;
  loading?: boolean;
}

const BULLETS = [
  'Releases illimitées',
  'Post-mortem et stats comparatives',
  'Budget tracker complet',
  'Export PDF équipe',
];

export function PaywallModal({
  visible,
  priceLabel,
  onClose,
  onPurchase,
  onRestore,
  loading,
}: PaywallModalProps) {
  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.overlay}>
        <View style={styles.sheet}>
          <Pressable style={styles.close} onPress={onClose}>
            <Ionicons name="close" size={24} color={colors.textSecondary} />
          </Pressable>

          <Text style={styles.logo}>DropDay Pro</Text>
          <Text style={styles.subtitle}>
            Ta 1ère release est gratuite. Débloque tout pour {priceLabel} — achat unique.
          </Text>

          <ScrollView style={styles.bullets}>
            {BULLETS.map((b) => (
              <View key={b} style={styles.bulletRow}>
                <Ionicons name="checkmark-circle" size={22} color={colors.success} />
                <Text style={styles.bulletText}>{b}</Text>
              </View>
            ))}
          </ScrollView>

          <Pressable
            style={[styles.cta, loading && styles.ctaDisabled]}
            onPress={onPurchase}
            disabled={loading}
          >
            <Text style={styles.ctaText}>
              {loading ? 'Chargement…' : `Débloquer — ${priceLabel}`}
            </Text>
          </Pressable>

          <Pressable style={styles.restore} onPress={onRestore}>
            <Text style={styles.restoreText}>Restaurer l'achat</Text>
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
  close: { alignSelf: 'flex-end' },
  logo: {
    color: colors.text,
    fontSize: 28,
    fontWeight: '800',
    textAlign: 'center',
  },
  subtitle: {
    color: colors.textSecondary,
    fontSize: 15,
    textAlign: 'center',
    marginTop: spacing.sm,
    lineHeight: 22,
  },
  bullets: { marginVertical: spacing.lg, maxHeight: 200 },
  bulletRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.sm,
  },
  bulletText: { color: colors.text, fontSize: 16 },
  cta: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
  },
  ctaDisabled: { opacity: 0.6 },
  ctaText: { color: colors.white, fontWeight: '700', fontSize: 17 },
  restore: { alignItems: 'center', marginTop: spacing.md },
  restoreText: { color: colors.accentLight, fontSize: 15 },
});
