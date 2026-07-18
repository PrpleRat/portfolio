import type { CurrencyCode, PaymentMode, VatRate } from '@/constants/theme';

export type InvoiceStatus = 'pending' | 'paid' | 'overdue';
export type QuoteStatus = 'draft' | 'sent' | 'accepted' | 'converted' | 'expired';
export type LegalStatus = 'auto_entrepreneur' | 'micro_entreprise' | 'societe' | 'particulier';
export type ContractType = 'beat_lease' | 'exclusive' | 'work_for_hire' | 'session' | 'custom';
export type RecurrenceFrequency = 'weekly' | 'monthly' | 'quarterly';

export interface LineItem {
  description: string;
  qty: number;
  unitPrice: number;
  total: number;
}

export interface InvoiceAction {
  type: 'created' | 'reminded' | 'paid' | 'status_changed' | 'shared' | 'deleted';
  date: string;
  note?: string;
}

export interface Invoice {
  id: string;
  number: string;
  status: InvoiceStatus;
  clientName: string;
  clientEmail: string;
  project?: string;
  items: LineItem[];
  subtotal: number;
  vatRate: VatRate;
  vatAmount: number;
  total: number;
  currency: CurrencyCode;
  paymentMode: PaymentMode;
  paymentRef: string;
  notes?: string;
  createdAt: string;
  dueDate: string;
  paidAt: string | null;
  pdfUri?: string;
  actions: InvoiceAction[];
  quoteId?: string;
}

export interface Quote {
  id: string;
  number: string;
  status: QuoteStatus;
  clientName: string;
  clientEmail: string;
  project?: string;
  items: LineItem[];
  subtotal: number;
  vatRate: VatRate;
  vatAmount: number;
  total: number;
  currency: CurrencyCode;
  notes?: string;
  validityDays: number;
  createdAt: string;
  expiresAt: string;
  convertedInvoiceId?: string;
  pdfUri?: string;
}

export interface Client {
  id: string;
  name: string;
  email: string;
  createdAt: string;
}

export interface ServiceCatalogItem {
  id: string;
  description: string;
  unitPrice: number;
  currency: CurrencyCode;
  category: string;
}

export interface ContractTemplate {
  id: string;
  title: string;
  type: ContractType;
  body: string;
  isBuiltin?: boolean;
}

export interface RecurringInvoice {
  id: string;
  label: string;
  clientName: string;
  clientEmail: string;
  project?: string;
  items: LineItem[];
  vatRate: VatRate;
  currency: CurrencyCode;
  frequency: RecurrenceFrequency;
  nextRunDate: string;
  paymentMode: PaymentMode;
  paymentRef: string;
  notes?: string;
  active: boolean;
}

export interface ProducerProfile {
  name: string;
  email: string;
  phone?: string;
  siret?: string;
  vatNumber?: string;
  address?: string;
  country: string;
  paymentMode: PaymentMode;
  paymentRef: string;
  bic?: string;
  currency: CurrencyCode;
  defaultVatRate: VatRate;
  defaultDueDays: number;
  invoicePrefix: string;
  quotePrefix: string;
  remindersEnabled: boolean;
  reminderDelayDays: number;
  logoUri?: string;
  legalStatus: LegalStatus;
  latePenaltyEnabled: boolean;
  recoveryIndemnityEnabled: boolean;
  customLegalFooter?: string;
}

export interface InvoiceDraft {
  clientName: string;
  clientEmail: string;
  project: string;
  number: string;
  issueDate: Date;
  dueDate: Date;
  items: LineItem[];
  vatRate: VatRate;
  notes: string;
  paymentMode: PaymentMode;
  paymentRef: string;
  currency: CurrencyCode;
}

export interface QuoteDraft {
  clientName: string;
  clientEmail: string;
  project: string;
  number: string;
  issueDate: Date;
  expiresAt: Date;
  items: LineItem[];
  vatRate: VatRate;
  notes: string;
  currency: CurrencyCode;
  validityDays: number;
}

export interface SearchResult {
  type: 'invoice' | 'quote' | 'client';
  id: string;
  title: string;
  subtitle: string;
  amount?: number;
  currency?: CurrencyCode;
}

export const defaultProfile: ProducerProfile = {
  name: '',
  email: '',
  country: 'France',
  paymentMode: 'PayPal.me',
  paymentRef: '',
  currency: 'EUR',
  defaultVatRate: 0,
  defaultDueDays: 14,
  invoicePrefix: 'BB',
  quotePrefix: 'DV',
  remindersEnabled: true,
  reminderDelayDays: 7,
  legalStatus: 'auto_entrepreneur',
  latePenaltyEnabled: true,
  recoveryIndemnityEnabled: true,
};

export function getCurrencySymbol(code: CurrencyCode): string {
  const map: Record<CurrencyCode, string> = {
    EUR: '€',
    USD: '$',
    GBP: '£',
    CHF: 'CHF',
  };
  return map[code];
}

export function formatMoney(amount: number, currency: CurrencyCode): string {
  const symbol = getCurrencySymbol(currency);
  const formatted = amount.toFixed(2).replace('.', ',');
  if (currency === 'CHF') return `${formatted} ${symbol}`;
  return `${formatted} ${symbol}`;
}

export function formatDate(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

export function computeLineTotal(qty: number, unitPrice: number): number {
  return Math.round(qty * unitPrice * 100) / 100;
}

export function computeInvoiceTotals(items: LineItem[], vatRate: VatRate) {
  const subtotal = Math.round(items.reduce((sum, i) => sum + i.total, 0) * 100) / 100;
  const vatAmount = Math.round(subtotal * (vatRate / 100) * 100) / 100;
  const total = Math.round((subtotal + vatAmount) * 100) / 100;
  return { subtotal, vatAmount, total };
}

export function effectiveStatus(invoice: Invoice): InvoiceStatus {
  if (invoice.status === 'paid') return 'paid';
  if (invoice.status === 'overdue') return 'overdue';
  if (new Date(invoice.dueDate) < new Date()) return 'overdue';
  return 'pending';
}

export function effectiveQuoteStatus(quote: Quote): QuoteStatus {
  if (quote.status === 'converted') return 'converted';
  if (quote.status === 'accepted') return 'accepted';
  if (new Date(quote.expiresAt) < new Date()) return 'expired';
  return quote.status;
}

export function statusLabel(status: InvoiceStatus): string {
  switch (status) {
    case 'paid':
      return 'PAYÉ';
    case 'overdue':
      return 'EN RETARD';
    default:
      return 'EN ATTENTE';
  }
}

export function quoteStatusLabel(status: QuoteStatus): string {
  switch (status) {
    case 'draft':
      return 'BROUILLON';
    case 'sent':
      return 'ENVOYÉ';
    case 'accepted':
      return 'ACCEPTÉ';
    case 'converted':
      return 'FACTURÉ';
    case 'expired':
      return 'EXPIRÉ';
    default:
      return String(status).toUpperCase();
  }
}

export function generateReminderMessage(invoice: Invoice, producerName: string): string {
  return `Bonjour ${invoice.clientName},

Je me permets de te relancer concernant la facture ${invoice.number}
d'un montant de ${formatMoney(invoice.total, invoice.currency)}, émise le ${formatDate(invoice.createdAt)}, arrivée à échéance
le ${formatDate(invoice.dueDate)}.

N'hésite pas à me confirmer la réception. Merci !

${producerName}`;
}

export function addRecurrenceInterval(date: Date, frequency: RecurrenceFrequency): Date {
  const d = new Date(date);
  if (frequency === 'weekly') d.setDate(d.getDate() + 7);
  else if (frequency === 'monthly') d.setMonth(d.getMonth() + 1);
  else d.setMonth(d.getMonth() + 3);
  return d;
}
