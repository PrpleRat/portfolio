import templates from '@/data/templates.json';
import type { ArtistLevel, ReleaseFormat, Task, TemplateDefinition } from '@/types';
import { uuid } from '@/utils/uuid';

const allTemplates = templates as TemplateDefinition[];

export function findTemplate(format: ReleaseFormat, level: ArtistLevel): TemplateDefinition | undefined {
  return allTemplates.find((t) => t.format === format && t.level === level);
}

export function generateTasksFromTemplate(
  format: ReleaseFormat,
  level: ArtistLevel,
  releaseDate: Date,
  costOverrides?: Record<string, number>
): Task[] {
  const template = findTemplate(format, level);
  if (!template) {
    const fallback = allTemplates.find((t) => t.format === format);
    if (!fallback) return [];
    return buildTasks(fallback, releaseDate, costOverrides);
  }
  return buildTasks(template, releaseDate, costOverrides);
}

function buildTasks(
  template: TemplateDefinition,
  releaseDate: Date,
  costOverrides?: Record<string, number>
): Task[] {
  const release = new Date(releaseDate);
  release.setHours(0, 0, 0, 0);

  return template.steps.map((step) => {
    const due = new Date(release);
    due.setDate(due.getDate() + step.daysOffset);
    const estimatedCost = costOverrides?.[step.title] ?? step.defaultCost ?? 0;

    return {
      id: uuid(),
      title: step.title,
      description: step.description,
      dueDate: due.toISOString(),
      completed: false,
      completedAt: null,
      assignedTo: null,
      estimatedCost,
      actualCost: null,
      category: step.category,
      daysOffset: step.daysOffset,
    };
  });
}

export function getTemplateWeeks(format: ReleaseFormat, level: ArtistLevel): number {
  const template = findTemplate(format, level);
  return template?.weeks ?? 8;
}

export { allTemplates };
