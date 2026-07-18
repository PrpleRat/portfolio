import { useMemo } from 'react';
import {
  ScrollView,
  View,
  Text,
  Pressable,
  StyleSheet,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import * as Sharing from 'expo-sharing';
import * as Linking from 'expo-linking';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { SignatureTracker } from '@/components/SignatureTracker';
import { useSplits } from '@/hooks/useAppData';
import { generatePDF } from '@/utils/generatePDF';
import { buildBeatDealSplitUrl } from '@/utils/beatDealLink';
import { formatDate } from '@/types';

export default function SplitDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { getSplitById, toggleSignature, updateSplit, loading } = useSplits();

  const split = useMemo(() => (id ? getSplitById(id) : undefined), [id, getSplitById]);

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator color={colors.accent} size="large" />
      </View>
    );
  }

  if (!split) {
    return (
      <View style={styles.centered}>
        <Text style={styles.errorText}>Split introuvable</Text>
        <Pressable onPress={() => router.back()}>
          <Text style={styles.link}>Retour</Text>
        </Pressable>
      </View>
    );
  }

  const handleReshare = async () => {
    try {
      let uri = split.pdfUri;
      if (!uri) {
        uri = await generatePDF(split);
        await updateSplit(split.id, { pdfUri: uri });
      }
      if (await Sharing.isAvailableAsync()) {
        await Sharing.shareAsync(uri, {
          mimeType: 'application/pdf',
          dialogTitle: `Split — ${split.title}`,
        });
      }
    } catch {
      Alert.alert('Erreur', 'Impossible de partager le PDF.');
    }
  };

  const handleDuplicate = () => {
    router.push({
      pathname: '/new-split',
      params: {
        duplicate: JSON.stringify({
          artist: split.artist ?? '',
          genre: split.genre ?? '',
          splitType: split.splitType,
          clauses: split.clauses,
          collaborators: split.collaborators.map((c) => ({
            name: c.name,
            role: c.role,
            masterShare: c.masterShare,
            publishingShare: c.publishingShare,
            sacem: c.sacem ?? '',
            email: c.email ?? '',
          })),
        }),
      },
    });
  };

  const handleExportBeatDeal = async () => {
    const url = buildBeatDealSplitUrl(split);
    try {
      await Linking.openURL(url);
    } catch {
      Alert.alert(
        'Ouverture BeatDeal',
        'Impossible d’ouvrir BeatDeal. Mets à jour BeatDeal (dernière version TestFlight) puis réessaie.'
      );
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.headerCard}>
        <Text style={styles.title}>{split.title}</Text>
        {split.artist ? <Text style={styles.artist}>{split.artist}</Text> : null}
        <Text style={styles.meta}>
          {split.ref} · {formatDate(split.createdAt)}
        </Text>
        <View style={styles.statusBadge}>
          <Text style={[styles.statusText, split.status === 'complete' && styles.statusComplete]}>
            {split.status === 'complete' ? '✅ Complet' : '⏳ En attente de signatures'}
          </Text>
        </View>
      </View>

      <Text style={styles.section}>Collaborateurs</Text>
      {split.collaborators.map((c) => (
        <View key={c.id} style={styles.collabRow}>
          <View>
            <Text style={styles.collabName}>{c.name}</Text>
            <Text style={styles.collabRole}>
              {c.role} · Master {c.masterShare}%
              {split.splitType === 'master_and_publishing' ? ` · Pub ${c.publishingShare}%` : ''}
            </Text>
            {c.sacem ? <Text style={styles.collabSacem}>SACEM {c.sacem}</Text> : null}
          </View>
        </View>
      ))}

      <SignatureTracker
        collaborators={split.collaborators}
        onToggle={(collabId, signed) => toggleSignature(split.id, collabId, signed)}
      />

      {split.clauses.length > 0 && (
        <>
          <Text style={styles.section}>Clauses</Text>
          <View style={styles.clausesBox}>
            {split.clauses.map((clause) => (
              <Text key={clause} style={styles.clause}>
                • {clause}
              </Text>
            ))}
            {split.notes ? <Text style={styles.notes}>{split.notes}</Text> : null}
          </View>
        </>
      )}

      <Pressable style={[styles.btn, styles.primaryBtn]} onPress={handleReshare}>
        <Ionicons name="share-outline" size={20} color={colors.text} />
        <Text style={styles.primaryBtnText}>Re-partager le PDF</Text>
      </Pressable>

      <Pressable style={styles.btn} onPress={handleDuplicate}>
        <Ionicons name="copy-outline" size={20} color={colors.accentLight} />
        <Text style={styles.btnText}>Dupliquer</Text>
      </Pressable>

      <Pressable style={styles.btn} onPress={handleExportBeatDeal}>
        <Ionicons name="open-outline" size={20} color={colors.accentLight} />
        <Text style={styles.btnText}>Ouvrir dans BeatDeal</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl },
  centered: {
    flex: 1,
    backgroundColor: colors.background,
    alignItems: 'center',
    justifyContent: 'center',
  },
  errorText: { color: colors.textSecondary, marginBottom: spacing.md },
  link: { color: colors.accentLight },
  headerCard: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.lg,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  title: { color: colors.text, fontSize: 24, fontWeight: '700' },
  artist: { color: colors.textSecondary, fontSize: 16, marginTop: 4 },
  meta: { color: colors.textSecondary, fontSize: 12, marginTop: spacing.sm },
  statusBadge: { marginTop: spacing.md },
  statusText: { color: colors.warning, fontWeight: '600' },
  statusComplete: { color: colors.success },
  section: {
    color: colors.textSecondary,
    fontSize: 12,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: spacing.sm,
  },
  collabRow: {
    backgroundColor: colors.card,
    borderRadius: radius.sm,
    padding: spacing.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  collabName: { color: colors.text, fontWeight: '600', fontSize: 15 },
  collabRole: { color: colors.textSecondary, fontSize: 12, marginTop: 2 },
  collabSacem: { color: colors.accentLight, fontSize: 11, marginTop: 2 },
  clausesBox: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  clause: { color: colors.text, fontSize: 13, marginBottom: spacing.xs },
  notes: { color: colors.textSecondary, fontSize: 13, marginTop: spacing.sm },
  btn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    padding: spacing.md,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.separator,
    marginBottom: spacing.sm,
    backgroundColor: colors.card,
  },
  primaryBtn: { backgroundColor: colors.accent, borderColor: colors.accent },
  btnText: { color: colors.accentLight, fontWeight: '600', fontSize: 15 },
  primaryBtnText: { color: colors.text, fontWeight: '700', fontSize: 15 },
});
