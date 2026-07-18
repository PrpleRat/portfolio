import AsyncStorage from '@react-native-async-storage/async-storage';
import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import * as DocumentPicker from 'expo-document-picker';
import { STORAGE_KEYS } from '@/constants/theme';
import type {
  Client,
  ContractTemplate,
  Invoice,
  ProducerProfile,
  Quote,
  RecurringInvoice,
  ServiceCatalogItem,
} from '@/types';
import { defaultProfile, effectiveStatus, formatDate } from '@/types';

export interface BeatBillBackup {
  version: 2;
  app: 'BeatBill';
  exportedAt: string;
  invoices: Invoice[];
  quotes: Quote[];
  clients: Client[];
  catalog: ServiceCatalogItem[];
  contracts: ContractTemplate[];
  recurring: RecurringInvoice[];
  profile: ProducerProfile;
  invoiceCount: Record<string, number>;
  quoteCount: Record<string, number>;
}

function migrateProfile(raw: Partial<ProducerProfile> | null | undefined): ProducerProfile {
  if (!raw || typeof raw !== 'object') return { ...defaultProfile };
  return {
    ...defaultProfile,
    ...raw,
    quotePrefix: raw.quotePrefix ?? defaultProfile.quotePrefix,
    legalStatus: raw.legalStatus ?? defaultProfile.legalStatus,
    latePenaltyEnabled: raw.latePenaltyEnabled ?? defaultProfile.latePenaltyEnabled,
    recoveryIndemnityEnabled: raw.recoveryIndemnityEnabled ?? defaultProfile.recoveryIndemnityEnabled,
  };
}

export async function exportBackup(): Promise<void> {
  const keys = [
    STORAGE_KEYS.invoices,
    STORAGE_KEYS.quotes,
    STORAGE_KEYS.clients,
    STORAGE_KEYS.catalog,
    STORAGE_KEYS.contracts,
    STORAGE_KEYS.recurring,
    STORAGE_KEYS.profile,
    STORAGE_KEYS.invoiceCount,
    STORAGE_KEYS.quoteCount,
  ] as const;

  const raw = await AsyncStorage.multiGet([...keys]);
  const map = Object.fromEntries(raw) as Record<string, string | null>;

  const backup: BeatBillBackup = {
    version: 2,
    app: 'BeatBill',
    exportedAt: new Date().toISOString(),
    invoices: map[STORAGE_KEYS.invoices] ? JSON.parse(map[STORAGE_KEYS.invoices]!) : [],
    quotes: map[STORAGE_KEYS.quotes] ? JSON.parse(map[STORAGE_KEYS.quotes]!) : [],
    clients: map[STORAGE_KEYS.clients] ? JSON.parse(map[STORAGE_KEYS.clients]!) : [],
    catalog: map[STORAGE_KEYS.catalog] ? JSON.parse(map[STORAGE_KEYS.catalog]!) : [],
    contracts: map[STORAGE_KEYS.contracts] ? JSON.parse(map[STORAGE_KEYS.contracts]!) : [],
    recurring: map[STORAGE_KEYS.recurring] ? JSON.parse(map[STORAGE_KEYS.recurring]!) : [],
    profile: migrateProfile(map[STORAGE_KEYS.profile] ? JSON.parse(map[STORAGE_KEYS.profile]!) : defaultProfile),
    invoiceCount: map[STORAGE_KEYS.invoiceCount] ? JSON.parse(map[STORAGE_KEYS.invoiceCount]!) : {},
    quoteCount: map[STORAGE_KEYS.quoteCount] ? JSON.parse(map[STORAGE_KEYS.quoteCount]!) : {},
  };

  const filename = `beatbill-backup-${new Date().toISOString().slice(0, 10)}.json`;
  const uri = `${FileSystem.cacheDirectory}${filename}`;
  await FileSystem.writeAsStringAsync(uri, JSON.stringify(backup, null, 2));

  if (!(await Sharing.isAvailableAsync())) {
    throw new Error('Partage indisponible sur cet appareil');
  }
  await Sharing.shareAsync(uri, {
    mimeType: 'application/json',
    dialogTitle: 'Exporter la sauvegarde BeatBill',
  });
}

export async function importBackup(): Promise<void> {
  const result = await DocumentPicker.getDocumentAsync({
    type: 'application/json',
    copyToCacheDirectory: true,
  });

  if (result.canceled || !result.assets?.[0]?.uri) return;

  const raw = await FileSystem.readAsStringAsync(result.assets[0].uri);
  const backup = JSON.parse(raw) as BeatBillBackup & { version?: number };

  if (backup.app !== 'BeatBill') {
    throw new Error('Fichier de sauvegarde BeatBill invalide');
  }

  const profile = migrateProfile(backup.profile);

  const pairs: [string, string][] = [
    [STORAGE_KEYS.invoices, JSON.stringify(backup.invoices ?? [])],
    [STORAGE_KEYS.clients, JSON.stringify(backup.clients ?? [])],
    [STORAGE_KEYS.profile, JSON.stringify(profile)],
    [STORAGE_KEYS.invoiceCount, JSON.stringify(backup.invoiceCount ?? {})],
  ];

  if (backup.version === 2 || backup.quotes) {
    pairs.push(
      [STORAGE_KEYS.quotes, JSON.stringify(backup.quotes ?? [])],
      [STORAGE_KEYS.catalog, JSON.stringify(backup.catalog ?? [])],
      [STORAGE_KEYS.contracts, JSON.stringify(backup.contracts ?? [])],
      [STORAGE_KEYS.recurring, JSON.stringify(backup.recurring ?? [])],
      [STORAGE_KEYS.quoteCount, JSON.stringify(backup.quoteCount ?? {})]
    );
  }

  await AsyncStorage.multiSet(pairs);
}

export async function exportInvoicesCsv(invoices: Invoice[]): Promise<void> {
  const header = 'Numero;Client;Email;Statut;Emission;Echeance;Sous-total;TVA;Total;Devise;Projet';
  const rows = invoices.map((inv) => {
    const status = effectiveStatus(inv);
    const statusLabel =
      status === 'paid' ? 'Payee' : status === 'overdue' ? 'En retard' : 'En attente';
    return [
      inv.number,
      inv.clientName,
      inv.clientEmail,
      statusLabel,
      formatDate(inv.createdAt),
      formatDate(inv.dueDate),
      inv.subtotal.toFixed(2),
      inv.vatAmount.toFixed(2),
      inv.total.toFixed(2),
      inv.currency,
      inv.project ?? '',
    ]
      .map((cell) => `"${String(cell).replace(/"/g, '""')}"`)
      .join(';');
  });

  const csv = '\uFEFF' + [header, ...rows].join('\n');
  const filename = `beatbill-factures-${new Date().toISOString().slice(0, 10)}.csv`;
  const uri = `${FileSystem.cacheDirectory}${filename}`;
  await FileSystem.writeAsStringAsync(uri, csv);

  if (!(await Sharing.isAvailableAsync())) {
    throw new Error('Partage indisponible sur cet appareil');
  }
  await Sharing.shareAsync(uri, {
    mimeType: 'text/csv',
    dialogTitle: 'Exporter les factures (CSV)',
  });
}
