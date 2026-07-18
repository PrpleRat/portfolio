export const colors = {
  background: '#0a0a0a',
  card: '#141414',
  section: '#1a1a1a',
  accent: '#8b5cf6',
  accentLight: '#a78bfa',
  text: '#f8f8f8',
  textSecondary: '#888888',
  success: '#22c55e',
  warning: '#f97316',
  error: '#ef4444',
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
  splits: '@splitpad/splits',
  collaborators: '@splitpad/collaborators',
  profile: '@splitpad/profile',
  isPro: '@splitpad/is_pro',
} as const;

export const FREE_SPLIT_LIMIT = 2;
export const PRO_PRODUCT_ID = 'splitpad_pro';

export const GENRES = [
  'Rap FR',
  'Trap',
  'Drill',
  'Afro',
  'R&B',
  'Pop',
  'Autre',
] as const;

export const ROLES = [
  'Producteur',
  'Co-producteur',
  'Parolier',
  'Compositeur',
  'Artiste',
  'Arrangeur',
  'Custom',
] as const;

export const CURRENCIES = [
  { code: 'EUR', symbol: '€', label: 'Euro (€)' },
  { code: 'USD', symbol: '$', label: 'Dollar ($)' },
] as const;

export const DEFAULT_CLAUSES = [
  "Ce split s'applique à toutes les versions du morceau",
  'En cas de sample non clearé, ce split est suspendu',
  'Accord valable pour ce morceau uniquement (pas les remixes)',
] as const;

export type Genre = (typeof GENRES)[number];
export type Role = (typeof ROLES)[number];
export type CurrencyCode = (typeof CURRENCIES)[number]['code'];
