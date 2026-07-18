import { DEFAULT_CONTRACTS } from '@/utils/defaultContracts';
import type { ContractTemplate } from '@/types';

export function getAllContracts(stored: ContractTemplate[]): ContractTemplate[] {
  const custom = stored.filter((c) => !c.isBuiltin);
  return [...DEFAULT_CONTRACTS, ...custom];
}

export function fillContractBody(body: string, vars: Record<string, string>): string {
  let result = body;
  for (const [key, value] of Object.entries(vars)) {
    result = result.replace(new RegExp(`\\{\\{${key}\\}\\}`, 'g'), value);
  }
  return result;
}

export function buildContractHtml(title: string, body: string, profileName: string): string {
  const paragraphs = body.split('\n').map((p) => `<p>${escapeHtml(p)}</p>`).join('');
  return `<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8"/>
<style>
  body { font-family: -apple-system, Helvetica, Arial, sans-serif; padding: 40px; color: #111; line-height: 1.6; font-size: 13px; }
  h1 { font-size: 22px; margin-bottom: 24px; }
  p { margin-bottom: 12px; }
  .footer { margin-top: 40px; font-size: 11px; color: #888; border-top: 1px solid #ddd; padding-top: 16px; }
</style></head>
<body>
  <h1>${escapeHtml(title)}</h1>
  ${paragraphs}
  <div class="footer">Document généré via BeatBill · ${escapeHtml(profileName)}</div>
</body></html>`;
}

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
