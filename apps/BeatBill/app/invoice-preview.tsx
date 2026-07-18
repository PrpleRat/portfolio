import { useEffect, useState } from 'react';
import {
  View,
  Text,
  Pressable,
  StyleSheet,
  ActivityIndicator,
  Alert,
  ScrollView,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { WebView } from 'react-native-webview';
import * as Sharing from 'expo-sharing';
import { colors, radius, spacing } from '@/constants/theme';
import { generatePDF, generatePDFPreviewHtml } from '@/utils/generatePDF';
import { useAppData, useProfile } from '@/hooks/useAppData';
import { useNotifications } from '@/hooks/useServices';
import { uuid } from '@/utils/uuid';
import {
  computeInvoiceTotals,
  type Invoice,
  type InvoiceDraft,
} from '@/types';

export default function InvoicePreviewScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ draft: string; editId?: string }>();
  const { profile } = useProfile();
  const { saveInvoice, upsertClient, getInvoiceById } = useAppData();
  const { scheduleInvoiceReminders } = useNotifications();

  const [html, setHtml] = useState('');
  const [pdfUri, setPdfUri] = useState('');
  const [loading, setLoading] = useState(true);
  const [invoice, setInvoice] = useState<Invoice | null>(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const draftRaw = JSON.parse(params.draft);
        const draft = {
          ...draftRaw,
          issueDate: new Date(draftRaw.issueDate),
          dueDate: new Date(draftRaw.dueDate),
        };
        const totals = computeInvoiceTotals(draft.items, draft.vatRate);
        const existing = params.editId ? getInvoiceById(params.editId) : undefined;
        const inv: Invoice = {
          id: params.editId ?? uuid(),
          number: draft.number,
          status: existing?.status ?? 'pending',
          clientName: draft.clientName,
          clientEmail: draft.clientEmail,
          project: draft.project || undefined,
          items: draft.items,
          subtotal: totals.subtotal,
          vatRate: draft.vatRate,
          vatAmount: totals.vatAmount,
          total: totals.total,
          currency: draft.currency ?? profile.currency,
          paymentMode: draft.paymentMode,
          paymentRef: draft.paymentRef,
          notes: draft.notes || undefined,
          createdAt: existing?.createdAt ?? (draft.issueDate.toISOString?.() ?? new Date(draft.issueDate).toISOString()),
          dueDate: draft.dueDate.toISOString?.() ?? new Date(draft.dueDate).toISOString(),
          paidAt: existing?.paidAt ?? null,
          actions: existing
            ? [...existing.actions, { type: 'status_changed' as const, date: new Date().toISOString(), note: 'Modifiée' }]
            : [{ type: 'created' as const, date: new Date().toISOString() }],
        };
        setInvoice(inv);
        const previewHtml = await generatePDFPreviewHtml(inv, profile);
        setHtml(previewHtml);
        const uri = await generatePDF(inv, profile);
        setPdfUri(uri);
        inv.pdfUri = uri;
        setInvoice({ ...inv, pdfUri: uri });
      } catch (e) {
        Alert.alert('Erreur', 'Impossible de générer le PDF.');
        router.back();
      } finally {
        setLoading(false);
      }
    })();
  }, [params.draft]);

  const handleShare = async () => {
    if (!pdfUri) return;
    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(pdfUri, {
        mimeType: 'application/pdf',
        dialogTitle: `Facture ${invoice?.number}`,
      });
    }
  };

  const handleSave = async () => {
    if (!invoice) return;
    await upsertClient(invoice.clientName, invoice.clientEmail);
    await saveInvoice(invoice);
    if (profile.remindersEnabled) {
      await scheduleInvoiceReminders(invoice, profile.reminderDelayDays);
    }
    setSaved(true);
    Alert.alert('Enregistrée', 'Facture sauvegardée dans l\'historique.', [
      { text: 'Accueil', onPress: () => router.replace('/') },
      {
        text: 'Marquer payée',
        onPress: async () => {
          await saveInvoice({ ...invoice, status: 'paid', paidAt: new Date().toISOString() });
          router.replace({ pathname: '/invoice-detail', params: { id: invoice.id } });
        },
      },
      { text: 'OK' },
    ]);
  };

  if (loading || !invoice) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator color={colors.accent} size="large" />
        <Text style={styles.loadingText}>Génération du PDF...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <ScrollView style={styles.preview} contentContainerStyle={styles.previewContent}>
        <WebView
          originWhitelist={['*']}
          source={{ html }}
          style={styles.webview}
          scrollEnabled
        />
      </ScrollView>

      <View style={styles.actions}>
        <View style={styles.actionRow}>
          <Pressable style={styles.actionBtn} onPress={handleShare}>
            <Text style={styles.actionBtnText}>Envoyer</Text>
          </Pressable>
          {!saved ? (
            <Pressable style={[styles.actionBtn, styles.primaryBtn]} onPress={handleSave}>
              <Text style={[styles.actionBtnText, styles.primaryBtnText]}>Enregistrer</Text>
            </Pressable>
          ) : (
            <Pressable
              style={[styles.actionBtn, styles.primaryBtn]}
              onPress={() => router.replace({ pathname: '/invoice-detail', params: { id: invoice.id } })}
            >
              <Text style={[styles.actionBtnText, styles.primaryBtnText]}>Voir détail</Text>
            </Pressable>
          )}
          <Pressable style={styles.actionBtn} onPress={() => router.back()}>
            <Text style={styles.actionBtnText}>Modifier</Text>
          </Pressable>
        </View>
        <Pressable
          style={styles.homeBtn}
          onPress={() => router.replace('/')}
        >
          <Text style={styles.homeBtnText}>Accueil</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  centered: {
    flex: 1,
    backgroundColor: colors.background,
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingText: { color: colors.textSecondary, marginTop: spacing.md },
  preview: { flex: 1 },
  previewContent: { flexGrow: 1 },
  webview: { flex: 1, minHeight: 500, backgroundColor: colors.white },
  actions: {
    padding: spacing.md,
    gap: spacing.sm,
    borderTopWidth: 1,
    borderTopColor: colors.separator,
    backgroundColor: colors.card,
  },
  actionRow: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  actionBtn: {
    flex: 1,
    padding: spacing.md,
    borderRadius: radius.sm,
    borderWidth: 1,
    borderColor: colors.separator,
    alignItems: 'center',
  },
  primaryBtn: { backgroundColor: colors.accent, borderColor: colors.accent },
  actionBtnText: { color: colors.text, fontWeight: '600', fontSize: 13 },
  primaryBtnText: { color: colors.background },
  homeBtn: {
    padding: spacing.md,
    borderRadius: radius.sm,
    borderWidth: 1,
    borderColor: colors.accent,
    alignItems: 'center',
  },
  homeBtnText: { color: colors.accentLight, fontWeight: '700', fontSize: 15 },
});
