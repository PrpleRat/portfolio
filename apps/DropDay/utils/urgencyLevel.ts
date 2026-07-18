import type { Task } from '@/types';

export type UrgencyLevel = 'overdue' | 'urgent' | 'soon' | 'ok' | 'future' | 'done';

export function getDaysUntilDue(task: Task): number {
  const due = new Date(task.dueDate);
  due.setHours(0, 0, 0, 0);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return Math.round((due.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
}

export function getUrgencyLevel(task: Task): UrgencyLevel {
  if (task.completed) return 'done';
  const days = getDaysUntilDue(task);
  if (days < 0) return 'overdue';
  if (days <= 3) return 'urgent';
  if (days <= 7) return 'soon';
  if (days <= 14) return 'ok';
  return 'future';
}

export function urgencyColor(level: UrgencyLevel): string {
  switch (level) {
    case 'overdue':
      return '#ef4444';
    case 'urgent':
      return '#f97316';
    case 'soon':
      return '#eab308';
    case 'done':
      return '#22c55e';
    case 'ok':
      return '#6366f1';
    default:
      return '#374151';
  }
}

export function urgencyLabel(task: Task): string {
  const level = getUrgencyLevel(task);
  const days = getDaysUntilDue(task);
  if (level === 'done') return 'FAIT';
  if (level === 'overdue') return `En retard de ${Math.abs(days)}j`;
  if (days === 0) return "AUJOURD'HUI";
  if (days === 1) return 'Demain';
  return `Dans ${days}j`;
}

export type TimelineSection = 'today' | 'this_week' | 'next_week' | 'later';

export function getTimelineSection(task: Task): TimelineSection {
  if (task.completed) return 'later';
  const days = getDaysUntilDue(task);
  if (days <= 0) return 'today';
  if (days <= 7) return 'this_week';
  if (days <= 14) return 'next_week';
  return 'later';
}

export const SECTION_LABELS: Record<TimelineSection, string> = {
  today: "AUJOURD'HUI",
  this_week: 'CETTE SEMAINE',
  next_week: 'SEMAINE PROCHAINE',
  later: 'DANS 3+ SEMAINES',
};
