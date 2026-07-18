export const colors = {
  background: '#0a0a0a',
  card: '#141414',
  section: '#1a1a1a',
  accent: '#22c55e',
  accentLight: '#4ade80',
  text: '#f8f8f8',
  textSecondary: '#888888',
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
  invoices: '@beatbill/invoices',
  clients: '@beatbill/clients',
  profile: '@beatbill/profile',
  invoiceCount: '@beatbill/invoice_count',
  quoteCount: '@beatbill/quote_count',
  quotes: '@beatbill/quotes',
  catalog: '@beatbill/catalog',
  contracts: '@beatbill/contracts',
  recurring: '@beatbill/recurring',
} as const;

export const LEGAL_STATUS_OPTIONS = [
  { value: 'auto_entrepreneur' as const, label: 'Auto-entrepreneur' },
  { value: 'micro_entreprise' as const, label: 'Micro-entreprise' },
  { value: 'societe' as const, label: 'Société (SARL/SAS…)' },
  { value: 'particulier' as const, label: 'Particulier' },
];

export const VAT_RATES = [0, 5.5, 10, 20] as const;
export const DUE_DATE_OPTIONS = [7, 14, 30] as const;
export const REMINDER_DELAYS = [3, 7, 14] as const;

export const CURRENCIES = [
  { code: 'EUR', symbol: '€', label: 'Euro (€)' },
  { code: 'USD', symbol: '$', label: 'Dollar ($)' },
  { code: 'GBP', symbol: '£', label: 'Livre (£)' },
  { code: 'CHF', symbol: 'CHF', label: 'Franc suisse (CHF)' },
] as const;

export const PAYMENT_MODES = [
  'PayPal.me',
  'Virement (IBAN)',
  'Lydia',
  'Sumeria',
  'Wise',
  'Autre',
] as const;

export type CurrencyCode = (typeof CURRENCIES)[number]['code'];
export type PaymentMode = (typeof PAYMENT_MODES)[number];
export type VatRate = (typeof VAT_RATES)[number];
