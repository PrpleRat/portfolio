import { useEffect, useState } from 'react';
import {
  ScrollView,
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
  Switch,
  Alert,
} from 'react-native';
import Constants from 'expo-constants';
import { colors, radius, spacing, CURRENCIES } from '@/constants/theme';
import { useReleases } from '@/hooks/useReleases';
import { usePurchase } from '@/hooks/usePurchase';
import { useNotifications } from '@/hooks/useNotifications';
import type { ArtistProfile } from '@/types';

export default function SettingsScreen() {
  const { profile, saveProfile, releases } = useReleases();
  const { isPro, restorePurchase, priceLabel } = usePurchase(releases.length);
  const { enabled, setNotificationsEnabled, requestPermission } = useNotifications();
  const [draft, setDraft] = useState<ArtistProfile>(profile);

  useEffect(() => {
    setDraft(profile);
  }, [profile]);

  const save = async () => {
    await saveProfile(draft);
    Alert.alert('Enregistré', 'Profil mis à jour.');
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.section}>Profil artiste</Text>
      <Field
        label="Nom / pseudo"
        value={draft.name}
        onChangeText={(name) => setDraft({ ...draft, name })}
      />
      <Field
        label="Genre musical principal"
        value={draft.genre}
        onChangeText={(genre) => setDraft({ ...draft, genre })}
        placeholder="Rap, R&B, Afro…"
      />

      <Text style={styles.section}>Devise</Text>
      <View style={styles.chips}>
        {CURRENCIES.map((c) => (
          <Pressable
            key={c.code}
            style={[styles.chip, draft.currency === c.code && styles.chipActive]}
            onPress={() => setDraft({ ...draft, currency: c.code })}
          >
            <Text style={[styles.chipText, draft.currency === c.code && styles.chipTextActive]}>
              {c.label}
            </Text>
          </Pressable>
        ))}
      </View>

      <Text style={styles.section}>Notifications</Text>
      <View style={styles.row}>
        <Text style={styles.rowLabel}>Rappels contextuels</Text>
        <Switch
          value={enabled && draft.notificationsEnabled}
          onValueChange={async (v) => {
            setDraft({ ...draft, notificationsEnabled: v });
            await setNotificationsEnabled(v);
            if (v) await requestPermission();
          }}
          trackColor={{ true: colors.accent, false: colors.future }}
        />
      </View>
      <Text style={styles.hint}>
        J-7, J-3, jour J, retards et post-mortem J+7 / J+30
      </Text>

      <Text style={styles.section}>DropDay Pro</Text>
      <View style={styles.proBox}>
        <Text style={styles.proStatus}>
          {isPro ? '✓ Pro actif' : `Gratuit · 1 release incluse · Pro ${priceLabel}`}
        </Text>
        <Pressable
          style={styles.secondaryBtn}
          onPress={async () => {
            const ok = await restorePurchase();
            Alert.alert(ok ? 'Restauré' : 'Aucun achat', ok ? 'Pro débloqué.' : 'Pas d\'achat trouvé.');
          }}
        >
          <Text style={styles.secondaryText}>Restaurer l'achat</Text>
        </Pressable>
      </View>

      <Pressable style={styles.saveBtn} onPress={save}>
        <Text style={styles.saveText}>Enregistrer</Text>
      </Pressable>

      <Text style={styles.about}>
        DropDay v{Constants.expoConfig?.version ?? '1.0.0'} · 100% offline · com.cashthetrain.dropday
      </Text>
    </ScrollView>
  );
}

function Field({
  label,
  value,
  onChangeText,
  placeholder,
}: {
  label: string;
  value: string;
  onChangeText: (v: string) => void;
  placeholder?: string;
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
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl },
  section: {
    color: colors.accentLight,
    fontSize: 13,
    fontWeight: '700',
    marginTop: spacing.lg,
    marginBottom: spacing.sm,
    letterSpacing: 0.5,
  },
  field: { marginBottom: spacing.md },
  label: { color: colors.textSecondary, fontSize: 13, marginBottom: spacing.xs },
  input: {
    backgroundColor: colors.card,
    borderRadius: radius.sm,
    padding: spacing.md,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  chips: { flexDirection: 'row', gap: spacing.sm },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.sm,
    backgroundColor: colors.card,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  chipActive: { borderColor: colors.accent, backgroundColor: colors.accent + '22' },
  chipText: { color: colors.textSecondary },
  chipTextActive: { color: colors.accentLight, fontWeight: '600' },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: colors.card,
    padding: spacing.md,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  rowLabel: { color: colors.text, fontSize: 16 },
  hint: { color: colors.textSecondary, fontSize: 12, marginTop: spacing.xs },
  proBox: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  proStatus: { color: colors.text, fontSize: 15 },
  secondaryBtn: { marginTop: spacing.sm },
  secondaryText: { color: colors.accentLight, fontSize: 15 },
  saveBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.xl,
  },
  saveText: { color: colors.white, fontWeight: '700', fontSize: 16 },
  about: {
    color: colors.textSecondary,
    fontSize: 12,
    textAlign: 'center',
    marginTop: spacing.xl,
  },
});
