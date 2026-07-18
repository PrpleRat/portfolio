import { View, Text, TextInput, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { HELP } from '@/constants/help';
import { RolePicker } from './RolePicker';
import { PercentageSlider } from './PercentageSlider';
import type { SplitType } from '@/types';

export interface CollaboratorFormData {
  id: string;
  name: string;
  role: string;
  masterShare: number;
  publishingShare: number;
  sacem: string;
  email: string;
}

interface Props {
  index: number;
  data: CollaboratorFormData;
  splitType: SplitType;
  onChange: (data: CollaboratorFormData) => void;
  onRemove: () => void;
  canRemove: boolean;
}

export function CollaboratorCard({
  index,
  data,
  splitType,
  onChange,
  onRemove,
  canRemove,
}: Props) {
  const update = <K extends keyof CollaboratorFormData>(key: K, value: CollaboratorFormData[K]) => {
    onChange({ ...data, [key]: value });
  };

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <Text style={styles.cardTitle}>Collaborateur {index + 1}</Text>
        {canRemove && (
          <Pressable onPress={onRemove} hitSlop={8}>
            <Ionicons name="trash-outline" size={20} color={colors.error} />
          </Pressable>
        )}
      </View>

      <Text style={styles.label}>Prénom / Nom de scène *</Text>
      <TextInput
        style={styles.input}
        value={data.name}
        onChangeText={(v) => update('name', v)}
        placeholder="Ex: Metro"
        placeholderTextColor={colors.textSecondary}
      />

      <Text style={styles.label}>Rôle</Text>
      <RolePicker value={data.role} onChange={(v) => update('role', v)} />

      <View style={styles.sliders}>
        <PercentageSlider
          label="Part Master"
          value={data.masterShare}
          onChange={(v) => update('masterShare', v)}
          infoTitle={HELP.masterShare.title}
          infoText={HELP.masterShare.text}
        />
        {splitType === 'master_and_publishing' && (
          <PercentageSlider
            label="Part Publishing"
            value={data.publishingShare}
            onChange={(v) => update('publishingShare', v)}
            infoTitle={HELP.publishingShare.title}
            infoText={HELP.publishingShare.text}
          />
        )}
      </View>

      <Text style={styles.label}>PRO / SACEM</Text>
      <TextInput
        style={styles.input}
        value={data.sacem}
        onChangeText={(v) => update('sacem', v)}
        placeholder="Numéro d'adhérent"
        placeholderTextColor={colors.textSecondary}
        keyboardType="number-pad"
      />

      <Text style={styles.label}>Email</Text>
      <TextInput
        style={styles.input}
        value={data.email}
        onChangeText={(v) => update('email', v)}
        placeholder="optionnel"
        placeholderTextColor={colors.textSecondary}
        keyboardType="email-address"
        autoCapitalize="none"
      />
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  cardTitle: {
    color: colors.accentLight,
    fontWeight: '700',
    fontSize: 14,
  },
  label: {
    color: colors.textSecondary,
    fontSize: 12,
    marginBottom: spacing.xs,
    marginTop: spacing.sm,
  },
  input: {
    backgroundColor: colors.section,
    borderRadius: radius.sm,
    padding: spacing.md,
    color: colors.text,
    fontSize: 16,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  sliders: {
    marginTop: spacing.md,
  },
});
