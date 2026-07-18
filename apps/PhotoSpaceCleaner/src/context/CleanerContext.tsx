import AsyncStorage from '@react-native-async-storage/async-storage';
import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';

import { deleteAssets } from '../services/mediaLibrary';
import type { EnrichedAsset, QueueItem } from '../types/media';

const STORAGE_KEY = '@photospacecleaner/queue';

type CleanerContextValue = {
  queue: QueueItem[];
  queueSizeBytes: number;
  addToQueue: (item: EnrichedAsset) => void;
  removeFromQueue: (assetId: string) => void;
  clearQueue: () => void;
  commitDelete: () => Promise<number>;
  skippedIds: Set<string>;
  markSkipped: (assetId: string) => void;
  unmarkSkipped: (assetId: string) => void;
};

const CleanerContext = createContext<CleanerContextValue | null>(null);

export function CleanerProvider({ children }: { children: React.ReactNode }) {
  const [queue, setQueue] = useState<QueueItem[]>([]);
  const [skippedIds, setSkippedIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY).then((raw) => {
      if (!raw) return;
      try {
        const parsed = JSON.parse(raw) as QueueItem[];
        setQueue(parsed);
      } catch {
        // ignore corrupt storage
      }
    });
  }, []);

  useEffect(() => {
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(queue));
  }, [queue]);

  const addToQueue = useCallback((item: EnrichedAsset) => {
    setQueue((prev) => {
      if (prev.some((q) => q.asset.id === item.asset.id)) return prev;
      return [...prev, { ...item, queuedAt: Date.now() }];
    });
  }, []);

  const removeFromQueue = useCallback((assetId: string) => {
    setQueue((prev) => prev.filter((q) => q.asset.id !== assetId));
  }, []);

  const clearQueue = useCallback(() => {
    setQueue([]);
  }, []);

  const markSkipped = useCallback((assetId: string) => {
    setSkippedIds((prev) => new Set(prev).add(assetId));
  }, []);

  const unmarkSkipped = useCallback((assetId: string) => {
    setSkippedIds((prev) => {
      const next = new Set(prev);
      next.delete(assetId);
      return next;
    });
  }, []);

  const commitDelete = useCallback(async () => {
    const assets = queue.map((q) => q.asset);
    const count = assets.length;
    await deleteAssets(assets);
    setQueue([]);
    return count;
  }, [queue]);

  const queueSizeBytes = useMemo(
    () => queue.reduce((sum, item) => sum + item.sizeBytes, 0),
    [queue]
  );

  const value = useMemo(
    () => ({
      queue,
      queueSizeBytes,
      addToQueue,
      removeFromQueue,
      clearQueue,
      commitDelete,
      skippedIds,
      markSkipped,
      unmarkSkipped,
    }),
    [queue, queueSizeBytes, addToQueue, removeFromQueue, clearQueue, commitDelete, skippedIds, markSkipped, unmarkSkipped]
  );

  return <CleanerContext.Provider value={value}>{children}</CleanerContext.Provider>;
}

export function useCleaner() {
  const ctx = useContext(CleanerContext);
  if (!ctx) throw new Error('useCleaner must be used within CleanerProvider');
  return ctx;
}
