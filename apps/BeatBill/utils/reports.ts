import type { CurrencyCode } from '@/constants/theme';
import type { Invoice } from '@/types';
import { effectiveStatus } from '@/types';

export interface PeriodReport {
  year: number;
  month?: number;
  label: string;
  invoiceCount: number;
  paidCount: number;
  pendingCount: number;
  byCurrency: Record<
    CurrencyCode,
    { collected: number; pending: number; total: number }
  >;
}

function emptyCurrencyMap(): PeriodReport['byCurrency'] {
  return { EUR: { collected: 0, pending: 0, total: 0 }, USD: { collected: 0, pending: 0, total: 0 }, GBP: { collected: 0, pending: 0, total: 0 }, CHF: { collected: 0, pending: 0, total: 0 } };
}

export function computePeriodReport(
  invoices: Invoice[],
  year: number,
  month?: number
): PeriodReport {
  const filtered = invoices.filter((inv) => {
    const d = new Date(inv.createdAt);
    if (d.getFullYear() !== year) return false;
    if (month !== undefined && d.getMonth() !== month) return false;
    return true;
  });

  const byCurrency = emptyCurrencyMap();
  let paidCount = 0;
  let pendingCount = 0;

  for (const inv of filtered) {
    const cur = inv.currency;
    if (!byCurrency[cur]) continue;
    byCurrency[cur].total += inv.total;
    if (effectiveStatus(inv) === 'paid') {
      byCurrency[cur].collected += inv.total;
      paidCount++;
    } else {
      byCurrency[cur].pending += inv.total;
      pendingCount++;
    }
  }

  const label =
    month !== undefined
      ? new Date(year, month, 1).toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' })
      : String(year);

  return {
    year,
    month,
    label,
    invoiceCount: filtered.length,
    paidCount,
    pendingCount,
    byCurrency,
  };
}

export function computeYearlyBreakdown(invoices: Invoice[], year: number): PeriodReport[] {
  return Array.from({ length: 12 }, (_, m) => computePeriodReport(invoices, year, m));
}
