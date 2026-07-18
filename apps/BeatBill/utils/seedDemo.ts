import AsyncStorage from '@react-native-async-storage/async-storage';
import { STORAGE_KEYS } from '@/constants/theme';
import { defaultProfile } from '@/types';
import { uuid } from '@/utils/uuid';
import type { Invoice } from '@/types';

const DEMO_PROFILE = {
  ...defaultProfile,
  name: 'Studio BeatFlow',
  email: 'contact@beatflow.fr',
  phone: '06 12 34 56 78',
  country: 'France',
  paymentMode: 'PayPal.me' as const,
  paymentRef: 'paypal.me/beatflow',
  currency: 'EUR' as const,
  defaultVatRate: 0 as const,
  defaultDueDays: 14,
  invoicePrefix: 'BB',
};

const DEMO_INVOICES: Invoice[] = [
  {
    id: uuid(),
    number: 'BB-2026-001',
    status: 'paid',
    clientName: 'Niska',
    clientEmail: 'contact@niska.fr',
    project: 'Album Commando — Mixing',
    items: [
      { description: 'Mixing — Commando', qty: 1, unitPrice: 80, total: 80 },
      { description: 'Mastering', qty: 1, unitPrice: 50, total: 50 },
    ],
    subtotal: 130,
    vatRate: 0,
    vatAmount: 0,
    total: 130,
    currency: 'EUR',
    paymentMode: 'PayPal.me',
    paymentRef: 'paypal.me/beatflow',
    notes: 'Paiement sous 14 jours',
    createdAt: new Date(Date.now() - 5 * 86400000).toISOString(),
    dueDate: new Date(Date.now() + 9 * 86400000).toISOString(),
    paidAt: new Date(Date.now() - 2 * 86400000).toISOString(),
    actions: [
      { type: 'created', date: new Date(Date.now() - 5 * 86400000).toISOString() },
      { type: 'paid', date: new Date(Date.now() - 2 * 86400000).toISOString() },
    ],
  },
  {
    id: uuid(),
    number: 'BB-2026-002',
    status: 'pending',
    clientName: 'Laylow',
    clientEmail: 'booking@laylow.fr',
    project: 'Beat Lease — WAV',
    items: [{ description: 'Beat Lease — WAV', qty: 1, unitPrice: 49, total: 49 }],
    subtotal: 49,
    vatRate: 0,
    vatAmount: 0,
    total: 49,
    currency: 'EUR',
    paymentMode: 'PayPal.me',
    paymentRef: 'paypal.me/beatflow',
    createdAt: new Date(Date.now() - 2 * 86400000).toISOString(),
    dueDate: new Date(Date.now() + 12 * 86400000).toISOString(),
    paidAt: null,
    actions: [{ type: 'created', date: new Date(Date.now() - 2 * 86400000).toISOString() }],
  },
];

const DEMO_CLIENTS = [
  { id: uuid(), name: 'Niska', email: 'contact@niska.fr', createdAt: new Date().toISOString() },
  { id: uuid(), name: 'Laylow', email: 'booking@laylow.fr', createdAt: new Date().toISOString() },
];

export async function seedDemoData(): Promise<void> {
  await AsyncStorage.multiSet([
    [STORAGE_KEYS.profile, JSON.stringify(DEMO_PROFILE)],
    [STORAGE_KEYS.invoices, JSON.stringify(DEMO_INVOICES)],
    [STORAGE_KEYS.clients, JSON.stringify(DEMO_CLIENTS)],
    [STORAGE_KEYS.invoiceCount, JSON.stringify({ 'BB-2026': 2 })],
  ]);
}

export async function hasAnyData(): Promise<boolean> {
  const profile = await AsyncStorage.getItem(STORAGE_KEYS.profile);
  const invoices = await AsyncStorage.getItem(STORAGE_KEYS.invoices);
  return Boolean(profile || invoices);
}
