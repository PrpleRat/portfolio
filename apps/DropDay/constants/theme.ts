export const colors = {
  background: '#0a0a0a',
  card: '#141414',
  section: '#1a1a1a',
  accent: '#6366f1',
  accentLight: '#818cf8',
  success: '#22c55e',
  warning: '#f97316',
  soon: '#eab308',
  error: '#ef4444',
  future: '#374151',
  text: '#f8f8f8',
  textSecondary: '#888888',
  separator: '#222222',
  white: '#ffffff',
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
} as const;

export const radius = {
  sm: 8,
  md: 12,
  lg: 16,
} as const;

export const STORAGE_KEYS = {
  releases: '@dropday/releases',
  isPro: '@dropday/is_pro',
  profile: '@dropday/profile',
} as const;

export const CURRENCIES = [
  { code: 'EUR' as const, symbol: '€', label: 'Euro (€)' },
  { code: 'USD' as const, symbol: '$', label: 'Dollar ($)' },
] as const;

export type CurrencyCode = (typeof CURRENCIES)[number]['code'];

export const FORMAT_OPTIONS = [
  { value: 'single' as const, emoji: '🎵', label: 'Single' },
  { value: 'double_single' as const, emoji: '🎶', label: 'Double single' },
  { value: 'ep' as const, emoji: '📀', label: 'EP' },
  { value: 'album' as const, emoji: '💿', label: 'Album' },
  { value: 'clip' as const, emoji: '🎬', label: 'Clip YouTube' },
] as const;

export const LEVEL_OPTIONS = [
  { value: 'beginner' as const, emoji: '🌱', label: 'Débutant', hint: '< 1k followers' },
  { value: 'intermediate' as const, emoji: '📈', label: 'Intermédiaire', hint: '1k–10k followers' },
  { value: 'advanced' as const, emoji: '🚀', label: 'Avancé', hint: '10k+ followers' },
] as const;

export const FREE_RELEASE_LIMIT = 1;
export const PRO_PRODUCT_ID = 'dropday_pro';
