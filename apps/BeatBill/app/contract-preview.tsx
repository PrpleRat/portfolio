import { useEffect, useState } from 'react';
import { View, Text, Pressable, StyleSheet, ActivityIndicator, ScrollView } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { WebView } from 'react-native-webview';
import * as Sharing from 'expo-sharing';
import { colors, radius, spacing } from '@/constants/theme';
import { useProfile } from '@/hooks/useAppData';
import { fillContractBody, buildContractHtml } from '@/utils/contractTemplate';
import { generateHtmlPdf } from '@/utils/generatePDF';

export default function ContractPreviewScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ title: string; body: string; vars: string }>();
  const { profile } = useProfile();
  const [html, setHtml] = useState('');
  const [pdfUri, setPdfUri] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const vars = JSON.parse(params.vars ?? '{}') as Record<string, string>;
        const filled = fillContractBody(params.body ?? '', vars);
        const docHtml = buildContractHtml(params.title ?? 'Contrat', filled, profile.name || 'Producteur');
        setHtml(docHtml);
        const uri = await generateHtmlPdf(docHtml);
        setPdfUri(uri);
      } finally {
        setLoading(false);
      }
    })();
  }, [params.title, params.body, params.vars, profile.name]);

  if (loading) {
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
          <Text style={styles.btnText}>Partager PDF</Text>
        </Pressable>
        <Pressable style={[styles.btn, styles.btnOutline]} onPress={() => router.back()}>
          <Text style={styles.btnTextOutline}>Retour</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  centered: { flex: 1, backgroundColor: colors.background, alignItems: 'center', justifyContent: 'center' },
  preview: { flex: 1 },
  webview: { flex: 1, minHeight: 500, backgroundColor: colors.white },
  actions: { padding: spacing.md, gap: spacing.sm, borderTopWidth: 1, borderTopColor: colors.separator, backgroundColor: colors.card },
  btn: { backgroundColor: colors.accent, borderRadius: radius.sm, padding: spacing.md, alignItems: 'center' },
  btnText: { color: colors.background, fontWeight: '700' },
  btnOutline: { backgroundColor: 'transparent', borderWidth: 1, borderColor: colors.separator },
  btnTextOutline: { color: colors.text, fontWeight: '600' },
});
