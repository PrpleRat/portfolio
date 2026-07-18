import type { Asset, MediaTypeValue } from 'expo-media-library';

export type MediaFilter =
  | 'all'
  | 'photos'
  | 'videos'
  | 'screenshots'
  | 'live'
  | 'icloud'
  | 'random'
  | 'panoramas'
  | 'screen_recordings'
  | 'old'
  | 'large_videos'
  | 'duplicates'
  | 'timelapse'
  | 'recent';

export type EnrichedAsset = {
  asset: Asset;
  sizeBytes: number;
  isCloud: boolean;
  isEstimatedSize: boolean;
  displayUri: string;
};

export type QueueItem = EnrichedAsset & {
  queuedAt: number;
};

const ONE_YEAR_MS = 365 * 24 * 60 * 60 * 1000;
const ONE_MONTH_MS = 30 * 24 * 60 * 60 * 1000;

export function estimateBytes(asset: Asset): number {
  if (asset.mediaType === 'video') {
    return estimateVideoBytes(asset);
  }
  const pixels = Math.max(asset.width, 1) * Math.max(asset.height, 1);
  return Math.round(pixels * 0.35);
}

/** Estimation vidéo basée résolution × durée (meilleure que 1 Mo/s fixe). */
export function estimateVideoBytes(asset: Asset): number {
  const durationSec = Math.max(asset.duration ?? 0, 1);
  const w = Math.max(asset.width ?? 1920, 1);
  const h = Math.max(asset.height ?? 1080, 1);
  const megapixels = (w * h) / 1_000_000;

  let bitsPerSecond: number;
  if (megapixels >= 7) bitsPerSecond = 50_000_000;
  else if (megapixels >= 2.5) bitsPerSecond = 18_000_000;
  else if (megapixels >= 1) bitsPerSecond = 8_000_000;
  else bitsPerSecond = 4_000_000;

  const name = asset.filename?.toLowerCase() ?? '';
  if (isScreenRecording(asset)) bitsPerSecond *= 1.8;
  if (name.includes('prores')) bitsPerSecond *= 3;
  if (asset.mediaSubtypes?.includes('highFrameRate')) bitsPerSecond *= 1.35;

  return Math.round((bitsPerSecond / 8) * durationSec);
}

export function isScreenshot(asset: Asset): boolean {
  const name = asset.filename?.toLowerCase() ?? '';
  return (
    name.includes('screenshot') ||
    name.includes('capture d') ||
    name.includes('simulator screen') ||
    (asset.mediaSubtypes?.includes('screenshot') ?? false)
  );
}

export function isLivePhoto(asset: Asset): boolean {
  return asset.mediaSubtypes?.includes('livePhoto') ?? false;
}

export function isPanorama(asset: Asset): boolean {
  return asset.mediaSubtypes?.includes('panorama') ?? false;
}

export function isScreenRecording(asset: Asset): boolean {
  const name = asset.filename?.toLowerCase() ?? '';
  return (
    asset.mediaSubtypes?.includes('stream') ||
    name.includes('screen recording') ||
    name.includes('rpreplay') ||
    name.includes('enregistrement')
  );
}

export function isTimelapse(asset: Asset): boolean {
  return asset.mediaSubtypes?.includes('timelapse') ?? false;
}

export function isOldMedia(asset: Asset): boolean {
  return asset.creationTime < Date.now() - ONE_YEAR_MS;
}

export function isRecentMedia(asset: Asset): boolean {
  return asset.creationTime >= Date.now() - ONE_MONTH_MS;
}

export function isLargeVideo(asset: Asset): boolean {
  if (asset.mediaType !== 'video') return false;
  return asset.duration >= 45 || estimateBytes(asset) > 40_000_000;
}

export function matchesFilter(asset: Asset, filter: MediaFilter): boolean {
  switch (filter) {
    case 'all':
    case 'random':
      return true;
    case 'photos':
      return asset.mediaType === 'photo';
    case 'videos':
      return asset.mediaType === 'video';
    case 'screenshots':
      return isScreenshot(asset);
    case 'live':
      return isLivePhoto(asset);
    case 'panoramas':
      return isPanorama(asset);
    case 'screen_recordings':
      return isScreenRecording(asset);
    case 'timelapse':
      return isTimelapse(asset);
    case 'old':
      return isOldMedia(asset);
    case 'recent':
      return isRecentMedia(asset);
    case 'large_videos':
      return isLargeVideo(asset);
    case 'icloud':
    case 'duplicates':
      return true;
    default:
      return true;
  }
}

export function filterDuplicateCandidates(assets: Asset[]): Asset[] {
  const groups = new Map<string, Asset[]>();

  for (const asset of assets) {
    const bucket = Math.floor(asset.creationTime / 3000);
    const key = `${asset.width}x${asset.height}-${bucket}-${asset.mediaType}`;
    const list = groups.get(key) ?? [];
    list.push(asset);
    groups.set(key, list);
  }

  const duplicates: Asset[] = [];
  for (const group of groups.values()) {
    if (group.length < 2) continue;
    group.sort((a, b) => a.creationTime - b.creationTime);
    duplicates.push(...group.slice(1));
  }

  return duplicates;
}

export function filterLabel(filter: MediaFilter): string {
  const labels: Record<MediaFilter, string> = {
    all: 'Tout',
    photos: 'Photos',
    videos: 'Vidéos',
    screenshots: 'Captures',
    live: 'Live Photos',
    icloud: 'iCloud uniquement',
    random: 'Mode aléatoire',
    panoramas: 'Panoramas',
    screen_recordings: 'Enregistrements écran',
    old: 'Plus d\'1 an',
    large_videos: 'Grosses vidéos',
    duplicates: 'Doublons probables',
    timelapse: 'Timelapse',
    recent: 'Ce mois-ci',
  };
  return labels[filter];
}

export function mediaTypeForFilter(filter: MediaFilter): MediaTypeValue[] | undefined {
  switch (filter) {
    case 'photos':
    case 'panoramas':
    case 'live':
    case 'screenshots':
    case 'timelapse':
      return ['photo'];
    case 'videos':
    case 'large_videos':
    case 'screen_recordings':
      return ['video'];
    default:
      return undefined;
  }
}
