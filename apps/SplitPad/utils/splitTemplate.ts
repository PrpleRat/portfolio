import type { Split } from '@/types';
import { formatDate } from '@/types';

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

export function buildSplitHtml(split: Split): string {
  const showPublishing = split.splitType === 'master_and_publishing';

  const rows = split.collaborators
    .map(
      (c) => `
      <tr>
        <td>${escapeHtml(c.name)}</td>
        <td>${escapeHtml(c.role)}</td>
        <td style="text-align:center">${c.masterShare}%</td>
        ${showPublishing ? `<td style="text-align:center">${c.publishingShare}%</td>` : ''}
      </tr>`
    )
    .join('');

  const totalMaster = split.collaborators.reduce((s, c) => s + c.masterShare, 0);
  const totalPublishing = split.collaborators.reduce((s, c) => s + c.publishingShare, 0);

  const sacemLines = split.collaborators
    .filter((c) => c.sacem?.trim())
    .map((c) => `<div>${escapeHtml(c.name)} — SACEM n° ${escapeHtml(c.sacem!)}</div>`)
    .join('');

  const clausesBlock =
    [...split.clauses, split.notes?.trim()].filter(Boolean).join('\n') ||
    'Aucune clause additionnelle.';

  const signatureBlocks = split.collaborators
    .map(
      (c) => `
      <div class="signature-line">
        <strong>${escapeHtml(c.name)}</strong>
        <span class="sig-field">_________________________</span>
        <span>Date : __________</span>
      </div>`
    )
    .join('');

  return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, Helvetica, Arial, sans-serif; color: #111; padding: 40px; font-size: 12px; line-height: 1.5; background: #fff; }
    h1 { text-align: center; font-size: 18px; letter-spacing: 1px; margin-bottom: 24px; text-transform: uppercase; }
    .section { margin-bottom: 20px; padding-bottom: 16px; border-bottom: 1px solid #ccc; }
    .section h2 { font-size: 11px; text-transform: uppercase; color: #444; margin-bottom: 10px; letter-spacing: 0.5px; }
    .meta div { margin-bottom: 4px; }
    table { width: 100%; border-collapse: collapse; margin-top: 8px; }
    th { background: #f0f0f0; text-align: left; padding: 8px; font-size: 10px; text-transform: uppercase; border: 1px solid #ccc; }
    td { padding: 8px; border: 1px solid #ddd; }
    .total-row td { font-weight: 700; background: #fafafa; }
    .clauses { white-space: pre-wrap; color: #333; }
    .signature-line { margin-bottom: 28px; display: flex; flex-wrap: wrap; gap: 12px; align-items: baseline; }
    .sig-field { flex: 1; min-width: 200px; border-bottom: 1px solid #333; }
    .footer { margin-top: 32px; padding-top: 12px; border-top: 1px solid #ccc; text-align: center; color: #666; font-size: 10px; }
  </style>
</head>
<body>
  <h1>Split Sheet — Accord de propriété</h1>

  <div class="section">
    <h2>Morceau</h2>
    <div class="meta">
      <div><strong>MORCEAU :</strong> "${escapeHtml(split.title)}"</div>
      ${split.artist ? `<div><strong>Artiste principal :</strong> ${escapeHtml(split.artist)}</div>` : ''}
      ${split.genre ? `<div><strong>Genre :</strong> ${escapeHtml(split.genre)}</div>` : ''}
      <div><strong>Date de création :</strong> ${formatDate(split.createdAt)}</div>
      <div><strong>ISRC :</strong> ${split.isrc?.trim() ? escapeHtml(split.isrc) : 'À obtenir'}</div>
      <div><strong>Référence :</strong> ${escapeHtml(split.ref)}</div>
    </div>
  </div>

  <div class="section">
    <h2>Répartition des droits</h2>
    <table>
      <thead>
        <tr>
          <th>Collaborateur</th>
          <th>Rôle</th>
          <th style="text-align:center">Master</th>
          ${showPublishing ? '<th style="text-align:center">Publishing</th>' : ''}
        </tr>
      </thead>
      <tbody>
        ${rows}
        <tr class="total-row">
          <td colspan="2"><strong>TOTAL</strong></td>
          <td style="text-align:center">${totalMaster}%</td>
          ${showPublishing ? `<td style="text-align:center">${totalPublishing}%</td>` : ''}
        </tr>
      </tbody>
    </table>
  </div>

  ${
    sacemLines
      ? `<div class="section"><h2>Informations PRO / SACEM</h2>${sacemLines}</div>`
      : ''
  }

  <div class="section">
    <h2>Clauses</h2>
    <div class="clauses">${escapeHtml(clausesBlock)}</div>
  </div>

  <div class="section">
    <h2>Signatures</h2>
    ${signatureBlocks}
  </div>

  <div class="footer">
    Généré via SplitPad · Ref : ${escapeHtml(split.ref)}<br/>
    Ce document est un accord entre les parties signataires.
  </div>
</body>
</html>`;
}
