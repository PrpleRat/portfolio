import { useEffect, useState } from 'react';
import {
  View,
  Text,
  Pressable,
  StyleSheet,
  ActivityIndicator,
  Alert,
  ScrollView,
  Switch,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { WebView } from 'react-native-webview';
import * as Sharing from 'expo-sharing';
import { colors, radius, spacing } from '@/constants/theme';
import { generatePDF, generatePDFPreviewHtml } from '@/utils/generatePDF';
import { useSplits } from '@/hooks/useAppData';
import { uuid } from '@/utils/uuid';
import { generateSplitRef } from '@/utils/splitId';
import { splitStatusFromCollaborators, type Split, type SplitDraft } from '@/types';

export default function SplitPreviewScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ draft: string; editId?: string }>();
  const { saveSplit } = useSplits();

  const [html, setHtml] = useState('');
  const [pdfUri, setPdfUri] = useState('');
  const [loading, setLoading] = useState(true);
  const [split, setSplit] = useState<Split | null>(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const draftRaw = JSON.parse(params.draft) as SplitDraft & { createdAt: string };
        const draft: SplitDraft = {
          ...draftRaw,
          createdAt: new Date(draftRaw.createdAt),
        };

        const inv: Split = {
          id: params.editId ?? uuid(),
          ref: generateSplitRef(),
          title: draft.title,
          artist: draft.artist || undefined,
          genre: draft.genre || undefined,
          isrc: draft.isrc || undefined,
          createdAt: draft.createdAt.toISOString(),
          splitType: draft.splitType,
          collaborators: draft.collaborators.map((c) => ({
            id: uuid(),
            name: c.name,
            role: c.role,
            masterShare: c.masterShare,
            publishingShare: c.publishingShare,
            sacem: c.sacem,
            email: c.email,
            signed: false,
          })),
          clauses: draft.clauses,
          notes: draft.notes || undefined,
          status: 'pending',
        };

        setSplit(inv);
        const previewHtml = await generatePDFPreviewHtml(inv);
        setHtml(previewHtml);
        const uri = await generatePDF(inv);
        setPdfUri(uri);
        setSplit({ ...inv, pdfUri: uri });
      } catch {
        Alert.alert('Erreur', 'Impossible de générer le PDF.');
        router.back();
      } finally {
        setLoading(false);
      }
    })();
  }, [params.draft]);

  const toggleSigned = (collaboratorId: string, signed: boolean) => {
    if (!split) return;
    const collaborators = split.collaborators.map((c) =>
      c.id === collaboratorId ? { ...c, signed } : c
    );
    setSplit({
      ...split,
      collaborators,
      status: splitStatusFromCollaborators(collaborators),
    });
  };

  const handleShare = async () => {
    if (!pdfUri) return;
    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(pdfUri, {
        mimeType: 'application/pdf',
        dialogTitle: `Split — ${split?.title}`,
      });
    }
  };

  const handleSave = async () => {
    if (!split) return;
    await saveSplit(split);
    setSaved(true);
    Alert.alert('Enregistré', 'Split sauvegardé — en attente de signatures.', [
      { text: 'Accueil', onPress: () => router.replace('/') },
      {
        text: 'Voir détail',
        onPress: () => router.replace({ pathname: '/split-detail', params: { id: split.id } }),
      },
      { text: 'OK' },
    ]);
  };

  const handleEdit = () => {
    if (!split) return;
    router.push({
      pathname: '/new-split',
      params: {
        edit: JSON.stringify({
          title: split.title,
          artist: split.artist ?? '',
          genre: split.genre ?? '',
          isrc: split.isrc ?? '',
          createdAt: split.createdAt,
          splitType: split.splitType,
          collaborators: split.collaborators,
          clauses: split.clauses,
          notes: split.notes ?? '',
        }),
      },
    });
  };

  if (loading || !split) {
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
        <WebView originWhitelist={['*']} source={{ html }} style={styles.webview} scrollEnabled />

        <View style={styles.signatures}>
          <Text style={styles.sigTitle}>Signatures (manuel en studio)</Text>
          {split.collaborators.map((c) => (
            <View key={c.id} style={styles.sigRow}>
              <View>
                <Text style={styles.sigName}>{c.name}</Text>
                <Text style={styles.sigStatus}>{c.signed ? '✅ Signé' : 'Non signé'}</Text>
              </View>
              <Switch
                value={c.signed}
                onValueChange={(v) => toggleSigned(c.id, v)}
                trackColor={{ false: colors.separator, true: colors.accent }}
                thumbColor={colors.text}
              />
            </View>
          ))}
        </View>
      </ScrollView>

      <View style={styles.actions}>
        <Pressable style={[styles.actionBtn, styles.primaryBtn]} onPress={handleShare}>
          <Text style={[styles.actionBtnText, styles.primaryBtnText]}>
            Partager (AirDrop / iMessage / Email)
          </Text>
        </Pressable>
        {!saved ? (
          <Pressable style={styles.actionBtn} onPress={handleSave}>
            <Text style={styles.actionBtnText}>Enregistrer</Text>
          </Pressable>
        ) : null}
        <Pressable style={styles.actionBtn} onPress={handleEdit}>
          <Text style={styles.actionBtnText}>Modifier</Text>
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
  webview: { flex: 1, minHeight: 400, backgroundColor: colors.white },
  signatures: {
    backgroundColor: colors.card,
    margin: spacing.md,
    padding: spacing.md,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  sigTitle: {
    color: colors.text,
    fontWeight: '700',
    marginBottom: spacing.md,
  },
  sigRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.separator,
  },
  sigName: { color: colors.text, fontWeight: '600' },
  sigStatus: { color: colors.textSecondary, fontSize: 12, marginTop: 2 },
  actions: {
    padding: spacing.md,
    gap: spacing.sm,
    borderTopWidth: 1,
    borderTopColor: colors.separator,
    backgroundColor: colors.card,
  },
  actionBtn: {
    padding: spacing.md,
    borderRadius: radius.sm,
    borderWidth: 1,
    borderColor: colors.separator,
    alignItems: 'center',
  },
  primaryBtn: { backgroundColor: colors.accent, borderColor: colors.accent },
  actionBtnText: { color: colors.text, fontWeight: '600', fontSize: 14 },
  primaryBtnText: { color: colors.text },
});
