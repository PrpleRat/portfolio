import type { Client, Invoice, Quote, SearchResult } from '@/types';

export function globalSearch(
  query: string,
  invoices: Invoice[],
  quotes: Quote[],
  clients: Client[]
): SearchResult[] {
  const q = query.trim().toLowerCase();
  if (!q) return [];

  const results: SearchResult[] = [];

  for (const inv of invoices) {
    if (
      inv.clientName.toLowerCase().includes(q) ||
      inv.number.toLowerCase().includes(q) ||
      inv.clientEmail.toLowerCase().includes(q) ||
      (inv.project?.toLowerCase().includes(q) ?? false)
    ) {
      results.push({
        type: 'invoice',
        id: inv.id,
        title: inv.number,
        subtitle: `${inv.clientName} · Facture`,
        amount: inv.total,
        currency: inv.currency,
      });
    }
  }

  for (const quote of quotes) {
    if (
      quote.clientName.toLowerCase().includes(q) ||
      quote.number.toLowerCase().includes(q) ||
      quote.clientEmail.toLowerCase().includes(q) ||
      (quote.project?.toLowerCase().includes(q) ?? false)
    ) {
      results.push({
        type: 'quote',
        id: quote.id,
        title: quote.number,
        subtitle: `${quote.clientName} · Devis`,
        amount: quote.total,
        currency: quote.currency,
      });
    }
  }

  for (const client of clients) {
    if (client.name.toLowerCase().includes(q) || client.email.toLowerCase().includes(q)) {
      results.push({
        type: 'client',
        id: client.id,
        title: client.name,
        subtitle: client.email,
      });
    }
  }

  return results.slice(0, 40);
}
