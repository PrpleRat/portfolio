import { Image } from 'expo-image';
import * as Haptics from 'expo-haptics';
import { router } from 'expo-router';
import React, { useState } from 'react';
import {
  Alert,
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { useCleaner } from '../src/context/CleanerContext';
import { colors } from '../src/constants/theme';
import { formatBytes } from '../src/utils/format';

export default function QueueScreen() {
  const { queue, queueSizeBytes, removeFromQueue, clearQueue, commitDelete } = useCleaner();
  const [deleting, setDeleting] = useState(false);

  const confirmDelete = () => {
    if (!queue.length) return;

    Alert.alert(
      'Supprimer définitivement ?',
      `${queue.length} élément(s) · environ ${formatBytes(queueSizeBytes)} seront supprimés de ta photothèque (et souvent d'iCloud). Cette action est irréversible.`,
      [
        { text: 'Annuler', style: 'cancel' },
        {
          text: 'Supprimer',
          style: 'destructive',
          onPress: async () => {
            setDeleting(true);
            try {
              const count = await commitDelete();
              Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
              Alert.alert('Espace libéré', `${count} élément(s) supprimé(s).`, [
                { text: 'OK', onPress: () => router.back() },
              ]);
            } catch {
              Alert.alert('Erreur', 'La suppression a échoué. Vérifie les permissions photos.');
            } finally {
              setDeleting(false);
            }
          },
        },
      ]
    );
  };

  if (!queue.length) {
    return (
      <View style={styles.center}>
        <Text style={styles.emptyTitle}>Corbeille vide</Text>
        <Text style={styles.emptyBody}>Swipe des photos à supprimer pour les retrouver ici.</Text>
        <Pressable style={styles.primaryBtn} onPress={() => router.push({ pathname: '/swipe', params: { filter: 'all' } })}>
          <Text style={styles.primaryBtnText}>Commencer à trier</Text>
        </Pressable>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.summary}>
        <Text style={styles.summarySize}>{formatBytes(queueSizeBytes)}</Text>
        <Text style={styles.summarySub}>
          {queue.length} élément(s) · suppression définitive après confirmation
        </Text>
      </View>

      <FlatList
        data={queue}
        keyExtractor={(item) => item.asset.id}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => (
          <View style={styles.row}>
            <Image source={{ uri: item.displayUri ?? item.asset.uri }} style={styles.thumb} contentFit="cover" />
            <View style={styles.meta}>
              <Text style={styles.size}>{formatBytes(item.sizeBytes)}</Text>
              <Text style={styles.filename} numberOfLines={1}>
                {item.asset.filename}
              </Text>
            </View>
            <Pressable onPress={() => removeFromQueue(item.asset.id)} hitSlop={12}>
              <Text style={styles.remove}>Retirer</Text>
            </Pressable>
          </View>
        )}
      />

      <View style={styles.footer}>
        <Pressable style={styles.clearBtn} onPress={clearQueue} disabled={deleting}>
          <Text style={styles.clearBtnText}>Vider la corbeille</Text>
        </Pressable>
        <Pressable style={styles.deleteBtn} onPress={confirmDelete} disabled={deleting}>
          <Text style={styles.deleteBtnText}>{deleting ? 'Suppression…' : 'Supprimer tout'}</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32 },
  emptyTitle: { color: colors.text, fontSize: 22, fontWeight: '700' },
  emptyBody: { color: colors.textMuted, textAlign: 'center', marginTop: 8 },
  primaryBtn: {
    marginTop: 20,
    backgroundColor: colors.accent,
    paddingHorizontal: 20,
    paddingVertical: 14,
    borderRadius: 14,
  },
  primaryBtnText: { color: colors.text, fontWeight: '700' },
  summary: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  summarySize: { color: colors.delete, fontSize: 28, fontWeight: '800' },
  summarySub: { color: colors.textMuted, marginTop: 4 },
  list: { padding: 16, paddingBottom: 120 },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 10,
    backgroundColor: colors.surface,
    padding: 10,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
  },
  thumb: { width: 52, height: 52, borderRadius: 8 },
  meta: { flex: 1 },
  size: { color: colors.text, fontWeight: '700' },
  filename: { color: colors.textMuted, fontSize: 12, marginTop: 2 },
  remove: { color: colors.accent, fontWeight: '600', fontSize: 13 },
  footer: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    padding: 16,
    paddingBottom: 28,
    backgroundColor: colors.bg,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    gap: 10,
  },
  clearBtn: {
    padding: 14,
    borderRadius: 12,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
  },
  clearBtnText: { color: colors.textMuted, fontWeight: '600' },
  deleteBtn: {
    padding: 16,
    borderRadius: 14,
    alignItems: 'center',
    backgroundColor: colors.delete,
  },
  deleteBtnText: { color: colors.text, fontWeight: '800', fontSize: 16 },
});
