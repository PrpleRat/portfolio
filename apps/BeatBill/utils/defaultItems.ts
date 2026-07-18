export interface DefaultItem {
  id: string;
  description: string;
  defaultPrice: number | null;
}

export const DEFAULT_ITEMS: DefaultItem[] = [
  { id: 'mixing', description: 'Mixing (par titre)', defaultPrice: 80 },
  { id: 'mastering', description: 'Mastering (par titre)', defaultPrice: 50 },
  { id: 'beat-mp3', description: 'Beat Lease — MP3', defaultPrice: 29 },
  { id: 'beat-wav', description: 'Beat Lease — WAV', defaultPrice: 49 },
  { id: 'beat-trackout', description: 'Beat Lease — Trackout', defaultPrice: 99 },
  { id: 'beat-exclusive', description: 'Beat Exclusif', defaultPrice: 299 },
  { id: 'session', description: 'Session de prod (par heure)', defaultPrice: 60 },
  { id: 'revision', description: 'Revision', defaultPrice: 25 },
  { id: 'arrangement', description: 'Arrangement', defaultPrice: 150 },
  { id: 'custom', description: 'Custom', defaultPrice: null },
];
