import AsyncStorage from '@react-native-async-storage/async-storage';
import { STORAGE_KEYS } from '@/constants/theme';

export async function getNextNumber(
  prefix: string,
  countKey: string = STORAGE_KEYS.invoiceCount
): Promise<string> {
  const year = new Date().getFullYear();
  const raw = await AsyncStorage.getItem(countKey);
  const counts: Record<string, number> = raw ? JSON.parse(raw) : {};
  const key = `${prefix}-${year}`;
  const next = (counts[key] ?? 0) + 1;
  counts[key] = next;
  await AsyncStorage.setItem(countKey, JSON.stringify(counts));
  return `${prefix}-${year}-${String(next).padStart(3, '0')}`;
}

export async function getNextInvoiceNumber(prefix = 'BB'): Promise<string> {
  return getNextNumber(prefix, STORAGE_KEYS.invoiceCount);
}

export async function getNextQuoteNumber(prefix = 'DV'): Promise<string> {
  return getNextNumber(prefix, STORAGE_KEYS.quoteCount);
}
