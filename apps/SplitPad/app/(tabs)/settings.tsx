import { useEffect, useState } from 'react';
import {
  ScrollView,
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
  Alert,
  Linking,
} from 'react-native';
import Constants from 'expo-constants';
import { colors, radius, spacing, CURRENCIES } from '@/constants/theme';
import { RolePicker } from '@/components/RolePicker';
import { useProfile } from '@/hooks/useAppData';
import { usePurchase } from '@/hooks/usePurchase';
import type { UserProfile } from '@/types';

function Field({
  label,
  value,
  onChangeText,
  placeholder,
  keyboardType,
}: {
  label: string;
  value: string;
  onChangeText: (v: string) => void;
  placeholder?: string;
  keyboardType?: 'default' | 'email-address' | 'number-pad';
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        style={styles.input}
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={colors.textSecondary}
        keyboardType={keyboardType}
      />
    </View>
  );
}

export default function SettingsScreen() {
  const { profile, saveProfile } = useProfile();
  const { restorePurchase } = usePurchase();
  const [draft, setDraft] = useState<UserProfile>(profile);

  useEffect(() => {
    setDraft(profile);
  }, [profile]);

  const update = <K extends keyof UserProfile>(key: K, value: UserProfile[K]) => {
    setDraft((d) => ({ ...d, [key]: value }));
  };

  const handleSave = async () => {
    if (!draft.name.trim()) {
      Alert.alert('Profil incomplet', 'Ton nom / alias est requis pour pré-remplir tes splits.');
      return;
    }
    await saveProfile(draft);
    Alert.alert('Enregistré', 'Ton profil pré-remplit chaque nouveau split.');
  };

  const handleRestore = async () => {
    const ok = await restorePurchase();
    Alert.alert(ok ? 'Restauré' : 'Aucun achat', ok ? 'SplitPad Pro débloqué.' : 'Aucun achat trouvé.');
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.section}>Mon profil</Text>
      <View style={styles.sectionBox}>
        <Field
          label="Nom / alias"
          value={draft.name}
          onChangeText={(v) => update('name', v)}
          placeholder="Ton nom de scène"
        />
        <Text style={styles.label}>Rôle habituel</Text>
        <RolePicker value={draft.role} onChange={(v) => update('role', v)} />
        <Field
          label="Email"
          value={draft.email}
          onChangeText={(v) => update('email', v)}
          placeholder="optionnel"
          keyboardType="email-address"
        />
        <Field
          label="SACEM / PRO"
          value={draft.sacem ?? ''}
          onChangeText={(v) => update('sacem', v)}
          placeholder="Numéro d'adhérent"
          keyboardType="number-pad"
        />
        <Field
          label="Pays"
          value={draft.country}
          onChangeText={(v) => update('country', v)}
        />
      </View>

      <Text style={styles.section}>Devise</Text>
      <View style={styles.sectionBox}>
        <View style={styles.currencyRow}>
          {CURRENCIES.map((c) => (
            <Pressable
              key={c.code}
              style={[styles.chip, draft.currency === c.code && styles.chipActive]}
              onPress={() => update('currency', c.code)}
            >
              <Text style={[styles.chipText, draft.currency === c.code && styles.chipTextActive]}>
                {c.symbol}
              </Text>
            </Pressable>
          ))}
        </View>
      </View>

      <Pressable style={styles.saveBtn} onPress={handleSave}>
        <Text style={styles.saveBtnText}>Enregistrer le profil</Text>
      </Pressable>

      <Text style={styles.section}>À propos</Text>
      <View style={styles.sectionBox}>
        <Text style={styles.aboutRow}>Version {Constants.expoConfig?.version ?? '1.0.0'}</Text>
        <Pressable onPress={() => Linking.openURL('https://www.voisintech.fr/pro')}>
          <Text style={styles.link}>Politique de confidentialité</Text>
        </Pressable>
        <Pressable onPress={handleRestore}>
          <Text style={styles.link}>Restaurer l'achat</Text>
        </Pressable>
      </View>

      <Text style={styles.footer}>
        SplitPad · 100% offline · Aucune donnée envoyée au cloud
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl },
  section: {
    color: colors.textSecondary,
    fontSize: 12,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: spacing.sm,
    marginTop: spacing.md,
  },
  sectionBox: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  field: { marginBottom: spacing.sm },
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
  currencyRow: { flexDirection: 'row', gap: spacing.sm },
  chip: {
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderRadius: radius.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  chipActive: { backgroundColor: colors.accent, borderColor: colors.accent },
  chipText: { color: colors.textSecondary, fontSize: 18, fontWeight: '600' },
  chipTextActive: { color: colors.text },
  saveBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.lg,
  },
  saveBtnText: { color: colors.text, fontWeight: '700', fontSize: 16 },
  aboutRow: { color: colors.textSecondary, fontSize: 14, marginBottom: spacing.md },
  link: { color: colors.accentLight, fontSize: 14, marginBottom: spacing.md },
  footer: {
    color: colors.textSecondary,
    fontSize: 11,
    textAlign: 'center',
    marginTop: spacing.xl,
  },
});
