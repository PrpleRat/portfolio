import { Pressable, Text, StyleSheet } from 'react-native';
import { colors, radius, spacing } from '@/constants/theme';

interface Props {
  label: string;
  price?: number | null;
  onPress: () => void;
}

export function QuickItemButton({ label, price, onPress }: Props) {
  return (
    <Pressable style={styles.button} onPress={onPress}>
      <Text style={styles.label} numberOfLines={2}>
        {label}
      </Text>
      {price != null && <Text style={styles.price}>{price} €</Text>}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    backgroundColor: colors.section,
    borderRadius: radius.md,
    padding: spacing.sm,
    minWidth: '47%',
    flexGrow: 1,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  label: {
    color: colors.text,
    fontSize: 13,
    fontWeight: '500',
    marginBottom: 4,
  },
  price: {
    color: colors.accentLight,
    fontSize: 12,
    fontWeight: '600',
  },
});
