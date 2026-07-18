import * as Print from 'expo-print';
import type { Invoice, ProducerProfile, Quote } from '@/types';
import { buildInvoiceHtml, buildQuoteHtml } from './invoiceTemplate';
import { imageUriToBase64 } from './imageToBase64';

async function resolveLogo(profile: ProducerProfile): Promise<string | null> {
  if (!profile.logoUri) return null;
  return imageUriToBase64(profile.logoUri);
}

export async function generatePDF(invoice: Invoice, profile: ProducerProfile): Promise<string> {
  const logo = await resolveLogo(profile);
  const html = buildInvoiceHtml(invoice, profile, logo);
  const { uri } = await Print.printToFileAsync({ html, base64: false });
  return uri;
}

export async function generatePDFPreviewHtml(
  invoice: Invoice,
  profile: ProducerProfile
): Promise<string> {
  const logo = await resolveLogo(profile);
  return buildInvoiceHtml(invoice, profile, logo);
}

export async function generateQuotePDF(quote: Quote, profile: ProducerProfile): Promise<string> {
  const logo = await resolveLogo(profile);
  const html = buildQuoteHtml(quote, profile, logo);
  const { uri } = await Print.printToFileAsync({ html, base64: false });
  return uri;
}

export async function generateQuotePreviewHtml(
  quote: Quote,
  profile: ProducerProfile
): Promise<string> {
  const logo = await resolveLogo(profile);
  return buildQuoteHtml(quote, profile, logo);
}

export async function generateHtmlPdf(html: string): Promise<string> {
  const { uri } = await Print.printToFileAsync({ html, base64: false });
  return uri;
}
