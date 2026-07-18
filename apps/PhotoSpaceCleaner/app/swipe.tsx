import { Ionicons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { router, useLocalSearchParams } from 'expo-router';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import type { Asset } from 'expo-media-library';

import { SwipeCard } from '../src/components/SwipeCard';
import { useCleaner } from '../src/context/CleanerContext';
import { colors } from '../src/constants/theme';
import { loadEntireLibrary, resolveAssetSize } from '../src/services/mediaLibrary';
import type { EnrichedAsset, MediaFilter } from '../src/types/media';
import { filterLabel } from '../src/types/media';
import { formatBytes } from '../src/utils/format';
import { shuffleArray } from '../src/utils/shuffle';

type SwipeHistoryEntry =
  | { type: 'delete'; item: EnrichedAsset }
  | { type: 'keep'; assetId: string };

export default function SwipeScreen() {
  const params = useLocalSearchParams<{ filter?: string; shuffle?: string }>();
  const filter = (params.filter as MediaFilter) || 'all';
  const wantShuffle = params.shuffle === '1' || filter === 'random';
  const { addToQueue, removeFromQueue, markSkipped, unmarkSkipped, queue } = useCleaner();

  const [deck, setDeck] = useState<Asset[]>([]);
  const [enrichedMap, setEnrichedMap] = useState<Record<string, EnrichedAsset>>({});
  const [totalInLibrary, setTotalInLibrary] = useState<number | null>(null);
  const [loadedCount, setLoadedCount] = useState(0);
  const [syncing, setSyncing] = useState(true);
  const [index, setIndex] = useState(0);
  const [freedBytes, setFreedBytes] = useState(0);
  const [history, setHistory] = useState<SwipeHistoryEntry[]>([]);

  const cancelledRef = useRef(false);

  useEffect(() => {
    cancelledRef.current = false;
    setSyncing(true);
    setIndex(0);
    setDeck([]);
    setHistory([]);
    setLoadedCount(0);
    setTotalInLibrary(null);

    loadEntireLibrary(
      filter,
      ({ assets, loaded, total, syncing: isSyncing }) => {
        let next = assets;
        if (!isSyncing && wantShuffle && filter !== 'random') {
          next = shuffleArray(assets);
        }
        if (!isSyncing) {
          setDeck(next);
          setIndex(0);
          setHistory([]);
        }
        setLoadedCount(loaded);
        setTotalInLibrary(total);
        setSyncing(isSyncing);
      },
      () => cancelledRef.current
    );

    return () => {
      cancelledRef.current = true;
    };
  }, [filter, wantShuffle]);

  const enrichNext = useCallback(async (assets: Asset[]) => {
    const toLoad = assets.slice(0, 3);
    const results = await Promise.all(
      toLoad.map((asset) => resolveAssetSize(asset, { sizeOnly: true }))
    );
    setEnrichedMap((prev) => {
      const next = { ...prev };
      for (const item of results) {
        next[item.asset.id] = {
          ...item,
          displayUri:
            item.asset.mediaType === 'video' ? item.asset.uri : item.displayUri,
        };
      }
      return next;
    });
  }, []);

  useEffect(() => {
    if (deck.length) {
      enrichNext(deck.slice(index, index + 3));
    }
  }, [deck, index, enrichNext]);

  const current = deck[index];
  const next = deck[index + 1];

  const handleDelete = () => {
    const item = enrichedMap[current?.id ?? ''];
    if (item) {
      addToQueue(item);
      setFreedBytes((v) => v + item.sizeBytes);
      setHistory((h) => [...h, { type: 'delete', item }]);
    }
    setIndex((v) => v + 1);
  };

  const handleKeep = () => {
    if (current) {
      markSkipped(current.id);
      setHistory((h) => [...h, { type: 'keep', assetId: current.id }]);
    }
    setIndex((v) => v + 1);
  };

  const handleUndo = () => {
    const last = history[history.length - 1];
    if (!last || index === 0) return;

    if (last.type === 'delete') {
      removeFromQueue(last.item.asset.id);
      setFreedBytes((v) => Math.max(0, v - last.item.sizeBytes));
    } else {
      unmarkSkipped(last.assetId);
    }

    setHistory((h) => h.slice(0, -1));
    setIndex((v) => v - 1);
  };

  const handleReshuffle = () => {
    Haptics.selectionAsync();
    setDeck((prev) => {
      const head = prev.slice(0, index);
      const rest = shuffleArray(prev.slice(index));
      return [...head, ...rest];
    });
  };

  const canUndo = history.length > 0 && index > 0;

  if (syncing && deck.length === 0) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={colors.accent} size="large" />
        <Text style={styles.loadingText}>Synchronisation de ta photothèque…</Text>
      </View>
    );
  }

  if (!current) {
    if (syncing) {
      return (
        <View style={styles.center}>
          <ActivityIndicator color={colors.accent} size="large" />
          <Text style={styles.loadingText}>
            {loadedCount.toLocaleString('fr-FR')} chargées
            {totalInLibrary ? ` / ${totalInLibrary.toLocaleString('fr-FR')}` : ''}…
          </Text>
        </View>
      );
    }

    return (
      <View style={styles.center}>
        <Ionicons name="checkmark-circle" size={64} color={colors.keep} />
        <Text style={styles.doneTitle}>Session terminée</Text>
        <Text style={styles.doneBody}>
          {filterLabel(filter)} — ~{formatBytes(freedBytes)} marqués pour suppression
        </Text>
        <Pressable style={styles.primaryBtn} onPress={() => router.push('/queue')}>
          <Text style={styles.primaryBtnText}>Voir la corbeille</Text>
        </Pressable>
        <Pressable style={styles.secondaryBtn} onPress={() => router.back()}>
          <Text style={styles.secondaryBtnText}>Retour</Text>
        </Pressable>
      </View>
    );
  }

  const currentEnriched = enrichedMap[current.id] ?? {
    asset: current,
    sizeBytes: 0,
    isCloud: false,
    isEstimatedSize: true,
    displayUri: current.uri,
  };

  const nextEnriched = next
    ? enrichedMap[next.id] ?? {
        asset: next,
        sizeBytes: 0,
        isCloud: false,
        isEstimatedSize: true,
        displayUri: next.uri,
      }
    : null;

  const totalLabel = totalInLibrary
    ? `${index + 1} · ${loadedCount.toLocaleString('fr-FR')} / ${totalInLibrary.toLocaleString('fr-FR')}`
    : `${index + 1} / ${deck.length}`;

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.filterLabel}>{filterLabel(filter)}</Text>
        <View style={styles.headerRight}>
          {syncing && (
            <View style={styles.syncPill}>
              <ActivityIndicator size="small" color={colors.cloud} />
              <Text style={styles.syncText}>Sync…</Text>
            </View>
          )}
          <Text style={styles.counter}>{totalLabel}</Text>
        </View>
      </View>

      <View style={styles.deck}>
        {nextEnriched && (
          <SwipeCard
            key={next.id}
            item={nextEnriched}
            onDelete={() => {}}
            onKeep={() => {}}
            isTop={false}
          />
        )}
        <SwipeCard
          key={current.id}
          item={currentEnriched}
          onDelete={handleDelete}
          onKeep={handleKeep}
          isTop
        />
      </View>

      <View style={styles.actions}>
        <Pressable
          style={[styles.actionBtn, styles.undoBtn, !canUndo && styles.actionDisabled]}
          disabled={!canUndo}
          onPress={() => {
            Haptics.selectionAsync();
            handleUndo();
          }}
        >
          <Ionicons name="arrow-undo" size={22} color={canUndo ? colors.text : colors.textMuted} />
        </Pressable>
        <Pressable
          style={[styles.actionBtn, styles.shuffleBtn]}
          onPress={handleReshuffle}
        >
          <Ionicons name="shuffle" size={22} color={colors.text} />
        </Pressable>
        <Pressable
          style={[styles.actionBtn, styles.deleteBtn]}
          onPress={() => {
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
            handleDelete();
          }}
        >
          <Ionicons name="trash" size={28} color={colors.text} />
        </Pressable>
        <Pressable
          style={[styles.actionBtn, styles.keepBtn]}
          onPress={() => {
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
            handleKeep();
          }}
        >
          <Ionicons name="heart" size={26} color={colors.text} />
        </Pressable>
      </View>

      <Text style={styles.hint}>← supprimer · garder → · ▶ lire les vidéos · 🔀 mélange</Text>
      <Text style={styles.sessionStats}>~{formatBytes(freedBytes)} en attente cette session</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, paddingBottom: 24 },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 32,
  },
  loadingText: { color: colors.textMuted, marginTop: 12, textAlign: 'center' },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingHorizontal: 20,
    paddingTop: 8,
    paddingBottom: 4,
    gap: 12,
  },
  headerRight: { alignItems: 'flex-end', gap: 6, flex: 1 },
  filterLabel: { color: colors.textMuted, fontWeight: '600' },
  syncPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: 'rgba(100,210,255,0.15)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  syncText: { color: colors.cloud, fontSize: 11, fontWeight: '700' },
  counter: { color: colors.text, fontWeight: '700', fontSize: 12, textAlign: 'right' },
  deck: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 420,
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 20,
    paddingVertical: 12,
  },
  actionBtn: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: colors.border,
  },
  actionDisabled: { opacity: 0.35 },
  undoBtn: { backgroundColor: colors.surface, width: 52, height: 52, borderRadius: 26 },
  shuffleBtn: { backgroundColor: colors.surfaceLight, width: 52, height: 52, borderRadius: 26 },
  deleteBtn: { backgroundColor: colors.delete, borderColor: colors.delete },
  keepBtn: { backgroundColor: colors.keep, borderColor: colors.keep },
  hint: { textAlign: 'center', color: colors.textMuted, fontSize: 13 },
  sessionStats: { textAlign: 'center', color: colors.accent, marginTop: 6, fontWeight: '600' },
  doneTitle: { color: colors.text, fontSize: 24, fontWeight: '800', marginTop: 12 },
  doneBody: { color: colors.textMuted, textAlign: 'center', marginTop: 8 },
  primaryBtn: {
    marginTop: 24,
    backgroundColor: colors.delete,
    paddingHorizontal: 24,
    paddingVertical: 14,
    borderRadius: 14,
  },
  primaryBtnText: { color: colors.text, fontWeight: '700' },
  secondaryBtn: { marginTop: 12, padding: 12 },
  secondaryBtnText: { color: colors.accent, fontWeight: '600' },
});
