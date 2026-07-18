import type { Invoice, ProducerProfile, Quote } from '@/types';
import { formatDate, formatMoney } from '@/types';
import { buildLegalFooter } from '@/utils/legalMentions';

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function itemsTableHtml(
  items: { description: string; qty: number; unitPrice: number; total: number }[],
  currency: Invoice['currency']
) {
  return items
    .map(
      (item) => `
      <tr>
        <td>${escapeHtml(item.description)}</td>
        <td style="text-align:center">${item.qty}</td>
        <td style="text-align:right">${formatMoney(item.unitPrice, currency)}</td>
        <td style="text-align:right">${formatMoney(item.total, currency)}</td>
      </tr>`
    )
    .join('');
}

function totalsHtml(subtotal: number, vatRate: number, vatAmount: number, total: number, currency: Invoice['currency']) {
  return `
  <table class="totals">
    <tr><td>Sous-total</td><td style="text-align:right">${formatMoney(subtotal, currency)}</td></tr>
    <tr><td>TVA (${vatRate}%)</td><td style="text-align:right">${formatMoney(vatAmount, currency)}</td></tr>
    <tr><td>TOTAL TTC</td><td style="text-align:right">${formatMoney(total, currency)}</td></tr>
  </table>`;
}

function baseStyles() {
  return `
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, Helvetica, Arial, sans-serif; color: #111; padding: 40px; font-size: 13px; line-height: 1.5; }
    .header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 32px; }
    .title { font-size: 28px; font-weight: 700; letter-spacing: 1px; }
    .logo { max-height: 64px; max-width: 180px; margin-bottom: 8px; }
    .meta { text-align: right; color: #333; }
    .meta div { margin-bottom: 4px; }
    .parties { display: flex; justify-content: space-between; margin-bottom: 24px; padding: 16px 0; border-top: 1px solid #ddd; border-bottom: 1px solid #ddd; }
    .party h3 { font-size: 11px; text-transform: uppercase; color: #666; margin-bottom: 8px; letter-spacing: 0.5px; }
    .project { margin-bottom: 20px; font-style: italic; color: #444; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
    th { background: #f5f5f5; text-align: left; padding: 10px 8px; font-size: 11px; text-transform: uppercase; border-bottom: 2px solid #333; }
    td { padding: 10px 8px; border-bottom: 1px solid #eee; vertical-align: top; }
    .totals { width: 280px; margin-left: auto; }
    .totals tr td { border: none; padding: 6px 8px; }
    .totals tr:last-child td { font-weight: 700; font-size: 16px; border-top: 2px solid #333; padding-top: 10px; }
    .payment { margin-top: 32px; padding-top: 16px; border-top: 1px solid #ddd; }
    .payment h3 { font-size: 11px; text-transform: uppercase; color: #666; margin-bottom: 8px; }
    .notes { margin-top: 16px; color: #555; font-size: 12px; }
    .legal { margin-top: 24px; padding: 12px; background: #fafafa; border: 1px solid #eee; font-size: 10px; color: #555; line-height: 1.5; white-space: pre-line; }
    .footer { margin-top: 24px; padding-top: 16px; border-top: 1px solid #ddd; text-align: center; color: #999; font-size: 11px; }
  `;
}

function senderBlock(profile: ProducerProfile) {
  return `
    <div><strong>${escapeHtml(profile.name || 'Producteur')}</strong></div>
    <div>${escapeHtml(profile.email)}</div>
    ${profile.phone ? `<div>${escapeHtml(profile.phone)}</div>` : ''}
    ${profile.siret ? `<div>SIRET : ${escapeHtml(profile.siret)}</div>` : ''}
    ${profile.vatNumber ? `<div>N° TVA : ${escapeHtml(profile.vatNumber)}</div>` : ''}
    ${profile.address ? `<div>${escapeHtml(profile.address)}</div>` : ''}
    <div>${escapeHtml(profile.country)}</div>`;
}

export function buildInvoiceHtml(
  invoice: Invoice,
  profile: ProducerProfile,
  logoDataUri?: string | null
): string {
  const paymentDetail =
    profile.paymentMode === 'Virement (IBAN)'
      ? `${escapeHtml(invoice.paymentRef)}${profile.bic ? `<br/>BIC : ${escapeHtml(profile.bic)}` : ''}`
      : escapeHtml(invoice.paymentRef);

  const logoBlock = logoDataUri ? `<img class="logo" src="${logoDataUri}" alt="Logo" />` : '';

  return `<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8" /><style>${baseStyles()}</style></head>
<body>
  <div class="header">
    <div>${logoBlock}<div class="title">FACTURE</div></div>
    <div class="meta">
      <div><strong>N° ${escapeHtml(invoice.number)}</strong></div>
      <div>Date : ${formatDate(invoice.createdAt)}</div>
      <div>Échéance : ${formatDate(invoice.dueDate)}</div>
    </div>
  </div>
  <div class="parties">
    <div class="party"><h3>De</h3>${senderBlock(profile)}</div>
    <div class="party"><h3>Pour</h3>
      <div><strong>${escapeHtml(invoice.clientName)}</strong></div>
      <div>${escapeHtml(invoice.clientEmail)}</div>
    </div>
  </div>
  ${invoice.project ? `<div class="project">Projet : ${escapeHtml(invoice.project)}</div>` : ''}
  <table><thead><tr>
    <th style="width:45%">Description</th><th style="width:10%;text-align:center">Qté</th>
    <th style="width:22%;text-align:right">Prix U.</th><th style="width:23%;text-align:right">Total</th>
  </tr></thead><tbody>${itemsTableHtml(invoice.items, invoice.currency)}</tbody></table>
  ${totalsHtml(invoice.subtotal, invoice.vatRate, invoice.vatAmount, invoice.total, invoice.currency)}
  <div class="payment"><h3>Paiement</h3><div>Mode : ${escapeHtml(invoice.paymentMode)}</div><div>${paymentDetail}</div></div>
  ${invoice.notes ? `<div class="notes">${escapeHtml(invoice.notes)}</div>` : ''}
  <div class="legal">${escapeHtml(buildLegalFooter(profile))}</div>
  <div class="footer">Facture générée via BeatBill · N° ${escapeHtml(invoice.number)}</div>
</body></html>`;
}

export function buildQuoteHtml(
  quote: Quote,
  profile: ProducerProfile,
  logoDataUri?: string | null
): string {
  const logoBlock = logoDataUri ? `<img class="logo" src="${logoDataUri}" alt="Logo" />` : '';

  return `<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8" /><style>${baseStyles()}</style></head>
<body>
  <div class="header">
    <div>${logoBlock}<div class="title">DEVIS</div></div>
    <div class="meta">
      <div><strong>N° ${escapeHtml(quote.number)}</strong></div>
      <div>Date : ${formatDate(quote.createdAt)}</div>
      <div>Valable jusqu'au : ${formatDate(quote.expiresAt)}</div>
    </div>
  </div>
  <div class="parties">
    <div class="party"><h3>De</h3>${senderBlock(profile)}</div>
    <div class="party"><h3>Pour</h3>
      <div><strong>${escapeHtml(quote.clientName)}</strong></div>
      <div>${escapeHtml(quote.clientEmail)}</div>
    </div>
  </div>
  ${quote.project ? `<div class="project">Projet : ${escapeHtml(quote.project)}</div>` : ''}
  <table><thead><tr>
    <th style="width:45%">Description</th><th style="width:10%;text-align:center">Qté</th>
    <th style="width:22%;text-align:right">Prix U.</th><th style="width:23%;text-align:right">Total</th>
  </tr></thead><tbody>${itemsTableHtml(quote.items, quote.currency)}</tbody></table>
  ${totalsHtml(quote.subtotal, quote.vatRate, quote.vatAmount, quote.total, quote.currency)}
  ${quote.notes ? `<div class="notes">${escapeHtml(quote.notes)}</div>` : ''}
  <div class="legal">Devis valable ${quote.validityDays} jours. ${escapeHtml(buildLegalFooter(profile))}</div>
  <div class="footer">Devis généré via BeatBill · N° ${escapeHtml(quote.number)}</div>
</body></html>`;
}
