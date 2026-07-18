import * as Print from 'expo-print';
import type { Split } from '@/types';
import { buildSplitHtml } from './splitTemplate';

export async function generatePDF(split: Split): Promise<string> {
  const html = buildSplitHtml(split);
  const { uri } = await Print.printToFileAsync({ html, base64: false });
  return uri;
}

export async function generatePDFPreviewHtml(split: Split): Promise<string> {
  return buildSplitHtml(split);
}
