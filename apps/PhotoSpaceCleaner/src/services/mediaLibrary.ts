import * as FileSystem from 'expo-file-system/legacy';
import * as MediaLibrary from 'expo-media-library';
import { Linking, Platform } from 'react-native';

import type { EnrichedAsset, MediaFilter } from '../types/media';
import {
  estimateBytes,
  filterDuplicateCandidates,
  matchesFilter,
  mediaTypeForFilter,
} from '../types/media';
import { shuffleArray } from '../utils/shuffle';

const PAGE_SIZE = 200;

export type LoadProgress = {
  assets: MediaLibrary.Asset[];
  loaded: number;
  total: number | null;
  syncing: boolean;
};

function filterPageItems(items: MediaLibrary.Asset[], filter: MediaFilter): MediaLibrary.Asset[] {
  if (filter === 'duplicates' || filter === 'icloud' || filter === 'random' || filter === 'all') {
    return items;
  }
  return items.filter((asset) => matchesFilter(asset, filter));
}

function applyFilter(assets: MediaLibrary.Asset[], filter: MediaFilter): MediaLibrary.Asset[] {
  if (filter === 'duplicates') {
    return filterDuplicateCandidates(assets);
  }
  if (filter === 'icloud' || filter === 'random' || filter === 'all') {
    return assets;
  }
  return assets.filter((asset) => matchesFilter(asset, filter));
}

function finalizeAssets(assets: MediaLibrary.Asset[], filter: MediaFilter): MediaLibrary.Asset[] {
  const result = applyFilter(assets, filter);
  if (filter === 'random') {
    return shuffleArray(result);
  }
  return result;
}

function mediaTypesForFilter(filter: MediaFilter): MediaLibrary.MediaTypeValue[] {
  const single = mediaTypeForFilter(filter);
  if (single) return single;
  return ['photo', 'video'];
}

function findOldestAsset(assets: MediaLibrary.Asset[]): MediaLibrary.Asset | undefined {
  if (!assets.length) return undefined;
  return assets.reduce((min, asset) => (asset.creationTime < min.creationTime ? asset : min));
}

async function fetchAssetsBatch(
  filter: MediaFilter,
  options: { after?: string; createdBefore?: number } = {}
) {
  const result = await MediaLibrary.getAssetsAsync({
    first: PAGE_SIZE,
    after: options.after,
    createdBefore: options.createdBefore,
    mediaType: mediaTypesForFilter(filter),
  });

  return {
    items: filterPageItems(result.assets, filter),
    hasNextPage: result.hasNextPage,
    endCursor: result.endCursor,
    totalCount: result.totalCount,
  };
}

/** Charge toute la photothèque (contourne le bug de pagination iOS après ~120 items). */
export async function loadEntireLibrary(
  filter: MediaFilter,
  onProgress: (progress: LoadProgress) => void,
  isCancelled?: () => boolean
): Promise<MediaLibrary.Asset[]> {
  const granted = await requestLibraryAccess();
  if (!granted) {
    onProgress({ assets: [], loaded: 0, total: null, syncing: false });
    return [];
  }

  if (filter === 'icloud') {
    return loadEntireICloudLibrary(onProgress, isCancelled);
  }

  const byId = new Map<string, MediaLibrary.Asset>();
  let total: number | null = null;
  let after: string | undefined;
  let createdBeforeMs: number | undefined;
  let mode: 'cursor' | 'timestamp' = 'cursor';
  let pages = 0;

  onProgress({ assets: [], loaded: 0, total: null, syncing: true });

  while (pages < 500 && !isCancelled?.()) {
    pages += 1;
    const sizeBefore = byId.size;

    if (mode === 'cursor') {
      const page = await fetchAssetsBatch(filter, { after });
      total = page.totalCount ?? total;

      for (const asset of page.items) {
        byId.set(asset.id, asset);
      }

      onProgress({ assets: applyFilter([...byId.values()], filter), loaded: byId.size, total, syncing: true });

      const added = byId.size - sizeBefore;
      if (!page.hasNextPage || (total != null && byId.size >= total)) {
        break;
      }

      if (added === 0) {
        mode = 'timestamp';
        createdBeforeMs = findOldestAsset([...byId.values()])?.creationTime;
        if (createdBeforeMs == null) break;
        continue;
      }

      after = page.endCursor;
      continue;
    }

    if (createdBeforeMs == null) break;

    const page = await fetchAssetsBatch(filter, { createdBefore: createdBeforeMs });
    total = page.totalCount ?? total;

    for (const asset of page.items) {
      byId.set(asset.id, asset);
    }

    onProgress({ assets: applyFilter([...byId.values()], filter), loaded: byId.size, total, syncing: true });

    const added = byId.size - sizeBefore;
    if (added === 0) break;

    const oldestInBatch = findOldestAsset(page.items);
    if (!oldestInBatch || oldestInBatch.creationTime >= createdBeforeMs) break;
    createdBeforeMs = oldestInBatch.creationTime;

    if (total != null && byId.size >= total) break;
  }

  const assets = finalizeAssets([...byId.values()], filter);
  onProgress({ assets, loaded: assets.length, total, syncing: false });
  return assets;
}

async function loadEntireICloudLibrary(
  onProgress: (progress: LoadProgress) => void,
  isCancelled?: () => boolean
): Promise<MediaLibrary.Asset[]> {
  const found: MediaLibrary.Asset[] = [];
  const seen = new Set<string>();
  let after: string | undefined;
  let hasMore = true;
  let pages = 0;
  let total: number | null = null;

  onProgress({ assets: [], loaded: 0, total: null, syncing: true });

  while (hasMore && pages < 300 && !isCancelled?.()) {
    pages += 1;
    const page = await fetchAssetsBatch('all', { after });
    total = page.totalCount ?? total;

    for (const asset of page.items) {
      if (seen.has(asset.id)) continue;
      try {
        const info = await MediaLibrary.getAssetInfoAsync(asset, {
          shouldDownloadFromNetwork: false,
        });
        if (info.isNetworkAsset) {
          seen.add(asset.id);
          found.push(asset);
        }
      } catch {
        // ignore
      }
    }

    onProgress({ assets: [...found], loaded: found.length, total, syncing: true });
    after = page.endCursor;
    hasMore = page.hasNextPage;

    if (!page.items.length) break;
  }

  onProgress({ assets: found, loaded: found.length, total, syncing: false });
  return found;
}

export type LibraryAccess = {
  granted: boolean;
  accessPrivileges: 'all' | 'limited' | 'none' | undefined;
};

function estimateSize(asset: MediaLibrary.Asset): number {
  return estimateBytes(asset);
}

async function readFileSize(localUri: string): Promise<number | null> {
  const fileInfo = await FileSystem.getInfoAsync(normalizePlayableUri(localUri));
  if (fileInfo.exists && 'size' in fileInfo && typeof fileInfo.size === 'number') {
    return fileInfo.size;
  }
  return null;
}

export function normalizePlayableUri(uri: string): string {
  let result = uri.trim();
  const hash = result.indexOf('#');
  if (hash !== -1) result = result.slice(0, hash);
  return result;
}

function isFileUri(uri: string): boolean {
  return uri.startsWith('file://');
}

function assetFromInfo(info: MediaLibrary.AssetInfo): MediaLibrary.Asset {
  return {
    id: info.id,
    filename: info.filename,
    uri: info.uri,
    mediaType: info.mediaType,
    width: info.width,
    height: info.height,
    creationTime: info.creationTime,
    modificationTime: info.modificationTime,
    duration: info.duration,
    mediaSubtypes: info.mediaSubtypes,
  };
}

export type PreviewLoadState = {
  progress: number;
  message: string;
};

export async function prepareAssetForPreview(
  assetId: string,
  onProgress: (state: PreviewLoadState) => void
): Promise<EnrichedAsset | null> {
  try {
    const granted = await requestLibraryAccess();
    if (!granted) return null;

    onProgress({ progress: 0.05, message: 'Accès au média…' });

    let info = await MediaLibrary.getAssetInfoAsync(assetId, {
      shouldDownloadFromNetwork: false,
    });

    const asset = assetFromInfo(info);
    const isVideo = info.mediaType === 'video';
    let isCloud = Boolean(info.isNetworkAsset);
    let localUri = info.localUri ? normalizePlayableUri(info.localUri) : null;
    const estimatedBytes = estimateSize(asset);

    const needsVideoDownload = isVideo && (isCloud || Platform.OS === 'android');

    if (needsVideoDownload) {
      onProgress({
        progress: 0.1,
        message: isCloud ? 'Téléchargement iCloud…' : 'Préparation de la vidéo…',
      });

      let synthetic = 0.1;
      const tick = setInterval(() => {
        synthetic = Math.min(0.9, synthetic + 0.012);
        onProgress({
          progress: synthetic,
          message: `Téléchargement… ${Math.round(synthetic * 100)}%`,
        });
      }, 400);

      try {
        info = await MediaLibrary.getAssetInfoAsync(assetId, {
          shouldDownloadFromNetwork: true,
        });
      } finally {
        clearInterval(tick);
      }

      isCloud = Boolean(info.isNetworkAsset);
      localUri = info.localUri ? normalizePlayableUri(info.localUri) : null;
    }

    onProgress({ progress: 0.92, message: isVideo ? 'Préparation lecture…' : 'Chargement…' });

    let displayUri: string;
    let sizeBytes = estimatedBytes;
    let isEstimatedSize = true;

    if (isVideo) {
      displayUri = Platform.OS === 'ios' ? info.uri : localUri && isFileUri(localUri) ? localUri : info.uri;
      if (!displayUri) {
        onProgress({ progress: 1, message: 'Vidéo inaccessible' });
        return null;
      }
      if (localUri && isFileUri(localUri)) {
        const realSize = await readFileSize(localUri);
        if (realSize) {
          sizeBytes = realSize;
          isEstimatedSize = false;
        }
      }
    } else {
      displayUri = localUri && isFileUri(localUri) ? localUri : info.uri;
      if (localUri && isFileUri(localUri)) {
        const realSize = await readFileSize(localUri);
        if (realSize) {
          sizeBytes = realSize;
          isEstimatedSize = false;
        }
      }
    }

    onProgress({ progress: 0.96, message: 'Presque prêt…' });

    return {
      asset: assetFromInfo(info),
      sizeBytes,
      isCloud,
      isEstimatedSize,
      displayUri,
    };
  } catch {
    onProgress({ progress: 1, message: 'Erreur de chargement' });
    return null;
  }
}

export async function resolveAssetSize(
  asset: MediaLibrary.Asset,
  options?: { downloadForDisplay?: boolean; sizeOnly?: boolean }
): Promise<EnrichedAsset> {
  try {
    const info = await MediaLibrary.getAssetInfoAsync(asset, {
      shouldDownloadFromNetwork: false,
    });

    const isCloud = Boolean(info.isNetworkAsset);
    let displayUri = info.localUri ?? asset.uri;
    let sizeBytes = 0;
    let isEstimatedSize = true;

    if (info.localUri) {
      const size = await readFileSize(info.localUri);
      if (size) {
        sizeBytes = size;
        isEstimatedSize = false;
      }
    }

    const needsDownload =
      !options?.sizeOnly &&
      options?.downloadForDisplay &&
      (!info.localUri || isCloud);
    if (needsDownload) {
      const downloaded = await MediaLibrary.getAssetInfoAsync(asset, {
        shouldDownloadFromNetwork: true,
      });
      if (downloaded.localUri) {
        displayUri = downloaded.localUri;
        const size = await readFileSize(downloaded.localUri);
        if (size) {
          sizeBytes = size;
          isEstimatedSize = false;
        }
      }
    }

    if (!sizeBytes) {
      sizeBytes = estimateSize(asset);
    }

    return { asset, sizeBytes, isCloud, isEstimatedSize, displayUri };
  } catch {
    return {
      asset,
      sizeBytes: estimateSize(asset),
      isCloud: false,
      isEstimatedSize: true,
      displayUri: asset.uri,
    };
  }
}

export async function getLibraryAccess(): Promise<LibraryAccess> {
  const current = await MediaLibrary.getPermissionsAsync();
  return {
    granted: current.status === 'granted',
    accessPrivileges: current.accessPrivileges,
  };
}

export async function requestLibraryAccess(): Promise<boolean> {
  const current = await MediaLibrary.getPermissionsAsync();
  if (current.status === 'granted') return true;

  const next = await MediaLibrary.requestPermissionsAsync();
  return next.status === 'granted';
}

export async function openPhotoAccessSettings(): Promise<void> {
  if (Platform.OS === 'ios') {
    await Linking.openURL('app-settings:');
    return;
  }
  await Linking.openSettings();
}

export async function loadLibraryStats() {
  const granted = await requestLibraryAccess();
  if (!granted) {
    return null;
  }

  const [photos, videos, albums, cloudSample] = await Promise.all([
    MediaLibrary.getAssetsAsync({ mediaType: 'photo', first: 1 }),
    MediaLibrary.getAssetsAsync({ mediaType: 'video', first: 1 }),
    MediaLibrary.getAlbumsAsync({ includeSmartAlbums: true }),
    scanCloudAssets(120),
  ]);

  return {
    photoCount: photos.totalCount,
    videoCount: videos.totalCount,
    albumCount: albums.length,
    cloudOnDevice: cloudSample.count,
    cloudScanned: cloudSample.scanned,
  };
}

/** Parcourt la photothèque et compte les médias stockés sur iCloud (pas en local). */
export async function scanCloudAssets(maxScan = 200): Promise<{ count: number; scanned: number }> {
  let count = 0;
  let scanned = 0;
  let after: string | undefined;
  let hasMore = true;

  while (hasMore && scanned < maxScan) {
    const page = await MediaLibrary.getAssetsAsync({
      first: Math.min(40, maxScan - scanned),
      after,
      mediaType: ['photo', 'video'],
    });

    const flags = await Promise.all(
      page.assets.map(async (asset) => {
        try {
          const info = await MediaLibrary.getAssetInfoAsync(asset, {
            shouldDownloadFromNetwork: false,
          });
          return Boolean(info.isNetworkAsset);
        } catch {
          return false;
        }
      })
    );

    count += flags.filter(Boolean).length;
    scanned += page.assets.length;
    after = page.endCursor;
    hasMore = page.hasNextPage;
  }

  return { count, scanned };
}

async function loadICloudPage(after?: string) {
  let cursor = after;
  let hasMore = true;
  const found: MediaLibrary.Asset[] = [];
  let safety = 0;

  while (found.length < 24 && hasMore && safety < 8) {
    safety += 1;
    const page = await fetchAssetsBatch('all', { after: cursor });

    for (const asset of page.items) {
      try {
        const info = await MediaLibrary.getAssetInfoAsync(asset, {
          shouldDownloadFromNetwork: false,
        });
        if (info.isNetworkAsset) {
          found.push(asset);
          if (found.length >= 24) break;
        }
      } catch {
        // ignore unreadable asset
      }
    }

    cursor = page.endCursor;
    hasMore = page.hasNextPage;
    if (!page.items.length) break;
  }

  return {
    items: found,
    hasNextPage: hasMore,
    endCursor: cursor,
    totalCount: undefined,
  };
}

export async function loadAssetsPage(
  filter: MediaFilter,
  after?: string
): Promise<{
  items: MediaLibrary.Asset[];
  hasNextPage: boolean;
  endCursor?: string;
  totalCount?: number;
}> {
  const granted = await requestLibraryAccess();
  if (!granted) {
    return { items: [], hasNextPage: false };
  }

  if (filter === 'icloud') {
    return loadICloudPage(after);
  }

  const page = await fetchAssetsBatch(filter, { after });
  return {
    items: page.items,
    hasNextPage: page.hasNextPage,
    endCursor: page.endCursor,
    totalCount: page.totalCount,
  };
}

function quickEstimate(asset: MediaLibrary.Asset): EnrichedAsset {
  return {
    asset,
    sizeBytes: estimateSize(asset),
    isCloud: false,
    isEstimatedSize: true,
    displayUri: asset.uri,
  };
}

async function loadAllVideos(
  onProgress?: (loaded: number, phase: 'scan') => void,
  isCancelled?: () => boolean
): Promise<MediaLibrary.Asset[]> {
  const byId = new Map<string, MediaLibrary.Asset>();
  let after: string | undefined;
  let createdBeforeMs: number | undefined;
  let mode: 'cursor' | 'timestamp' = 'cursor';
  let pages = 0;

  while (pages < 500 && !isCancelled?.()) {
    pages += 1;
    const sizeBefore = byId.size;

    if (mode === 'cursor') {
      const page = await fetchAssetsBatch('videos', { after });
      for (const asset of page.items) {
        byId.set(asset.id, asset);
      }
      onProgress?.(byId.size, 'scan');

      if (!page.hasNextPage) break;

      if (byId.size === sizeBefore) {
        mode = 'timestamp';
        createdBeforeMs = findOldestAsset([...byId.values()])?.creationTime;
        if (createdBeforeMs == null) break;
        continue;
      }

      after = page.endCursor;
      continue;
    }

    if (createdBeforeMs == null) break;

    const page = await fetchAssetsBatch('videos', { createdBefore: createdBeforeMs });
    for (const asset of page.items) {
      byId.set(asset.id, asset);
    }
    onProgress?.(byId.size, 'scan');

    if (byId.size === sizeBefore) break;

    const oldestInBatch = findOldestAsset(page.items);
    if (!oldestInBatch || oldestInBatch.creationTime >= createdBeforeMs) break;
    createdBeforeMs = oldestInBatch.creationTime;
  }

  return [...byId.values()];
}

async function resolveSizeBatch(assets: MediaLibrary.Asset[]): Promise<EnrichedAsset[]> {
  const results: EnrichedAsset[] = [];
  for (const asset of assets) {
    results.push(await resolveAssetSize(asset, { sizeOnly: true }));
  }
  return results;
}

export async function loadHeavyAssets(
  limit = 30,
  onProgress?: (loaded: number, phase: 'scan' | 'size', detail?: string) => void,
  isCancelled?: () => boolean
): Promise<EnrichedAsset[]> {
  const granted = await requestLibraryAccess();
  if (!granted) return [];

  const videos = await loadAllVideos(
    (loaded) => onProgress?.(loaded, 'scan'),
    isCancelled
  );
  if (isCancelled?.()) return [];

  const photos: MediaLibrary.Asset[] = [];
  let after: string | undefined;
  let photoPages = 0;
  while (photoPages < 4 && photos.length < 300 && !isCancelled?.()) {
    photoPages += 1;
    const page = await fetchAssetsBatch('photos', { after });
    photos.push(...page.items);
    if (!page.hasNextPage) break;
    after = page.endCursor;
  }

  const candidates = [...videos, ...photos]
    .map(quickEstimate)
    .sort((a, b) => b.sizeBytes - a.sizeBytes)
    .slice(0, Math.max(limit * 3, 60));

  const resolved: EnrichedAsset[] = [];
  const batchSize = 2;

  for (let i = 0; i < candidates.length; i += batchSize) {
    if (isCancelled?.()) break;
    const batch = candidates.slice(i, i + batchSize).map((c) => c.asset);
    const sized = await resolveSizeBatch(batch);
    resolved.push(...sized);
    onProgress?.(
      resolved.length,
      'size',
      `${resolved.length}/${candidates.length} tailles lues`
    );
  }

  return resolved.sort((a, b) => b.sizeBytes - a.sizeBytes).slice(0, limit);
}


export async function deleteAssets(assets: MediaLibrary.Asset[]): Promise<void> {
  if (!assets.length) return;
  await MediaLibrary.deleteAssetsAsync(assets);
}

export async function presentMorePhotosPicker(): Promise<void> {
  try {
    if (MediaLibrary.presentPermissionsPickerAsync) {
      await MediaLibrary.presentPermissionsPickerAsync();
      return;
    }
  } catch {
    // Expo Go — fallback réglages iOS
  }
  await openPhotoAccessSettings();
}
