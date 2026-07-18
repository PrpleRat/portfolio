import { useState } from 'react';
import {
  ScrollView,
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
  Alert,
  Switch,
} from 'react-native';
import { colors, radius, spacing, CURRENCIES, VAT_RATES } from '@/constants/theme';
import { useRecurring, useProfile } from '@/hooks/useAppData';
import { uuid } from '@/utils/uuid';
import {
  computeInvoiceTotals,
  computeLineTotal,
  formatMoney,
  type LineItem,
  type RecurringInvoice,
} from '@/types';
import type { CurrencyCode, PaymentMode, VatRate } from '@/constants/theme';
import type { RecurrenceFrequency } from '@/types';

const FREQUENCIES: { value: RecurrenceFrequency; label: string }[] = [
  { value: 'weekly', label: 'Hebdo' },
  { value: 'monthly', label: 'Mensuel' },
  { value: 'quarterly', label: 'Trimestriel' },
];

export default function RecurringScreen() {
  const { recurring, saveRecurring, deleteRecurring } = useRecurring();
  const { profile } = useProfile();
  const [showForm, setShowForm] = useState(false);
  const [label, setLabel] = useState('');
  const [clientName, setClientName] = useState('');
  const [clientEmail, setClientEmail] = useState('');
  const [description, setDescription] = useState('');
  const [unitPrice, setUnitPrice] = useState('');
  const [frequency, setFrequency] = useState<RecurrenceFrequency>('monthly');
  const [vatRate, setVatRate] = useState<VatRate>(profile.defaultVatRate);
  const [currency, setCurrency] = useState<CurrencyCode>(profile.currency);

  const handleCreate = async () => {
    if (!label.trim() || !clientName.trim() || !clientEmail.trim() || !description.trim()) {
      Alert.alert('Champs requis', 'Libellé, client, email et prestation obligatoires.');
      return;
    }
    const price = parseFloat(unitPrice.replace(',', '.'));
    if (Number.isNaN(price) || price <= 0) {
      Alert.alert('Prix invalide');
      return;
    }
    const items: LineItem[] = [
      { description: description.trim(), qty: 1, unitPrice: price, total: computeLineTotal(1, price) },
    ];
    const totals = computeInvoiceTotals(items, vatRate);
    const rec: RecurringInvoice = {
      id: uuid(),
      label: label.trim(),
      clientName: clientName.trim(),
      clientEmail: clientEmail.trim(),
      items,
      vatRate,
      currency,
      frequency,
      nextRunDate: new Date().toISOString(),
      paymentMode: profile.paymentMode,
      paymentRef: profile.paymentRef,
      active: true,
      notes: `Total TTC : ${formatMoney(totals.total, currency)}`,
    };
    await saveRecurring(rec);
    setShowForm(false);
    setLabel('');
    setClientName('');
    setClientEmail('');
    setDescription('');
    setUnitPrice('');
    Alert.alert('Créé', 'Facture récurrente programmée.');
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.intro}>
        Génère automatiquement une facture à chaque échéance (vérifié au lancement de l'app).
      </Text>

      {!showForm ? (
        <Pressable style={styles.addBtn} onPress={() => setShowForm(true)}>
          <Text style={styles.addBtnText}>+ Nouvelle récurrence</Text>
        </Pressable>
      ) : (
        <View style={styles.form}>
          <Field label="Libellé *" value={label} onChange={setLabel} placeholder="Retainer mensuel" />
          <Field label="Client *" value={clientName} onChange={setClientName} />
          <Field label="Email *" value={clientEmail} onChange={setClientEmail} keyboardType="email-address" />
          <Field label="Prestation *" value={description} onChange={setDescription} />
          <Field label="Montant HT *" value={unitPrice} onChange={setUnitPrice} keyboardType="decimal-pad" />
          <Text style={styles.label}>Fréquence</Text>
          <View style={styles.chips}>
            {FREQUENCIES.map((f) => (
              <Pressable
                key={f.value}
                style={[styles.chip, frequency === f.value && styles.chipActive]}
                onPress={() => setFrequency(f.value)}
              >
                <Text style={[styles.chipText, frequency === f.value && styles.chipTextActive]}>{f.label}</Text>
              </Pressable>
            ))}
          </View>
          <Text style={styles.label}>TVA</Text>
          <View style={styles.chips}>
            {VAT_RATES.map((r) => (
              <Pressable
                key={r}
                style={[styles.chip, vatRate === r && styles.chipActive]}
                onPress={() => setVatRate(r)}
              >
                <Text style={[styles.chipText, vatRate === r && styles.chipTextActive]}>{r}%</Text>
              </Pressable>
            ))}
          </View>
          <Text style={styles.label}>Devise</Text>
          <View style={styles.chips}>
            {CURRENCIES.map((c) => (
              <Pressable
                key={c.code}
                style={[styles.chip, currency === c.code && styles.chipActive]}
                onPress={() => setCurrency(c.code)}
              >
                <Text style={[styles.chipText, currency === c.code && styles.chipTextActive]}>{c.code}</Text>
              </Pressable>
            ))}
          </View>
          <View style={styles.formActions}>
            <Pressable style={styles.cancelBtn} onPress={() => setShowForm(false)}>
              <Text style={styles.cancelText}>Annuler</Text>
            </Pressable>
            <Pressable style={styles.saveBtn} onPress={handleCreate}>
              <Text style={styles.saveText}>Créer</Text>
            </Pressable>
          </View>
        </View>
      )}

      {recurring.map((rec) => (
        <RecurringRow
          key={rec.id}
          item={rec}
          onToggle={async (active) => saveRecurring({ ...rec, active })}
          onDelete={() =>
            Alert.alert('Supprimer', 'Supprimer cette récurrence ?', [
              { text: 'Annuler', style: 'cancel' },
              { text: 'Supprimer', style: 'destructive', onPress: () => deleteRecurring(rec.id) },
            ])
          }
        />
      ))}

      {recurring.length === 0 && !showForm && (
        <Text style={styles.empty}>Aucune facture récurrente</Text>
      )}
    </ScrollView>
  );
}

function RecurringRow({
  item,
  onToggle,
  onDelete,
}: {
  item: RecurringInvoice;
  onToggle: (active: boolean) => void;
  onDelete: () => void;
}) {
  const totals = computeInvoiceTotals(item.items, item.vatRate);
  const freqLabel = FREQUENCIES.find((f) => f.value === item.frequency)?.label ?? item.frequency;

  return (
    <View style={styles.row}>
      <View style={styles.rowInfo}>
        <Text style={styles.rowTitle}>{item.label}</Text>
        <Text style={styles.rowSub}>
          {item.clientName} · {freqLabel} · {formatMoney(totals.total, item.currency)}
        </Text>
        <Text style={styles.rowDate}>Prochaine : {new Date(item.nextRunDate).toLocaleDateString('fr-FR')}</Text>
      </View>
      <Switch
        value={item.active}
        onValueChange={onToggle}
        trackColor={{ false: colors.separator, true: colors.accent }}
      />
      <Pressable onPress={onDelete} hitSlop={8}>
        <Text style={styles.delete}>×</Text>
      </Pressable>
    </View>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  keyboardType,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  keyboardType?: 'default' | 'email-address' | 'decimal-pad';
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        style={styles.input}
        value={value}
        onChangeText={onChange}
        placeholder={placeholder}
        placeholderTextColor={colors.textSecondary}
        keyboardType={keyboardType}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
  intro: { color: colors.textSecondary, fontSize: 14, marginBottom: spacing.lg, lineHeight: 20 },
  addBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginBottom: spacing.lg,
  },
  addBtnText: { color: colors.background, fontWeight: '700' },
  form: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  field: { marginBottom: spacing.sm },
  label: { color: colors.textSecondary, fontSize: 12, marginBottom: spacing.xs },
  input: {
    backgroundColor: colors.section,
    borderRadius: radius.sm,
    padding: spacing.md,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm, marginBottom: spacing.sm },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.sm,
    backgroundColor: colors.section,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  chipActive: { backgroundColor: colors.accent, borderColor: colors.accent },
  chipText: { color: colors.textSecondary, fontSize: 13 },
  chipTextActive: { color: colors.background, fontWeight: '600' },
  formActions: { flexDirection: 'row', gap: spacing.sm, marginTop: spacing.sm },
  cancelBtn: { flex: 1, padding: spacing.md, alignItems: 'center', borderWidth: 1, borderColor: colors.separator, borderRadius: radius.sm },
  cancelText: { color: colors.textSecondary },
  saveBtn: { flex: 1, padding: spacing.md, alignItems: 'center', backgroundColor: colors.accent, borderRadius: radius.sm },
  saveText: { color: colors.background, fontWeight: '700' },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  rowInfo: { flex: 1 },
  rowTitle: { color: colors.text, fontWeight: '600', fontSize: 15 },
  rowSub: { color: colors.textSecondary, fontSize: 12, marginTop: 2 },
  rowDate: { color: colors.textSecondary, fontSize: 11, marginTop: 2 },
  delete: { color: colors.error, fontSize: 22, fontWeight: '300', paddingHorizontal: spacing.xs },
  empty: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.lg },
});
