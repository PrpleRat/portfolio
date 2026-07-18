import { useEffect, useState } from 'react';
import { View, Text, Pressable, StyleSheet, ActivityIndicator, Alert, ScrollView } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { WebView } from 'react-native-webview';
import * as Sharing from 'expo-sharing';
import { colors, radius, spacing } from '@/constants/theme';
import { generateQuotePDF, generateQuotePreviewHtml } from '@/utils/generatePDF';
import { useAppData, useProfile } from '@/hooks/useAppData';
import { uuid } from '@/utils/uuid';
import { computeInvoiceTotals, type Quote, type QuoteDraft } from '@/types';

export default function QuotePreviewScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ draft: string }>();
  const { profile } = useProfile();
  const { saveQuote, upsertClient } = useAppData();

  const [html, setHtml] = useState('');
  const [pdfUri, setPdfUri] = useState('');
  const [loading, setLoading] = useState(true);
  const [quote, setQuote] = useState<Quote | null>(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const draftRaw = JSON.parse(params.draft);
        const draft: QuoteDraft = {
          ...draftRaw,
          issueDate: new Date(draftRaw.issueDate),
          expiresAt: new Date(draftRaw.expiresAt),
        };
        const totals = computeInvoiceTotals(draft.items, draft.vatRate);
        const q: Quote = {
          id: uuid(),
          number: draft.number,
          status: 'sent',
          clientName: draft.clientName,
          clientEmail: draft.clientEmail,
          project: draft.project || undefined,
          items: draft.items,
          subtotal: totals.subtotal,
          vatRate: draft.vatRate,
          vatAmount: totals.vatAmount,
          total: totals.total,
          currency: draft.currency,
          notes: draft.notes || undefined,
          validityDays: draft.validityDays,
          createdAt: draft.issueDate.toISOString(),
          expiresAt: draft.expiresAt.toISOString(),
        };
        setQuote(q);
        const previewHtml = await generateQuotePreviewHtml(q, profile);
        setHtml(previewHtml);
        const uri = await generateQuotePDF(q, profile);
        setPdfUri(uri);
        setQuote({ ...q, pdfUri: uri });
      } catch {
        Alert.alert('Erreur', 'Impossible de générer le PDF.');
        router.back();
      } finally {
        setLoading(false);
      }
    })();
  }, [params.draft]);

  const handleSave = async () => {
    if (!quote) return;
    await upsertClient(quote.clientName, quote.clientEmail);
    await saveQuote({ ...quote, pdfUri });
    setSaved(true);
    Alert.alert('Enregistré', 'Devis sauvegardé.', [
      { text: 'Voir détail', onPress: () => router.replace({ pathname: '/quote-detail', params: { id: quote.id } }) },
      { text: 'OK' },
    ]);
  };

  if (loading || !quote) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator color={colors.accent} size="large" />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <ScrollView style={styles.preview}>
        <WebView originWhitelist={['*']} source={{ html }} style={styles.webview} />
      </ScrollView>
      <View style={styles.actions}>
        <Pressable
          style={styles.btn}
          onPress={async () => {
            if (pdfUri && (await Sharing.isAvailableAsync())) {
              await Sharing.shareAsync(pdfUri, { mimeType: 'application/pdf' });
            }
          }}
        >
          <Text style={styles.btnText}>Envoyer</Text>
        </Pressable>
        {!saved ? (
          <Pressable style={[styles.btn, styles.primary]} onPress={handleSave}>
            <Text style={[styles.btnText, styles.primaryText]}>Enregistrer</Text>
          </Pressable>
        ) : (
          <Pressable
            style={[styles.btn, styles.primary]}
            onPress={() => router.replace({ pathname: '/quote-detail', params: { id: quote.id } })}
          >
            <Text style={[styles.btnText, styles.primaryText]}>Voir détail</Text>
          </Pressable>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  centered: { flex: 1, backgroundColor: colors.background, alignItems: 'center', justifyContent: 'center' },
  preview: { flex: 1 },
  webview: { flex: 1, minHeight: 500, backgroundColor: colors.white },
  actions: { flexDirection: 'row', gap: spacing.sm, padding: spacing.md, borderTopWidth: 1, borderTopColor: colors.separator, backgroundColor: colors.card },
  btn: { flex: 1, padding: spacing.md, borderRadius: radius.sm, borderWidth: 1, borderColor: colors.separator, alignItems: 'center' },
  btnText: { color: colors.text, fontWeight: '600' },
  primary: { backgroundColor: colors.accent, borderColor: colors.accent },
  primaryText: { color: colors.background },
});
