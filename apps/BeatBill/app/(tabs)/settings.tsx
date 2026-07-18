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
  Image,
} from 'react-native';
import { useRouter } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import Constants from 'expo-constants';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing, CURRENCIES, PAYMENT_MODES, VAT_RATES, DUE_DATE_OPTIONS, REMINDER_DELAYS, LEGAL_STATUS_OPTIONS } from '@/constants/theme';
import { useInvoices, useProfile, useAppData } from '@/hooks/useAppData';
import { exportBackup, exportInvoicesCsv, importBackup } from '@/utils/backup';
import { buildLegalFooter } from '@/utils/legalMentions';
import type { ProducerProfile } from '@/types';
import type { CurrencyCode, PaymentMode, VatRate } from '@/constants/theme';
import type { LegalStatus } from '@/types';

function Field({
  label,
  value,
  onChangeText,
  placeholder,
  keyboardType,
  multiline,
}: {
  label: string;
  value: string;
  onChangeText: (v: string) => void;
  placeholder?: string;
  keyboardType?: 'default' | 'email-address' | 'phone-pad';
  multiline?: boolean;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        style={[styles.input, multiline && styles.multiline]}
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={colors.textSecondary}
        keyboardType={keyboardType}
        multiline={multiline}
      />
    </View>
  );
}

function PickerRow<T extends string | number>({
  label,
  options,
  value,
  onSelect,
  renderLabel,
}: {
  label: string;
  options: readonly T[];
  value: T;
  onSelect: (v: T) => void;
  renderLabel?: (v: T) => string;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        {options.map((opt) => (
          <Pressable
            key={String(opt)}
            style={[styles.chip, value === opt && styles.chipActive]}
            onPress={() => onSelect(opt)}
          >
            <Text style={[styles.chipText, value === opt && styles.chipTextActive]}>
              {renderLabel ? renderLabel(opt) : String(opt)}
            </Text>
          </Pressable>
        ))}
      </ScrollView>
    </View>
  );
}

export default function SettingsScreen() {
  const router = useRouter();
  const { profile, saveProfile } = useProfile();
  const { invoices } = useInvoices();
  const { refresh } = useAppData();
  const [draft, setDraft] = useState<ProducerProfile>(profile);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    setDraft(profile);
  }, [profile]);

  const update = <K extends keyof ProducerProfile>(key: K, value: ProducerProfile[K]) => {
    setDraft((d) => ({ ...d, [key]: value }));
  };

  const handleSave = async () => {
    if (!draft.name.trim() || !draft.email.trim()) {
      Alert.alert('Profil incomplet', 'Nom et email sont requis.');
      return;
    }
    await saveProfile(draft);
    Alert.alert('Enregistré', 'Tes réglages ont été sauvegardés.');
  };

  const pickLogo = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) {
      Alert.alert('Permission refusée', 'Autorise l\'accès aux photos pour ajouter un logo.');
      return;
    }
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsEditing: true,
      aspect: [3, 1],
      quality: 0.8,
    });
    if (!result.canceled && result.assets[0]?.uri) {
      update('logoUri', result.assets[0].uri);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.section}>Mon profil</Text>
      <View style={styles.sectionBox}>
        <Pressable style={styles.logoRow} onPress={pickLogo}>
          {draft.logoUri ? (
            <Image source={{ uri: draft.logoUri }} style={styles.logoPreview} resizeMode="contain" />
          ) : (
            <View style={styles.logoPlaceholder}>
              <Ionicons name="image-outline" size={28} color={colors.textSecondary} />
            </View>
          )}
          <View style={styles.logoInfo}>
            <Text style={styles.logoTitle}>Logo PDF</Text>
            <Text style={styles.hint}>Affiché sur factures et devis</Text>
          </View>
          {draft.logoUri && (
            <Pressable onPress={() => update('logoUri', undefined)} hitSlop={8}>
              <Text style={styles.link}>Retirer</Text>
            </Pressable>
          )}
        </Pressable>
        <Field label="Nom / Studio *" value={draft.name} onChangeText={(v) => update('name', v)} />
        <Field label="Email *" value={draft.email} onChangeText={(v) => update('email', v)} keyboardType="email-address" />
        <Field label="Téléphone" value={draft.phone ?? ''} onChangeText={(v) => update('phone', v)} keyboardType="phone-pad" />
        <Field label="SIRET" value={draft.siret ?? ''} onChangeText={(v) => update('siret', v)} />
        <Field label="N° TVA" value={draft.vatNumber ?? ''} onChangeText={(v) => update('vatNumber', v)} />
        <Field label="Adresse" value={draft.address ?? ''} onChangeText={(v) => update('address', v)} multiline />
        <Field label="Pays" value={draft.country} onChangeText={(v) => update('country', v)} />
      </View>

      <Text style={styles.section}>Paiement</Text>
      <View style={styles.sectionBox}>
        <PickerRow
          label="Mode préféré"
          options={PAYMENT_MODES}
          value={draft.paymentMode}
          onSelect={(v) => update('paymentMode', v as PaymentMode)}
        />
        <Field
          label={draft.paymentMode === 'Virement (IBAN)' ? 'IBAN' : 'Lien / identifiant'}
          value={draft.paymentRef}
          onChangeText={(v) => update('paymentRef', v)}
          placeholder={draft.paymentMode === 'PayPal.me' ? 'paypal.me/monnom' : ''}
        />
        {draft.paymentMode === 'Virement (IBAN)' && (
          <Field label="BIC" value={draft.bic ?? ''} onChangeText={(v) => update('bic', v)} />
        )}
      </View>

      <Text style={styles.section}>Facturation</Text>
      <View style={styles.sectionBox}>
        <PickerRow
          label="Devise"
          options={CURRENCIES.map((c) => c.code)}
          value={draft.currency}
          onSelect={(v) => update('currency', v as CurrencyCode)}
          renderLabel={(code) => CURRENCIES.find((c) => c.code === code)?.label ?? String(code)}
        />
        <PickerRow
          label="TVA par défaut"
          options={VAT_RATES}
          value={draft.defaultVatRate}
          onSelect={(v) => update('defaultVatRate', v as VatRate)}
          renderLabel={(v) => `${v}%`}
        />
        <PickerRow
          label="Échéance par défaut"
          options={DUE_DATE_OPTIONS}
          value={draft.defaultDueDays}
          onSelect={(v) => update('defaultDueDays', v)}
          renderLabel={(v) => `${v} jours`}
        />
        <Field
          label="Préfixe factures"
          value={draft.invoicePrefix}
          onChangeText={(v) => update('invoicePrefix', v.toUpperCase())}
          placeholder="BB"
        />
        <Field
          label="Préfixe devis"
          value={draft.quotePrefix}
          onChangeText={(v) => update('quotePrefix', v.toUpperCase())}
          placeholder="DV"
        />
      </View>

      <Text style={styles.section}>Mentions légales (FR)</Text>
      <View style={styles.sectionBox}>
        <PickerRow
          label="Statut juridique"
          options={LEGAL_STATUS_OPTIONS.map((o) => o.value)}
          value={draft.legalStatus}
          onSelect={(v) => update('legalStatus', v as LegalStatus)}
          renderLabel={(v) => LEGAL_STATUS_OPTIONS.find((o) => o.value === v)?.label ?? String(v)}
        />
        <View style={styles.switchRow}>
          <Text style={styles.switchLabel}>Pénalités de retard (L441-10)</Text>
          <Switch
            value={draft.latePenaltyEnabled}
            onValueChange={(v) => update('latePenaltyEnabled', v)}
            trackColor={{ false: colors.separator, true: colors.accent }}
          />
        </View>
        <View style={styles.switchRow}>
          <Text style={styles.switchLabel}>Indemnité recouvrement 40 €</Text>
          <Switch
            value={draft.recoveryIndemnityEnabled}
            onValueChange={(v) => update('recoveryIndemnityEnabled', v)}
            trackColor={{ false: colors.separator, true: colors.accent }}
          />
        </View>
        <Field
          label="Mentions personnalisées (optionnel)"
          value={draft.customLegalFooter ?? ''}
          onChangeText={(v) => update('customLegalFooter', v)}
          multiline
        />
        <View style={styles.legalPreview}>
          <Text style={styles.legalPreviewLabel}>Aperçu pied de page PDF</Text>
          <Text style={styles.legalPreviewText}>{buildLegalFooter(draft)}</Text>
        </View>
      </View>

      <Text style={styles.section}>Outils</Text>
      <View style={styles.sectionBox}>
        <LinkRow icon="people-outline" label="Mes clients" onPress={() => router.push('/clients')} />
        <LinkRow icon="list-outline" label="Catalogue de services" onPress={() => router.push('/catalog')} />
        <LinkRow icon="repeat-outline" label="Factures récurrentes" onPress={() => router.push('/recurring')} />
        <LinkRow icon="document-attach-outline" label="Contrats & riders" onPress={() => router.push('/contracts')} />
        <LinkRow icon="search-outline" label="Recherche globale" onPress={() => router.push('/search')} />
      </View>

      <Text style={styles.section}>Notifications</Text>
      <View style={styles.sectionBox}>
        <View style={styles.switchRow}>
          <Text style={styles.switchLabel}>Rappels factures impayées</Text>
          <Switch
            value={draft.remindersEnabled}
            onValueChange={(v) => update('remindersEnabled', v)}
            trackColor={{ false: colors.separator, true: colors.accent }}
          />
        </View>
        {draft.remindersEnabled && (
          <PickerRow
            label="Délai de rappel après échéance"
            options={REMINDER_DELAYS}
            value={draft.reminderDelayDays}
            onSelect={(v) => update('reminderDelayDays', v)}
            renderLabel={(v) => `${v} jours`}
          />
        )}
      </View>

      <Text style={styles.section}>Données</Text>
      <View style={styles.sectionBox}>
        <Text style={styles.hint}>
          Sauvegarde complète (factures, clients, profil). Idéal avant changement de téléphone.
        </Text>
        <Pressable
          style={styles.dataBtn}
          disabled={busy}
          onPress={async () => {
            setBusy(true);
            try {
              await exportBackup();
            } catch (e) {
              Alert.alert('Erreur', e instanceof Error ? e.message : 'Export impossible');
            } finally {
              setBusy(false);
            }
          }}
        >
          <Text style={styles.dataBtnText}>Exporter la sauvegarde (JSON)</Text>
        </Pressable>
        <Pressable
          style={[styles.dataBtn, styles.dataBtnOutline]}
          disabled={busy}
          onPress={() => {
            Alert.alert(
              'Restaurer une sauvegarde',
              'Les données actuelles seront remplacées. Continuer ?',
              [
                { text: 'Annuler', style: 'cancel' },
                {
                  text: 'Restaurer',
                  style: 'destructive',
                  onPress: async () => {
                    setBusy(true);
                    try {
                      await importBackup();
                      await refresh();
                      Alert.alert('Restauré', 'Tes données ont été importées.');
                    } catch (e) {
                      Alert.alert('Erreur', e instanceof Error ? e.message : 'Import impossible');
                    } finally {
                      setBusy(false);
                    }
                  },
                },
              ]
            );
          }}
        >
          <Text style={styles.dataBtnTextOutline}>Importer une sauvegarde</Text>
        </Pressable>
        <Pressable
          style={[styles.dataBtn, styles.dataBtnOutline]}
          disabled={busy || invoices.length === 0}
          onPress={async () => {
            setBusy(true);
            try {
              await exportInvoicesCsv(invoices);
            } catch (e) {
              Alert.alert('Erreur', e instanceof Error ? e.message : 'Export CSV impossible');
            } finally {
              setBusy(false);
            }
          }}
        >
          <Text style={styles.dataBtnTextOutline}>
            Exporter les factures (CSV)
          </Text>
        </Pressable>
      </View>

      <Text style={styles.section}>À propos</Text>
      <View style={styles.sectionBox}>
        <Text style={styles.version}>Version {Constants.expoConfig?.version ?? '1.0.0'}</Text>
        <Text style={styles.hint}>
          App payante · Toutes les données restent sur ton appareil (100 % offline).
        </Text>
        <Pressable onPress={() => Alert.alert('Confidentialité', 'BeatBill stocke toutes tes données localement sur ton appareil. Aucune donnée n\'est envoyée à un serveur.')}>
          <Text style={styles.link}>Politique de confidentialité</Text>
        </Pressable>
      </View>

      <Pressable style={styles.saveBtn} onPress={handleSave}>
        <Text style={styles.saveBtnText}>Enregistrer les réglages</Text>
      </Pressable>
    </ScrollView>
  );
}

function LinkRow({
  icon,
  label,
  onPress,
}: {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  onPress: () => void;
}) {
  return (
    <Pressable style={styles.linkRow} onPress={onPress}>
      <Ionicons name={icon} size={20} color={colors.accent} />
      <Text style={styles.linkRowText}>{label}</Text>
      <Ionicons name="chevron-forward" size={18} color={colors.textSecondary} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
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
    gap: spacing.md,
  },
  field: { gap: spacing.xs },
  label: { color: colors.textSecondary, fontSize: 12 },
  input: {
    backgroundColor: colors.section,
    borderRadius: radius.sm,
    padding: spacing.md,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  multiline: { minHeight: 72, textAlignVertical: 'top' },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.sm,
    backgroundColor: colors.section,
    marginRight: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  chipActive: { backgroundColor: colors.accent, borderColor: colors.accent },
  chipText: { color: colors.textSecondary, fontSize: 13 },
  chipTextActive: { color: colors.background, fontWeight: '600' },
  switchRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  switchLabel: { color: colors.text, fontSize: 15, flex: 1 },
  version: { color: colors.textSecondary, fontSize: 14 },
  hint: { color: colors.textSecondary, fontSize: 12, lineHeight: 18 },
  link: { color: colors.accentLight, fontSize: 14, marginTop: spacing.sm },
  dataBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.sm,
    padding: spacing.md,
    alignItems: 'center',
  },
  dataBtnOutline: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: colors.separator,
  },
  dataBtnText: { color: colors.background, fontWeight: '700', fontSize: 14 },
  dataBtnTextOutline: { color: colors.accentLight, fontWeight: '600', fontSize: 14 },
  saveBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.lg,
  },
  saveBtnText: { color: colors.background, fontWeight: '700', fontSize: 16 },
  logoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    marginBottom: spacing.sm,
  },
  logoPreview: { width: 72, height: 36, borderRadius: radius.sm, backgroundColor: colors.section },
  logoPlaceholder: {
    width: 72,
    height: 36,
    borderRadius: radius.sm,
    backgroundColor: colors.section,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: colors.separator,
  },
  logoInfo: { flex: 1 },
  logoTitle: { color: colors.text, fontWeight: '600', fontSize: 15 },
  legalPreview: {
    backgroundColor: colors.section,
    borderRadius: radius.sm,
    padding: spacing.md,
    marginTop: spacing.sm,
  },
  legalPreviewLabel: { color: colors.textSecondary, fontSize: 11, marginBottom: spacing.xs, textTransform: 'uppercase' },
  legalPreviewText: { color: colors.textSecondary, fontSize: 11, lineHeight: 16 },
  linkRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.separator,
  },
  linkRowText: { flex: 1, color: colors.text, fontSize: 15, fontWeight: '500' },
});
