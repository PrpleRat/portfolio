import { useEffect, useMemo, useState } from 'react';
import {
  ScrollView,
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
  Alert,
  Modal,
  FlatList,
  Platform,
} from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing, VAT_RATES, CURRENCIES } from '@/constants/theme';
import { DEFAULT_ITEMS } from '@/utils/defaultItems';
import { getNextQuoteNumber } from '@/utils/invoiceNumber';
import { QuickItemButton } from '@/components/QuickItemButton';
import { LineItemRow } from '@/components/LineItemRow';
import { useCatalog, useClients, useProfile } from '@/hooks/useAppData';
import {
  computeInvoiceTotals,
  computeLineTotal,
  formatMoney,
  type LineItem,
  type QuoteDraft,
} from '@/types';
import type { CurrencyCode, VatRate } from '@/constants/theme';

function addDays(date: Date, days: number): Date {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}

export default function NewQuoteScreen() {
  const router = useRouter();
  const { profile } = useProfile();
  const { clients } = useClients();
  const { catalog } = useCatalog();

  const [step, setStep] = useState(1);
  const [clientName, setClientName] = useState('');
  const [clientEmail, setClientEmail] = useState('');
  const [project, setProject] = useState('');
  const [number, setNumber] = useState('');
  const [issueDate, setIssueDate] = useState(new Date());
  const [validityDays, setValidityDays] = useState(30);
  const [currency, setCurrency] = useState<CurrencyCode>(profile.currency);
  const [items, setItems] = useState<LineItem[]>([{ description: '', qty: 1, unitPrice: 0, total: 0 }]);
  const [vatRate, setVatRate] = useState<VatRate>(profile.defaultVatRate);
  const [notes, setNotes] = useState('');
  const [clientPickerVisible, setClientPickerVisible] = useState(false);
  const [showIssueDatePicker, setShowIssueDatePicker] = useState(false);

  const quickItems = useMemo(
    () => [
      ...DEFAULT_ITEMS.map((i) => ({ id: i.id, description: i.description, price: i.defaultPrice })),
      ...catalog.map((c) => ({ id: c.id, description: c.description, price: c.unitPrice })),
    ],
    [catalog]
  );

  useEffect(() => {
    getNextQuoteNumber(profile.quotePrefix).then(setNumber);
  }, [profile.quotePrefix]);

  const expiresAt = useMemo(() => addDays(issueDate, validityDays), [issueDate, validityDays]);
  const totals = useMemo(() => computeInvoiceTotals(items.filter((i) => i.description), vatRate), [items, vatRate]);

  const handleQuickAdd = (description: string, price: number | null) => {
    if (price == null) {
      setItems([...items, { description: '', qty: 1, unitPrice: 0, total: 0 }]);
      return;
    }
    setItems([
      ...items.filter((i) => i.description.trim()),
      { description, qty: 1, unitPrice: price, total: computeLineTotal(1, price) },
    ]);
  };

  const handleGenerate = () => {
    if (!clientName.trim() || !clientEmail.trim()) {
      Alert.alert('Champs requis', 'Nom et email du client sont obligatoires.');
      return;
    }
    const validItems = items.filter((i) => i.description.trim() && i.unitPrice > 0);
    if (validItems.length === 0) {
      Alert.alert('Items requis', 'Ajoute au moins un item avec description et prix.');
      return;
    }

    const draft: QuoteDraft = {
      clientName: clientName.trim(),
      clientEmail: clientEmail.trim(),
      project: project.trim(),
      number,
      issueDate,
      expiresAt,
      items: validItems,
      vatRate,
      notes: notes.trim(),
      currency,
      validityDays,
    };

    router.push({ pathname: '/quote-preview', params: { draft: JSON.stringify(draft) } });
  };

  return (
    <>
      <ScrollView style={styles.container} contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <View style={styles.progress}>
          <View style={[styles.dot, step >= 1 && styles.dotActive]} />
          <View style={styles.line} />
          <View style={[styles.dot, step >= 2 && styles.dotActive]} />
        </View>

        {step === 1 ? (
          <>
            <Pressable style={styles.clientPicker} onPress={() => setClientPickerVisible(true)}>
              <Ionicons name="people" size={18} color={colors.accent} />
              <Text style={styles.clientPickerText}>Depuis mes clients</Text>
            </Pressable>
            <Field label="Nom du client *" value={clientName} onChange={setClientName} />
            <Field label="Email *" value={clientEmail} onChange={setClientEmail} keyboardType="email-address" />
            <Field label="N° devis" value={number} onChange={setNumber} />
            <Text style={styles.label}>Date d'émission</Text>
            <Pressable style={styles.dateField} onPress={() => setShowIssueDatePicker(true)}>
              <Text style={styles.dateFieldText}>{issueDate.toLocaleDateString('fr-FR')}</Text>
              <Ionicons name="calendar-outline" size={20} color={colors.accent} />
            </Pressable>
            {showIssueDatePicker && (
              <DateTimePicker
                value={issueDate}
                mode="date"
                display={Platform.OS === 'ios' ? 'spinner' : 'default'}
                locale="fr-FR"
                onChange={(_e, date) => {
                  if (Platform.OS === 'android') setShowIssueDatePicker(false);
                  if (date) setIssueDate(date);
                }}
              />
            )}
            <Text style={styles.label}>Validité</Text>
            <View style={styles.chips}>
              {[15, 30, 60].map((d) => (
                <Pressable
                  key={d}
                  style={[styles.chip, validityDays === d && styles.chipActive]}
                  onPress={() => setValidityDays(d)}
                >
                  <Text style={[styles.chipText, validityDays === d && styles.chipTextActive]}>{d} jours</Text>
                </Pressable>
              ))}
            </View>
            <Text style={styles.hint}>Expire le {expiresAt.toLocaleDateString('fr-FR')}</Text>
            <Field label="Projet (optionnel)" value={project} onChange={setProject} />
            <Pressable style={styles.nextBtn} onPress={() => clientName.trim() && clientEmail.trim() && setStep(2)}>
              <Text style={styles.nextBtnText}>Suivant</Text>
            </Pressable>
          </>
        ) : (
          <>
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
            <View style={styles.quickGrid}>
              {quickItems.map((item) => (
                <QuickItemButton
                  key={item.id}
                  label={item.description}
                  price={item.price}
                  onPress={() => handleQuickAdd(item.description, item.price)}
                />
              ))}
            </View>
            {items.map((item, index) => (
              <LineItemRow
                key={index}
                item={item}
                index={index}
                currency={currency}
                onChange={(i, next) => {
                  const copy = [...items];
                  copy[i] = next;
                  setItems(copy);
                }}
                onRemove={(i) => setItems(items.filter((_, idx) => idx !== i))}
                canRemove={items.length > 1}
              />
            ))}
            <Pressable
              style={styles.addLine}
              onPress={() => setItems([...items, { description: '', qty: 1, unitPrice: 0, total: 0 }])}
            >
              <Text style={styles.addLineText}>+ Ligne</Text>
            </Pressable>
            <View style={styles.chips}>
              {VAT_RATES.map((rate) => (
                <Pressable
                  key={rate}
                  style={[styles.chip, vatRate === rate && styles.chipActive]}
                  onPress={() => setVatRate(rate)}
                >
                  <Text style={[styles.chipText, vatRate === rate && styles.chipTextActive]}>{rate}%</Text>
                </Pressable>
              ))}
            </View>
            <View style={styles.totalsBox}>
              <Text style={styles.totalLarge}>TOTAL {formatMoney(totals.total, currency)}</Text>
            </View>
            <Field label="Notes" value={notes} onChange={setNotes} multiline />
            <View style={styles.actions}>
              <Pressable style={styles.backBtn} onPress={() => setStep(1)}>
                <Text style={styles.backBtnText}>Retour</Text>
              </Pressable>
              <Pressable style={styles.generateBtn} onPress={handleGenerate}>
                <Text style={styles.generateBtnText}>Générer le devis PDF</Text>
              </Pressable>
            </View>
          </>
        )}
      </ScrollView>

      <Modal visible={clientPickerVisible} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <FlatList
              data={clients}
              keyExtractor={(c) => c.id}
              renderItem={({ item }) => (
                <Pressable
                  style={styles.clientRow}
                  onPress={() => {
                    setClientName(item.name);
                    setClientEmail(item.email);
                    setClientPickerVisible(false);
                  }}
                >
                  <Text style={styles.clientRowName}>{item.name}</Text>
                  <Text style={styles.clientRowEmail}>{item.email}</Text>
                </Pressable>
              )}
            />
            <Pressable onPress={() => setClientPickerVisible(false)}>
              <Text style={styles.modalCloseText}>Fermer</Text>
            </Pressable>
          </View>
        </View>
      </Modal>
    </>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  keyboardType,
  multiline,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  keyboardType?: 'default' | 'email-address';
  multiline?: boolean;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        style={[styles.input, multiline && styles.multiline]}
        value={value}
        onChangeText={onChange}
        placeholder={placeholder}
        placeholderTextColor={colors.textSecondary}
        keyboardType={keyboardType}
        multiline={multiline}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
  progress: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', marginBottom: spacing.lg },
  dot: { width: 12, height: 12, borderRadius: 6, backgroundColor: colors.separator },
  dotActive: { backgroundColor: colors.accent },
  line: { width: 60, height: 2, backgroundColor: colors.separator, marginHorizontal: spacing.sm },
  clientPicker: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm, marginBottom: spacing.md },
  clientPickerText: { color: colors.accentLight, fontWeight: '600' },
  field: { marginBottom: spacing.md },
  label: { color: colors.textSecondary, fontSize: 12, marginBottom: spacing.xs },
  input: {
    backgroundColor: colors.card,
    borderRadius: radius.sm,
    padding: spacing.md,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  multiline: { minHeight: 80, textAlignVertical: 'top' },
  dateField: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: radius.sm,
    padding: spacing.md,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  dateFieldText: { color: colors.text, fontSize: 16 },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm, marginBottom: spacing.md },
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
  hint: { color: colors.textSecondary, fontSize: 12, marginBottom: spacing.md },
  nextBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.md,
  },
  nextBtnText: { color: colors.background, fontWeight: '700', fontSize: 16 },
  quickGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm, marginBottom: spacing.md },
  addLine: { marginBottom: spacing.md },
  addLineText: { color: colors.accentLight },
  totalsBox: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  totalLarge: { color: colors.accentLight, fontSize: 20, fontWeight: '800', textAlign: 'center' },
  actions: { flexDirection: 'row', gap: spacing.sm },
  backBtn: {
    flex: 1,
    padding: spacing.md,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.separator,
    alignItems: 'center',
  },
  backBtnText: { color: colors.text, fontWeight: '600' },
  generateBtn: {
    flex: 2,
    backgroundColor: colors.accent,
    padding: spacing.md,
    borderRadius: radius.md,
    alignItems: 'center',
  },
  generateBtnText: { color: colors.background, fontWeight: '700' },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.8)', justifyContent: 'flex-end' },
  modalSheet: {
    backgroundColor: colors.card,
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
    padding: spacing.lg,
    maxHeight: '60%',
  },
  clientRow: { paddingVertical: spacing.md, borderBottomWidth: 1, borderBottomColor: colors.separator },
  clientRowName: { color: colors.text, fontWeight: '600' },
  clientRowEmail: { color: colors.textSecondary, fontSize: 13 },
  modalCloseText: { color: colors.accentLight, textAlign: 'center', padding: spacing.md, fontWeight: '600' },
});
