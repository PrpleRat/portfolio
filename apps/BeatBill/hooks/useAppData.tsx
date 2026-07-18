import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { STORAGE_KEYS } from '@/constants/theme';
import {
  type Client,
  type ContractTemplate,
  type Invoice,
  type InvoiceStatus,
  type ProducerProfile,
  type Quote,
  type RecurringInvoice,
  type ServiceCatalogItem,
  addRecurrenceInterval,
  computeInvoiceTotals,
  defaultProfile,
  effectiveStatus,
} from '@/types';
import { uuid } from '@/utils/uuid';
import { clearLegacyPurchaseFlag } from '@/hooks/useServices';
import { getNextInvoiceNumber } from '@/utils/invoiceNumber';
import { DEFAULT_CONTRACTS } from '@/utils/defaultContracts';

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

interface AppDataContextValue {
  invoices: Invoice[];
  quotes: Quote[];
  clients: Client[];
  catalog: ServiceCatalogItem[];
  contracts: ContractTemplate[];
  recurring: RecurringInvoice[];
  profile: ProducerProfile;
  loading: boolean;
  refresh: () => Promise<void>;
  saveInvoice: (invoice: Invoice) => Promise<void>;
  updateInvoice: (id: string, patch: Partial<Invoice>) => Promise<void>;
  deleteInvoice: (id: string) => Promise<void>;
  saveQuote: (quote: Quote) => Promise<void>;
  updateQuote: (id: string, patch: Partial<Quote>) => Promise<void>;
  deleteQuote: (id: string) => Promise<void>;
  convertQuoteToInvoice: (quoteId: string) => Promise<Invoice>;
  upsertClient: (name: string, email: string) => Promise<Client>;
  saveProfile: (profile: ProducerProfile) => Promise<void>;
  saveCatalogItem: (item: ServiceCatalogItem) => Promise<void>;
  deleteCatalogItem: (id: string) => Promise<void>;
  saveContract: (contract: ContractTemplate) => Promise<void>;
  deleteContract: (id: string) => Promise<void>;
  saveRecurring: (item: RecurringInvoice) => Promise<void>;
  deleteRecurring: (id: string) => Promise<void>;
  getInvoiceById: (id: string) => Invoice | undefined;
  getQuoteById: (id: string) => Quote | undefined;
  invoiceCount: number;
  quoteCount: number;
}

const AppDataContext = createContext<AppDataContextValue | null>(null);

async function readJson<T>(key: string, fallback: T): Promise<T> {
  const raw = await AsyncStorage.getItem(key);
  if (!raw) return fallback;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

function sortInvoices(list: Invoice[]) {
  return [...list].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
}

function sortQuotes(list: Quote[]) {
  return [...list].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
}

function buildInvoiceFromRecurring(rec: RecurringInvoice, number: string): Invoice {
  const totals = computeInvoiceTotals(rec.items, rec.vatRate);
  const now = new Date();
  const due = new Date(now);
  due.setDate(due.getDate() + 14);
  return {
    id: uuid(),
    number,
    status: 'pending',
    clientName: rec.clientName,
    clientEmail: rec.clientEmail,
    project: rec.project,
    items: rec.items,
    subtotal: totals.subtotal,
    vatRate: rec.vatRate,
    vatAmount: totals.vatAmount,
    total: totals.total,
    currency: rec.currency,
    paymentMode: rec.paymentMode,
    paymentRef: rec.paymentRef,
    notes: rec.notes,
    createdAt: now.toISOString(),
    dueDate: due.toISOString(),
    paidAt: null,
    actions: [{ type: 'created', date: now.toISOString(), note: `Récurrent : ${rec.label}` }],
  };
}

export function AppDataProvider({ children }: { children: ReactNode }) {
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [quotes, setQuotes] = useState<Quote[]>([]);
  const [clients, setClients] = useState<Client[]>([]);
  const [catalog, setCatalog] = useState<ServiceCatalogItem[]>([]);
  const [contracts, setContracts] = useState<ContractTemplate[]>([]);
  const [recurring, setRecurring] = useState<RecurringInvoice[]>([]);
  const [profile, setProfile] = useState<ProducerProfile>(defaultProfile);
  const [loading, setLoading] = useState(true);

  const persistInvoices = async (next: Invoice[]) => {
    await AsyncStorage.setItem(STORAGE_KEYS.invoices, JSON.stringify(next));
    setInvoices(sortInvoices(next));
  };

  const persistQuotes = async (next: Quote[]) => {
    await AsyncStorage.setItem(STORAGE_KEYS.quotes, JSON.stringify(next));
    setQuotes(sortQuotes(next));
  };

  const persistClients = async (next: Client[]) => {
    await AsyncStorage.setItem(STORAGE_KEYS.clients, JSON.stringify(next));
    setClients([...next].sort((a, b) => a.name.localeCompare(b.name)));
  };

  const persistCatalog = async (next: ServiceCatalogItem[]) => {
    await AsyncStorage.setItem(STORAGE_KEYS.catalog, JSON.stringify(next));
    setCatalog(next);
  };

  const persistContracts = async (next: ContractTemplate[]) => {
    const customOnly = next.filter((c) => !c.isBuiltin);
    await AsyncStorage.setItem(STORAGE_KEYS.contracts, JSON.stringify(customOnly));
    setContracts(customOnly);
  };

  const persistRecurring = async (next: RecurringInvoice[]) => {
    await AsyncStorage.setItem(STORAGE_KEYS.recurring, JSON.stringify(next));
    setRecurring(next);
  };

  const processRecurringInvoices = useCallback(
    async (recList: RecurringInvoice[], invList: Invoice[], prof: ProducerProfile) => {
      const today = new Date();
      today.setHours(23, 59, 59, 999);
      let updatedRecurring = [...recList];
      let updatedInvoices = [...invList];
      let changed = false;

      for (const rec of recList.filter((r) => r.active)) {
        if (new Date(rec.nextRunDate) > today) continue;
        const number = await getNextInvoiceNumber(prof.invoicePrefix);
        const invoice = buildInvoiceFromRecurring(rec, number);
        updatedInvoices = [...updatedInvoices, invoice];
        updatedRecurring = updatedRecurring.map((r) =>
          r.id === rec.id
            ? { ...r, nextRunDate: addRecurrenceInterval(new Date(rec.nextRunDate), r.frequency).toISOString() }
            : r
        );
        if (prof.remindersEnabled) {
          const { scheduleInvoiceRemindersFor } = await import('@/hooks/useServices');
          await scheduleInvoiceRemindersFor(invoice, prof.reminderDelayDays);
        }
        changed = true;
      }

      if (changed) {
        await AsyncStorage.multiSet([
          [STORAGE_KEYS.invoices, JSON.stringify(sortInvoices(updatedInvoices))],
          [STORAGE_KEYS.recurring, JSON.stringify(updatedRecurring)],
        ]);
        setInvoices(sortInvoices(updatedInvoices));
        setRecurring(updatedRecurring);
      }
    },
    []
  );

  const refresh = useCallback(async () => {
    const [inv, quo, cli, cat, con, rec, profRaw] = await Promise.all([
      readJson<Invoice[]>(STORAGE_KEYS.invoices, []),
      readJson<Quote[]>(STORAGE_KEYS.quotes, []),
      readJson<Client[]>(STORAGE_KEYS.clients, []),
      readJson<ServiceCatalogItem[]>(STORAGE_KEYS.catalog, []),
      readJson<ContractTemplate[]>(STORAGE_KEYS.contracts, []),
      readJson<RecurringInvoice[]>(STORAGE_KEYS.recurring, []),
      readJson<Partial<ProducerProfile>>(STORAGE_KEYS.profile, defaultProfile),
    ]);
    const prof = migrateProfile(profRaw);
    if (JSON.stringify(profRaw) !== JSON.stringify(prof)) {
      await AsyncStorage.setItem(STORAGE_KEYS.profile, JSON.stringify(prof));
    }
    setInvoices(sortInvoices(inv));
    setQuotes(sortQuotes(quo));
    setClients([...cli].sort((a, b) => a.name.localeCompare(b.name)));
    setCatalog(cat);
    setContracts(con.filter((c) => !c.isBuiltin));
    setRecurring(rec);
    setProfile(prof);
    await processRecurringInvoices(rec, inv, prof);
    setLoading(false);
  }, [processRecurringInvoices]);

  useEffect(() => {
    clearLegacyPurchaseFlag();
    refresh();
  }, [refresh]);

  const saveInvoice = useCallback(
    async (invoice: Invoice) => {
      const next = [...invoices.filter((i) => i.id !== invoice.id), invoice];
      await persistInvoices(next);
    },
    [invoices]
  );

  const updateInvoice = useCallback(
    async (id: string, patch: Partial<Invoice>) => {
      const next = invoices.map((inv) => (inv.id === id ? { ...inv, ...patch } : inv));
      await persistInvoices(next);
    },
    [invoices]
  );

  const deleteInvoice = useCallback(
    async (id: string) => {
      await persistInvoices(invoices.filter((i) => i.id !== id));
    },
    [invoices]
  );

  const saveQuote = useCallback(
    async (quote: Quote) => {
      const next = [...quotes.filter((q) => q.id !== quote.id), quote];
      await persistQuotes(next);
    },
    [quotes]
  );

  const updateQuote = useCallback(
    async (id: string, patch: Partial<Quote>) => {
      const next = quotes.map((q) => (q.id === id ? { ...q, ...patch } : q));
      await persistQuotes(next);
    },
    [quotes]
  );

  const deleteQuote = useCallback(
    async (id: string) => {
      await persistQuotes(quotes.filter((q) => q.id !== id));
    },
    [quotes]
  );

  const convertQuoteToInvoice = useCallback(
    async (quoteId: string): Promise<Invoice> => {
      const quote = quotes.find((q) => q.id === quoteId);
      if (!quote) throw new Error('Devis introuvable');
      if (quote.status === 'converted') throw new Error('Devis déjà converti');

      const number = await getNextInvoiceNumber(profile.invoicePrefix);
      const now = new Date();
      const due = new Date(now);
      due.setDate(due.getDate() + profile.defaultDueDays);

      const invoice: Invoice = {
        id: uuid(),
        number,
        status: 'pending',
        clientName: quote.clientName,
        clientEmail: quote.clientEmail,
        project: quote.project,
        items: quote.items,
        subtotal: quote.subtotal,
        vatRate: quote.vatRate,
        vatAmount: quote.vatAmount,
        total: quote.total,
        currency: quote.currency,
        paymentMode: profile.paymentMode,
        paymentRef: profile.paymentRef,
        notes: quote.notes,
        createdAt: now.toISOString(),
        dueDate: due.toISOString(),
        paidAt: null,
        quoteId: quote.id,
        actions: [{ type: 'created', date: now.toISOString(), note: `Depuis devis ${quote.number}` }],
      };

      await upsertClientInternal(clients, quote.clientName, quote.clientEmail, persistClients);
      await persistInvoices([...invoices, invoice]);
      await persistQuotes(
        quotes.map((q) =>
          q.id === quoteId
            ? { ...q, status: 'converted' as const, convertedInvoiceId: invoice.id }
            : q
        )
      );
      return invoice;
    },
    [quotes, invoices, profile, clients]
  );

  async function upsertClientInternal(
    clientList: Client[],
    name: string,
    email: string,
    persist: (next: Client[]) => Promise<void>
  ): Promise<Client> {
    const existing = clientList.find(
      (c) => c.email.toLowerCase() === email.toLowerCase() || c.name.toLowerCase() === name.toLowerCase()
    );
    if (existing) {
      const updated: Client = { ...existing, name, email };
      await persist(clientList.map((c) => (c.id === existing.id ? updated : c)));
      return updated;
    }
    const created: Client = { id: uuid(), name, email, createdAt: new Date().toISOString() };
    await persist([...clientList, created]);
    return created;
  }

  const upsertClient = useCallback(
    async (name: string, email: string) => upsertClientInternal(clients, name, email, persistClients),
    [clients]
  );

  const saveProfile = useCallback(async (next: ProducerProfile) => {
    await AsyncStorage.setItem(STORAGE_KEYS.profile, JSON.stringify(next));
    setProfile(next);
  }, []);

  const saveCatalogItem = useCallback(
    async (item: ServiceCatalogItem) => {
      const next = [...catalog.filter((c) => c.id !== item.id), item];
      await persistCatalog(next);
    },
    [catalog]
  );

  const deleteCatalogItem = useCallback(
    async (id: string) => {
      await persistCatalog(catalog.filter((c) => c.id !== id));
    },
    [catalog]
  );

  const saveContract = useCallback(
    async (contract: ContractTemplate) => {
      if (contract.isBuiltin) return;
      const next = [...contracts.filter((c) => c.id !== contract.id), contract];
      await persistContracts(next);
    },
    [contracts]
  );

  const deleteContract = useCallback(
    async (id: string) => {
      if (DEFAULT_CONTRACTS.some((c) => c.id === id)) return;
      await persistContracts(contracts.filter((c) => c.id !== id));
    },
    [contracts]
  );

  const saveRecurring = useCallback(
    async (item: RecurringInvoice) => {
      const next = [...recurring.filter((r) => r.id !== item.id), item];
      await persistRecurring(next);
    },
    [recurring]
  );

  const deleteRecurring = useCallback(
    async (id: string) => {
      await persistRecurring(recurring.filter((r) => r.id !== id));
    },
    [recurring]
  );

  const getInvoiceById = useCallback((id: string) => invoices.find((i) => i.id === id), [invoices]);
  const getQuoteById = useCallback((id: string) => quotes.find((q) => q.id === id), [quotes]);

  const value = useMemo(
    () => ({
      invoices,
      quotes,
      clients,
      catalog,
      contracts,
      recurring,
      profile,
      loading,
      refresh,
      saveInvoice,
      updateInvoice,
      deleteInvoice,
      saveQuote,
      updateQuote,
      deleteQuote,
      convertQuoteToInvoice,
      upsertClient,
      saveProfile,
      saveCatalogItem,
      deleteCatalogItem,
      saveContract,
      deleteContract,
      saveRecurring,
      deleteRecurring,
      getInvoiceById,
      getQuoteById,
      invoiceCount: invoices.length,
      quoteCount: quotes.length,
    }),
    [
      invoices,
      quotes,
      clients,
      catalog,
      contracts,
      recurring,
      profile,
      loading,
      refresh,
      saveInvoice,
      updateInvoice,
      deleteInvoice,
      saveQuote,
      updateQuote,
      deleteQuote,
      convertQuoteToInvoice,
      upsertClient,
      saveProfile,
      saveCatalogItem,
      deleteCatalogItem,
      saveContract,
      deleteContract,
      saveRecurring,
      deleteRecurring,
      getInvoiceById,
      getQuoteById,
    ]
  );

  return <AppDataContext.Provider value={value}>{children}</AppDataContext.Provider>;
}

export function useAppData() {
  const ctx = useContext(AppDataContext);
  if (!ctx) throw new Error('useAppData must be used within AppDataProvider');
  return ctx;
}

export function useInvoices() {
  const { invoices, saveInvoice, updateInvoice, deleteInvoice, getInvoiceById, invoiceCount, loading } = useAppData();

  const recentInvoices = useMemo(() => invoices.slice(0, 5), [invoices]);

  const monthlyStats = useMemo(() => {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const thisMonth = invoices.filter((i) => new Date(i.createdAt) >= monthStart);
    const paidThisMonth = thisMonth.filter((i) => effectiveStatus(i) === 'paid');
    const pending = invoices.filter((i) => effectiveStatus(i) !== 'paid');
    return {
      collected: paidThisMonth.reduce((s, i) => s + i.total, 0),
      pending: pending.reduce((s, i) => s + i.total, 0),
      count: thisMonth.length,
    };
  }, [invoices]);

  const allTimeStats = useMemo(() => {
    const paid = invoices.filter((i) => effectiveStatus(i) === 'paid');
    const pending = invoices.filter((i) => effectiveStatus(i) !== 'paid');
    return {
      collected: paid.reduce((s, i) => s + i.total, 0),
      pending: pending.reduce((s, i) => s + i.total, 0),
    };
  }, [invoices]);

  const changeStatus = async (id: string, status: InvoiceStatus) => {
    const patch: Partial<Invoice> = {
      status,
      actions: [
        ...(getInvoiceById(id)?.actions ?? []),
        { type: 'status_changed', date: new Date().toISOString(), note: status },
      ],
    };
    if (status === 'paid') {
      patch.paidAt = new Date().toISOString();
      patch.actions!.push({ type: 'paid', date: new Date().toISOString() });
    } else {
      patch.paidAt = null;
    }
    await updateInvoice(id, patch);
  };

  return {
    invoices,
    recentInvoices,
    monthlyStats,
    allTimeStats,
    invoiceCount,
    loading,
    saveInvoice,
    updateInvoice,
    deleteInvoice,
    getInvoiceById,
    changeStatus,
  };
}

export function useQuotes() {
  const { quotes, saveQuote, updateQuote, deleteQuote, getQuoteById, convertQuoteToInvoice, quoteCount, loading } =
    useAppData();
  const recentQuotes = useMemo(() => quotes.slice(0, 5), [quotes]);
  return {
    quotes,
    recentQuotes,
    quoteCount,
    loading,
    saveQuote,
    updateQuote,
    deleteQuote,
    getQuoteById,
    convertQuoteToInvoice,
  };
}

export function useClients() {
  const { clients, invoices, upsertClient } = useAppData();

  const clientsWithStats = useMemo(
    () =>
      clients.map((client) => {
        const clientInvoices = invoices.filter(
          (i) =>
            i.clientEmail.toLowerCase() === client.email.toLowerCase() ||
            i.clientName.toLowerCase() === client.name.toLowerCase()
        );
        const paid = clientInvoices.filter((i) => effectiveStatus(i) === 'paid');
        return {
          ...client,
          invoiceCount: clientInvoices.length,
          totalCollected: paid.reduce((s, i) => s + i.total, 0),
          invoices: clientInvoices,
        };
      }),
    [clients, invoices]
  );

  return { clients: clientsWithStats, upsertClient, addClient: upsertClient };
}

export function useProfile() {
  const { profile, saveProfile } = useAppData();
  return { profile, saveProfile };
}

export function useCatalog() {
  const { catalog, saveCatalogItem, deleteCatalogItem } = useAppData();
  return { catalog, saveCatalogItem, deleteCatalogItem };
}

export function useContracts() {
  const { contracts, saveContract, deleteContract } = useAppData();
  const allContracts = useMemo(() => {
    const custom = contracts.filter((c) => !c.isBuiltin);
    return [...DEFAULT_CONTRACTS, ...custom];
  }, [contracts]);
  return { contracts: allContracts, customContracts: contracts, saveContract, deleteContract };
}

export function useRecurring() {
  const { recurring, saveRecurring, deleteRecurring } = useAppData();
  return { recurring, saveRecurring, deleteRecurring };
}
