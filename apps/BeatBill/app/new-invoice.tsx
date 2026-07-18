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
import { useRouter, useLocalSearchParams } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing, VAT_RATES, CURRENCIES } from '@/constants/theme';
import { DEFAULT_ITEMS } from '@/utils/defaultItems';
import { getNextInvoiceNumber } from '@/utils/invoiceNumber';
import { QuickItemButton } from '@/components/QuickItemButton';
import { LineItemRow } from '@/components/LineItemRow';
import { useCatalog, useClients, useProfile } from '@/hooks/useAppData';
import {
  computeInvoiceTotals,
  computeLineTotal,
  formatMoney,
  type InvoiceDraft,
  type LineItem,
} from '@/types';
import type { CurrencyCode, VatRate } from '@/constants/theme';

function addDays(date: Date, days: number): Date {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}

export default function NewInvoiceScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ duplicate?: string; import?: string; editId?: string }>();
  const { profile } = useProfile();
  const { clients } = useClients();
  const { catalog } = useCatalog();

  const quickItems = useMemo(
    () => [
      ...DEFAULT_ITEMS.map((i) => ({ id: i.id, description: i.description, price: i.defaultPrice })),
      ...catalog.map((c) => ({ id: c.id, description: c.description, price: c.unitPrice })),
    ],
    [catalog]
  );

  const [step, setStep] = useState(1);
  const [clientName, setClientName] = useState('');
  const [clientEmail, setClientEmail] = useState('');
  const [project, setProject] = useState('');
  const [number, setNumber] = useState('');
  const [issueDate, setIssueDate] = useState(new Date());
  const [dueDays, setDueDays] = useState(profile.defaultDueDays);
  const [items, setItems] = useState<LineItem[]>([
    { description: '', qty: 1, unitPrice: 0, total: 0 },
  ]);
  const [vatRate, setVatRate] = useState<VatRate>(profile.defaultVatRate);
  const [notes, setNotes] = useState('');
  const [paymentMode, setPaymentMode] = useState(profile.paymentMode);
  const [paymentRef, setPaymentRef] = useState(profile.paymentRef);
  const [currency, setCurrency] = useState<CurrencyCode>(profile.currency);
  const [clientPickerVisible, setClientPickerVisible] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [showIssueDatePicker, setShowIssueDatePicker] = useState(false);
  const [beatDealImport, setBeatDealImport] = useState(false);

  const goHome = () => router.replace('/');

  useEffect(() => {
    getNextInvoiceNumber(profile.invoicePrefix).then(setNumber);
  }, [profile.invoicePrefix]);

  useEffect(() => {
    const raw = params.import ?? params.duplicate;
    if (!raw) return;
    try {
      const dup = JSON.parse(raw);
      setClientName(dup.clientName ?? '');
      setClientEmail(dup.clientEmail ?? '');
      setProject(dup.project ?? '');
      setItems(dup.items?.length ? dup.items : items);
      setVatRate(dup.vatRate ?? profile.defaultVatRate);
      setNotes(dup.notes ?? '');
      if (dup.number) setNumber(dup.number);
      if (dup.issueDate) setIssueDate(new Date(dup.issueDate));
      if (dup.dueDate) {
        const due = new Date(dup.dueDate);
        const issue = dup.issueDate ? new Date(dup.issueDate) : issueDate;
        const diff = Math.round((due.getTime() - issue.getTime()) / (1000 * 60 * 60 * 24));
        if (diff > 0) setDueDays(diff);
      }
      if (dup.currency) setCurrency(dup.currency);
      if (dup.paymentMode) setPaymentMode(dup.paymentMode);
      if (dup.paymentRef) setPaymentRef(dup.paymentRef);
      if (dup.beatDealImport) {
        setBeatDealImport(true);
      }
      if (dup.startStep === 2 && dup.clientName && dup.clientEmail) {
        setStep(2);
      }
    } catch {
      // ignore invalid payload
    }
  }, [params.duplicate, params.import]);

  useEffect(() => {
    setPaymentMode(profile.paymentMode);
    setPaymentRef(profile.paymentRef);
    setVatRate(profile.defaultVatRate);
    setDueDays(profile.defaultDueDays);
    setCurrency(profile.currency);
  }, [profile]);

  const dueDate = useMemo(() => addDays(issueDate, dueDays), [issueDate, dueDays]);
  const totals = useMemo(() => computeInvoiceTotals(items.filter((i) => i.description), vatRate), [items, vatRate]);

  const validateStep1 = () => {
    if (!clientName.trim() || !clientEmail.trim()) {
      Alert.alert('Champs requis', 'Nom et email du client sont obligatoires.');
      return false;
    }
    return true;
  };

  const validateStep2 = () => {
    const validItems = items.filter((i) => i.description.trim() && i.unitPrice > 0);
    if (validItems.length === 0) {
      Alert.alert('Items requis', 'Ajoute au moins un item avec description et prix.');
      return false;
    }
    return true;
  };

  const handleQuickAdd = (description: string, price: number | null) => {
    if (price == null) {
      setItems([...items, { description: '', qty: 1, unitPrice: 0, total: 0 }]);
      return;
    }
    setItems([
      ...items.filter((i) => i.description.trim()),
      {
        description,
        qty: 1,
        unitPrice: price,
        total: computeLineTotal(1, price),
      },
    ]);
  };

  const handleGenerate = async () => {
    if (!validateStep1() || !validateStep2()) return;
    setGenerating(true);

    const draft: InvoiceDraft = {
      clientName: clientName.trim(),
      clientEmail: clientEmail.trim(),
      project: project.trim(),
      number,
      issueDate,
      dueDate,
      items: items.filter((i) => i.description.trim() && i.unitPrice > 0),
      vatRate,
      notes: notes.trim(),
      paymentMode,
      paymentRef,
      currency,
    };

    router.push({
      pathname: '/invoice-preview',
      params: {
        draft: JSON.stringify(draft),
        ...(params.editId ? { editId: params.editId } : {}),
      },
    });
    setGenerating(false);
  };

  return (
    <>
      <ScrollView style={styles.container} contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <View style={styles.progress}>
          <View style={[styles.dot, step >= 1 && styles.dotActive]} />
          <View style={styles.line} />
          <View style={[styles.dot, step >= 2 && styles.dotActive]} />
        </View>
        <Text style={styles.stepLabel}>Étape {step} / 2</Text>

        {beatDealImport && (
          <View style={styles.importBanner}>
            <Ionicons name="link" size={18} color={colors.accent} />
            <Text style={styles.importBannerText}>Import BeatDeal — vérifie et valide la facture</Text>
          </View>
        )}

        {step === 1 ? (
          <>
            <Text style={styles.sectionTitle}>Client & références</Text>

            <Pressable style={styles.clientPicker} onPress={() => setClientPickerVisible(true)}>
              <Ionicons name="people" size={18} color={colors.accent} />
              <Text style={styles.clientPickerText}>Depuis mes clients</Text>
            </Pressable>

            <Field label="Nom du client *" value={clientName} onChange={setClientName} />
            <Field label="Email *" value={clientEmail} onChange={setClientEmail} keyboardType="email-address" />

            <Field label="N° facture" value={number} onChange={setNumber} />

            <Text style={styles.label}>Date d'émission</Text>
            <Pressable style={styles.dateField} onPress={() => setShowIssueDatePicker(true)}>
              <Text style={styles.dateFieldText}>
                {issueDate.toLocaleDateString('fr-FR', {
                  day: '2-digit',
                  month: '2-digit',
                  year: 'numeric',
                })}
              </Text>
              <Ionicons name="calendar-outline" size={20} color={colors.accent} />
            </Pressable>
            {showIssueDatePicker && (
              <DateTimePicker
                value={issueDate}
                mode="date"
                display={Platform.OS === 'ios' ? 'spinner' : 'default'}
                locale="fr-FR"
                onChange={(_event, date) => {
                  if (Platform.OS === 'android') setShowIssueDatePicker(false);
                  if (date) setIssueDate(date);
                }}
              />
            )}
            {showIssueDatePicker && Platform.OS === 'ios' && (
              <Pressable style={styles.dateDoneBtn} onPress={() => setShowIssueDatePicker(false)}>
                <Text style={styles.dateDoneText}>OK</Text>
              </Pressable>
            )}

            <Text style={styles.label}>Échéance</Text>
            <View style={styles.chips}>
              {[7, 14, 30].map((d) => (
                <Pressable
                  key={d}
                  style={[styles.chip, dueDays === d && styles.chipActive]}
                  onPress={() => setDueDays(d)}
                >
                  <Text style={[styles.chipText, dueDays === d && styles.chipTextActive]}>{d} jours</Text>
                </Pressable>
              ))}
            </View>
            <Text style={styles.hint}>Échéance : {dueDate.toLocaleDateString('fr-FR')}</Text>

            <Field
              label="Projet / titre (optionnel)"
              value={project}
              onChange={setProject}
              placeholder="Album 'Soleil Noir' — Mixing"
            />

            <Pressable style={styles.nextBtn} onPress={() => validateStep1() && setStep(2)}>
              <Text style={styles.nextBtnText}>Suivant</Text>
              <Ionicons name="arrow-forward" size={18} color={colors.background} />
            </Pressable>

            <Pressable style={styles.cancelBtn} onPress={goHome}>
              <Text style={styles.cancelBtnText}>Annuler · Accueil</Text>
            </Pressable>
          </>
        ) : (
          <>
            <Text style={styles.sectionTitle}>Items & montant</Text>

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

            <Text style={styles.label}>Suggestions rapides</Text>
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

            <Text style={styles.label}>Lignes de facturation</Text>
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
              onPress={() =>
                setItems([...items, { description: '', qty: 1, unitPrice: 0, total: 0 }])
              }
            >
              <Ionicons name="add-circle-outline" size={20} color={colors.accent} />
              <Text style={styles.addLineText}>Ajouter une ligne</Text>
            </Pressable>

            <Text style={styles.label}>TVA</Text>
            <View style={styles.chips}>
              {VAT_RATES.map((rate) => (
                <Pressable
                  key={rate}
                  style={[styles.chip, vatRate === rate && styles.chipActive]}
                  onPress={() => setVatRate(rate)}
                >
                  <Text style={[styles.chipText, vatRate === rate && styles.chipTextActive]}>
                    {rate}%
                  </Text>
                </Pressable>
              ))}
            </View>

            <View style={styles.totalsBox}>
              <Row label="Sous-total HT" value={formatMoney(totals.subtotal, currency)} />
              <Row label={`TVA (${vatRate}%)`} value={formatMoney(totals.vatAmount, currency)} />
              <Row label="TOTAL TTC" value={formatMoney(totals.total, currency)} large />
            </View>

            <Field label="Notes (optionnel)" value={notes} onChange={setNotes} multiline />

            <View style={styles.paymentBox}>
              <Text style={styles.label}>Paiement</Text>
              <Text style={styles.paymentInfo}>
                {paymentMode} · {paymentRef || 'Configure dans Réglages'}
              </Text>
            </View>

            <View style={styles.actions}>
              <Pressable style={styles.backBtn} onPress={() => setStep(1)}>
                <Text style={styles.backBtnText}>Retour</Text>
              </Pressable>
              <Pressable style={styles.generateBtn} onPress={handleGenerate} disabled={generating}>
                <Text style={styles.generateBtnText}>Générer la facture PDF</Text>
              </Pressable>
            </View>

            <Pressable style={styles.cancelBtn} onPress={goHome}>
              <Text style={styles.cancelBtnText}>Annuler · Accueil</Text>
            </Pressable>
          </>
        )}
      </ScrollView>

      <Modal visible={clientPickerVisible} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <Text style={styles.modalTitle}>Choisir un client</Text>
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
              ListEmptyComponent={
                <Text style={styles.emptyClients}>Aucun client enregistré</Text>
              }
            />
            <Pressable style={styles.modalClose} onPress={() => setClientPickerVisible(false)}>
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
  editable = true,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  keyboardType?: 'default' | 'email-address';
  multiline?: boolean;
  editable?: boolean;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        style={[styles.input, multiline && styles.multiline, !editable && styles.disabled]}
        value={value}
        onChangeText={onChange}
        placeholder={placeholder}
        placeholderTextColor={colors.textSecondary}
        keyboardType={keyboardType}
        multiline={multiline}
        editable={editable}
      />
    </View>
  );
}

function Row({ label, value, large }: { label: string; value: string; large?: boolean }) {
  return (
    <View style={styles.totalRow}>
      <Text style={[styles.totalLabel, large && styles.totalLarge]}>{label}</Text>
      <Text style={[styles.totalValue, large && styles.totalLarge]}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
  progress: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.sm,
  },
  dot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: colors.separator,
  },
  dotActive: { backgroundColor: colors.accent },
  line: { width: 60, height: 2, backgroundColor: colors.separator, marginHorizontal: spacing.sm },
  importBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    backgroundColor: colors.section,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.accent,
  },
  importBannerText: {
    color: colors.accentLight,
    fontSize: 13,
    flex: 1,
  },
  stepLabel: {
    color: colors.textSecondary,
    textAlign: 'center',
    fontSize: 12,
    marginBottom: spacing.lg,
  },
  sectionTitle: {
    color: colors.text,
    fontSize: 20,
    fontWeight: '700',
    marginBottom: spacing.lg,
  },
  clientPicker: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  clientPickerText: { color: colors.accentLight, fontSize: 14, fontWeight: '600' },
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
  disabled: { opacity: 0.7 },
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
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    marginTop: spacing.md,
  },
  nextBtnText: { color: colors.background, fontWeight: '700', fontSize: 16 },
  cancelBtn: {
    marginTop: spacing.md,
    padding: spacing.md,
    alignItems: 'center',
  },
  cancelBtnText: { color: colors.textSecondary, fontSize: 14, fontWeight: '600' },
  dateField: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.card,
    borderRadius: radius.sm,
    padding: spacing.md,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  dateFieldText: { color: colors.text, fontSize: 16 },
  dateDoneBtn: {
    alignSelf: 'flex-end',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    marginBottom: spacing.md,
  },
  dateDoneText: { color: colors.accentLight, fontWeight: '700', fontSize: 16 },
  quickGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm, marginBottom: spacing.lg },
  addLine: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.lg,
  },
  addLineText: { color: colors.accentLight, fontSize: 14 },
  totalsBox: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  totalRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: spacing.xs,
  },
  totalLabel: { color: colors.textSecondary, fontSize: 14 },
  totalValue: { color: colors.text, fontSize: 14, fontWeight: '600' },
  totalLarge: { color: colors.accentLight, fontSize: 20, fontWeight: '800' },
  paymentBox: {
    backgroundColor: colors.section,
    borderRadius: radius.sm,
    padding: spacing.md,
    marginBottom: spacing.lg,
  },
  paymentInfo: { color: colors.text, fontSize: 14 },
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
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.8)',
    justifyContent: 'flex-end',
  },
  modalSheet: {
    backgroundColor: colors.card,
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
    padding: spacing.lg,
    maxHeight: '60%',
  },
  modalTitle: { color: colors.text, fontSize: 18, fontWeight: '700', marginBottom: spacing.md },
  clientRow: {
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.separator,
  },
  clientRowName: { color: colors.text, fontSize: 16, fontWeight: '600' },
  clientRowEmail: { color: colors.textSecondary, fontSize: 13 },
  emptyClients: { color: colors.textSecondary, textAlign: 'center', padding: spacing.lg },
  modalClose: { padding: spacing.md, alignItems: 'center' },
  modalCloseText: { color: colors.accentLight, fontWeight: '600' },
});
