import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import React, { memo, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { useCleaner } from '../src/context/CleanerContext';
import { colors } from '../src/constants/theme';
import { loadHeavyAssets } from '../src/services/mediaLibrary';
import type { EnrichedAsset } from '../src/types/media';
import { formatBytes, formatDate, formatDuration } from '../src/utils/format';

const HeavyRow = memo(function HeavyRow({
  item,
  queued,
  onPreview,
  onAdd,
}: {
  item: EnrichedAsset;
  queued: boolean;
  onPreview: () => void;
  onAdd: () => void;
}) {
  const isVideo = item.asset.mediaType === 'video';

  return (
    <View style={[styles.row, queued && styles.rowQueued]}>
      <Pressable style={[styles.thumb, isVideo && styles.thumbVideo]} onPress={onPreview}>
        <Ionicons
          name={isVideo ? 'play-circle' : 'image'}
          size={isVideo ? 28 : 22}
          color={isVideo ? colors.warning : colors.accent}
        />
      </Pressable>
      <Pressable style={styles.meta} onPress={onPreview}>
        <Text style={styles.size}>
          {formatBytes(item.sizeBytes)}
          {item.isEstimatedSize ? ' ≈' : ''}
        </Text>
        <Text style={styles.filename} numberOfLines={1}>
          {item.asset.filename}
        </Text>
        <Text style={styles.date}>
          {formatDate(item.asset.creationTime)}
          {isVideo ? ` · ${formatDuration(item.asset.duration)}` : ''}
          {item.isCloud ? ' · iCloud' : ''}
        </Text>
      </Pressable>
      <Pressable
        style={[styles.addBtn, queued && styles.addBtnDone]}
        onPress={() => !queued && onAdd()}
      >
        <Ionicons name={queued ? 'checkmark' : 'add'} size={22} color={colors.text} />
      </Pressable>
    </View>
  );
});

export default function HeavyScreen() {
  const { addToQueue, queue } = useCleaner();
  const [items, setItems] = useState<EnrichedAsset[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [progress, setProgress] = useState('Scan des vidéos…');
  const queuedIds = new Set(queue.map((q) => q.asset.id));

  useEffect(() => {
    let cancelled = false;

    (async () => {
      try {
        const data = await loadHeavyAssets(
          30,
          (loaded, phase, detail) => {
            if (cancelled) return;
            if (phase === 'scan') {
              setProgress(`${loaded} vidéos scannées…`);
            } else {
              setProgress(detail ?? `Tailles réelles… ${loaded}`);
            }
          },
          () => cancelled
        );
        if (!cancelled) setItems(data);
      } catch {
        if (!cancelled) setError('Analyse impossible. Réessaie.');
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, []);

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={colors.accent} size="large" />
        <Text style={styles.loadingText}>{progress}</Text>
        <Text style={styles.loadingHint}>Toutes tes vidéos sont analysées — ça peut prendre 1-2 min</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.center}>
        <Text style={styles.errorText}>{error}</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.intro}>
        Top 30 par taille — touche ▶ pour lire, + pour la corbeille. Taille réelle si le fichier est sur l'iPhone.
      </Text>
      <FlatList
        data={items}
        keyExtractor={(item) => item.asset.id}
        contentContainerStyle={styles.list}
        initialNumToRender={8}
        maxToRenderPerBatch={6}
        windowSize={5}
        removeClippedSubviews
        getItemLayout={(_, index) => ({ length: 78, offset: 78 * index, index })}
        renderItem={({ item }) => (
          <HeavyRow
            item={item}
            queued={queuedIds.has(item.asset.id)}
            onPreview={() =>
              router.push({ pathname: '/preview', params: { id: item.asset.id } })
            }
            onAdd={() => addToQueue(item)}
          />
        )}
        ListFooterComponent={
          <Pressable style={styles.footerBtn} onPress={() => router.push('/queue')}>
            <Text style={styles.footerBtnText}>Voir la corbeille ({queue.length})</Text>
          </Pressable>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24 },
  loadingText: { color: colors.text, marginTop: 12, textAlign: 'center', fontWeight: '600' },
  loadingHint: { color: colors.textMuted, marginTop: 8, textAlign: 'center', fontSize: 13 },
  errorText: { color: colors.delete, textAlign: 'center' },
  intro: {
    color: colors.textMuted,
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 4,
    lineHeight: 20,
    fontSize: 14,
  },
  list: { padding: 16, paddingBottom: 32 },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: 14,
    marginBottom: 10,
    padding: 10,
    borderWidth: 1,
    borderColor: colors.border,
    gap: 12,
    height: 68,
  },
  rowQueued: { borderColor: colors.delete, opacity: 0.7 },
  thumb: {
    width: 48,
    height: 48,
    borderRadius: 10,
    backgroundColor: colors.surfaceLight,
    alignItems: 'center',
    justifyContent: 'center',
  },
  thumbVideo: { backgroundColor: 'rgba(255,214,10,0.12)' },
  meta: { flex: 1 },
  size: { color: colors.text, fontWeight: '800', fontSize: 16 },
  filename: { color: colors.textMuted, fontSize: 13, marginTop: 2 },
  date: { color: colors.textMuted, fontSize: 12, marginTop: 2 },
  addBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.delete,
    alignItems: 'center',
    justifyContent: 'center',
  },
  addBtnDone: { backgroundColor: colors.surfaceLight },
  footerBtn: {
    marginTop: 8,
    backgroundColor: colors.delete,
    padding: 16,
    borderRadius: 14,
    alignItems: 'center',
  },
  footerBtnText: { color: colors.text, fontWeight: '700' },
});
