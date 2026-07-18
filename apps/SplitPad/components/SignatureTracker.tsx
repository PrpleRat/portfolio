import { View, Text, Switch, StyleSheet } from 'react-native';
import { colors, radius, spacing } from '@/constants/theme';
import type { SplitCollaborator } from '@/types';

interface Props {
  collaborators: SplitCollaborator[];
  onToggle: (collaboratorId: string, signed: boolean) => void;
}

export function SignatureTracker({ collaborators, onToggle }: Props) {
  const allSigned = collaborators.length > 0 && collaborators.every((c) => c.signed);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>
        Statut des signatures {allSigned ? '✅ Complet' : ''}
      </Text>
      {collaborators.map((c) => (
        <View key={c.id} style={styles.row}>
          <View style={styles.info}>
            <Text style={styles.name}>{c.name}</Text>
            <Text style={styles.role}>{c.role}</Text>
          </View>
          <View style={styles.toggle}>
            <Text style={[styles.status, c.signed && styles.signed]}>
              {c.signed ? 'Signé' : 'Non signé'}
            </Text>
            <Switch
              value={c.signed}
              onValueChange={(v) => onToggle(c.id, v)}
              trackColor={{ false: colors.separator, true: colors.accent }}
              thumbColor={colors.text}
            />
          </View>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
    marginBottom: spacing.md,
  },
  title: {
    color: colors.text,
    fontWeight: '700',
    fontSize: 14,
    marginBottom: spacing.md,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.separator,
  },
  info: { flex: 1 },
  name: {
    color: colors.text,
    fontSize: 15,
    fontWeight: '600',
  },
  role: {
    color: colors.textSecondary,
    fontSize: 12,
    marginTop: 2,
  },
  toggle: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  status: {
    color: colors.warning,
    fontSize: 12,
    fontWeight: '600',
  },
  signed: {
    color: colors.success,
  },
});
