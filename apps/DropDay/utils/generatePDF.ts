import * as Print from 'expo-print';
import type { Release } from '@/types';
import { formatDate, formatMoney, releaseProgress, totalActualBudget, totalEstimatedBudget } from '@/types';
import { getUrgencyLevel } from '@/utils/urgencyLevel';

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function taskStatusLabel(completed: boolean, dueDate: string): string {
  if (completed) return '✅ Fait';
  const level = getUrgencyLevel({ dueDate, completed } as never);
  if (level === 'overdue') return '🔴 En retard';
  if (level === 'urgent') return '🟠 Urgent';
  return '⬜ À faire';
}

export function buildTeamPdfHtml(release: Release, currency: 'EUR' | 'USD'): string {
  const tasksHtml = release.tasks
    .sort((a, b) => new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime())
    .map(
      (t) => `
      <tr>
        <td>${escapeHtml(formatDate(t.dueDate))}</td>
        <td>${escapeHtml(t.title)}</td>
        <td>${taskStatusLabel(t.completed, t.dueDate)}</td>
        <td>${escapeHtml(t.assignedTo ?? '—')}</td>
        <td>${t.estimatedCost ? formatMoney(t.estimatedCost, currency) : '—'}</td>
      </tr>`
    )
    .join('');

  const teamHtml =
    release.team.length > 0
      ? release.team
          .map(
            (m) =>
              `<li><strong>${escapeHtml(m.role)}</strong> — ${escapeHtml(m.name)} (${escapeHtml(m.email)})</li>`
          )
          .join('')
      : '<li>Aucun contact enregistré</li>';

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <style>
    body { font-family: -apple-system, sans-serif; color: #111; padding: 24px; }
    h1 { color: #6366f1; margin-bottom: 4px; }
    h2 { color: #333; border-bottom: 2px solid #6366f1; padding-bottom: 4px; margin-top: 24px; }
    table { width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 13px; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background: #6366f1; color: white; }
    .meta { color: #666; font-size: 14px; }
    ul { line-height: 1.8; }
    .summary { background: #f5f5f5; padding: 12px; border-radius: 8px; margin-top: 12px; }
  </style>
</head>
<body>
  <h1>DropDay — ${escapeHtml(release.title)}</h1>
  <p class="meta">Sortie : ${escapeHtml(formatDate(release.releaseDate))} · Progression : ${releaseProgress(release)}%</p>

  <h2>Timeline</h2>
  <table>
    <thead>
      <tr><th>Date</th><th>Tâche</th><th>Statut</th><th>Responsable</th><th>Budget</th></tr>
    </thead>
    <tbody>${tasksHtml}</tbody>
  </table>

  <div class="summary">
    <strong>Budget prévu :</strong> ${formatMoney(totalEstimatedBudget(release), currency)}<br/>
    <strong>Budget réel :</strong> ${formatMoney(totalActualBudget(release), currency)}
  </div>

  <h2>Équipe</h2>
  <ul>${teamHtml}</ul>

  <p style="margin-top:32px;color:#888;font-size:11px;">Généré par DropDay · 100% offline</p>
</body>
</html>`;
}

export async function generateTeamPDF(release: Release, currency: 'EUR' | 'USD'): Promise<string> {
  const html = buildTeamPdfHtml(release, currency);
  const { uri } = await Print.printToFileAsync({ html, base64: false });
  return uri;
}
