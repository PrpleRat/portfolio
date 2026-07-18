import { ScrollView, View, Text, Pressable, StyleSheet, Alert, ActivityIndicator } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import * as Sharing from 'expo-sharing';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { useQuotes, useProfile } from '@/hooks/useAppData';
import {
  effectiveQuoteStatus,
  formatDate,
  formatMoney,
  quoteStatusLabel,
} from '@/types';

export default function QuoteDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { getQuoteById, deleteQuote, convertQuoteToInvoice, saveQuote } = useQuotes();
  const { profile } = useProfile();

  const quote = getQuoteById(id);
  const status = quote ? effectiveQuoteStatus(quote) : 'draft';

  if (!quote) {
    return (
      <View style={styles.centered}>
        <Text style={styles.notFound}>Devis introuvable</Text>
      </View>
    );
  }

  const handleShare = async () => {
    let uri = quote.pdfUri;
    if (!uri) {
      const { generateQuotePDF } = await import('@/utils/generatePDF');
      uri = await generateQuotePDF(quote, profile);
      await saveQuote({ ...quote, pdfUri: uri });
    }
    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(uri, { mimeType: 'application/pdf' });
    }
  };

  const handleConvert = () => {
    Alert.alert(
      'Convertir en facture',
      `Créer une facture à partir du devis ${quote.number} ?`,
      [
        { text: 'Annuler', style: 'cancel' },
        {
          text: 'Convertir',
          onPress: async () => {
            try {
              const invoice = await convertQuoteToInvoice(quote.id);
              router.replace({ pathname: '/invoice-detail', params: { id: invoice.id } });
            } catch (e) {
              Alert.alert('Erreur', e instanceof Error ? e.message : 'Conversion impossible');
            }
          },
        },
      ]
    );
  };

  const handleDelete = () => {
    Alert.alert('Supprimer le devis', 'Cette action est irréversible.', [
      { text: 'Annuler', style: 'cancel' },
      {
        text: 'Supprimer',
        style: 'destructive',
        onPress: async () => {
          await deleteQuote(quote.id);
          router.back();
        },
      },
    ]);
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <View>
          <Text style={styles.number}>{quote.number}</Text>
          <Text style={styles.client}>{quote.clientName}</Text>
        </View>
        <Text style={styles.badge}>{quoteStatusLabel(status)}</Text>
      </View>

      <View style={styles.amountBox}>
        <Text style={styles.amount}>{formatMoney(quote.total, quote.currency)}</Text>
        <Text style={styles.dates}>
          Émis le {formatDate(quote.createdAt)} · Valable jusqu'au {formatDate(quote.expiresAt)}
        </Text>
      </View>

      {quote.project && (
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Projet</Text>
          <Text style={styles.sectionValue}>{quote.project}</Text>
        </View>
      )}

      <View style={styles.section}>
        <Text style={styles.sectionLabel}>Items</Text>
        {quote.items.map((item, i) => (
          <View key={i} style={styles.itemRow}>
            <Text style={styles.itemDesc}>{item.description}</Text>
            <Text style={styles.itemTotal}>{formatMoney(item.total, quote.currency)}</Text>
          </View>
        ))}
      </View>

      <View style={styles.actions}>
        {status !== 'converted' && (
          <ActionButton icon="swap-horizontal" label="→ Facture" onPress={handleConvert} primary />
        )}
        {quote.convertedInvoiceId && (
          <ActionButton
            icon="document-text-outline"
            label="Voir facture"
            onPress={() =>
              router.push({ pathname: '/invoice-detail', params: { id: quote.convertedInvoiceId! } })
            }
          />
        )}
        <ActionButton icon="share-outline" label="Partager" onPress={handleShare} />
        <ActionButton icon="trash-outline" label="Supprimer" onPress={handleDelete} danger />
      </View>
    </ScrollView>
  );
}

function ActionButton({
  icon,
  label,
  onPress,
  primary,
  danger,
}: {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  onPress: () => void;
  primary?: boolean;
  danger?: boolean;
}) {
  return (
    <Pressable
      style={[styles.actionBtn, primary && styles.actionPrimary, danger && styles.actionDanger]}
      onPress={onPress}
    >
      <Ionicons name={icon} size={22} color={primary ? colors.background : danger ? colors.error : colors.accent} />
      <Text style={[styles.actionLabel, primary && styles.actionLabelPrimary, danger && styles.actionLabelDanger]}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl },
  centered: { flex: 1, backgroundColor: colors.background, alignItems: 'center', justifyContent: 'center' },
  notFound: { color: colors.textSecondary },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: spacing.lg },
  number: { color: colors.textSecondary, fontSize: 13 },
  client: { color: colors.text, fontSize: 22, fontWeight: '700', marginTop: 4 },
  badge: { color: colors.accentLight, fontSize: 11, fontWeight: '700', letterSpacing: 0.5 },
  amountBox: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.lg,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  amount: { color: colors.accentLight, fontSize: 32, fontWeight: '800' },
  dates: { color: colors.textSecondary, fontSize: 13, marginTop: spacing.sm },
  section: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  sectionLabel: { color: colors.textSecondary, fontSize: 11, textTransform: 'uppercase', marginBottom: spacing.sm },
  sectionValue: { color: colors.text, fontSize: 14 },
  itemRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: spacing.xs },
  itemDesc: { color: colors.text, flex: 1 },
  itemTotal: { color: colors.accentLight, fontWeight: '600' },
  actions: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  actionBtn: {
    width: '47%',
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.separator,
    gap: spacing.xs,
  },
  actionPrimary: { backgroundColor: colors.accent, borderColor: colors.accent },
  actionDanger: { borderColor: colors.error },
  actionLabel: { color: colors.text, fontSize: 13, fontWeight: '600' },
  actionLabelPrimary: { color: colors.background },
  actionLabelDanger: { color: colors.error },
});
