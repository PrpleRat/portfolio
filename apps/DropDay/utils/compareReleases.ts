import type { PostMortem, Release } from '@/types';
import { releaseProgress, streamsWeek1Total, totalActualBudget } from '@/types';

export interface ReleaseComparison {
  streamsVsAverage: number | null;
  budgetVsAverage: number | null;
  completionVsAverage: number | null;
  streamsMessage: string | null;
  budgetMessage: string | null;
  completionMessage: string | null;
}

function average(values: number[]): number | null {
  if (values.length === 0) return null;
  return values.reduce((a, b) => a + b, 0) / values.length;
}

export function compareReleaseToHistory(
  release: Release,
  allReleases: Release[]
): ReleaseComparison {
  const completed = allReleases.filter(
    (r) => r.id !== release.id && r.postMortem?.filledAt
  );

  if (completed.length < 1) {
    return {
      streamsVsAverage: null,
      budgetVsAverage: null,
      completionVsAverage: null,
      streamsMessage: null,
      budgetMessage: null,
      completionMessage: null,
    };
  }

  const pm = release.postMortem;
  const avgStreams = average(
    completed.map((r) => streamsWeek1Total(r.postMortem!))
  );
  const avgBudget = average(completed.map((r) => totalActualBudget(r)));
  const avgCompletion = average(completed.map((r) => releaseProgress(r)));

  const currentStreams = pm ? streamsWeek1Total(pm) : 0;
  const currentBudget = totalActualBudget(release);
  const currentCompletion = releaseProgress(release);

  const streamsVsAverage =
    avgStreams && avgStreams > 0 ? currentStreams / avgStreams : null;
  const budgetVsAverage =
    avgBudget && avgBudget > 0 ? currentBudget / avgBudget : null;
  const completionVsAverage =
    avgCompletion && avgCompletion > 0 ? currentCompletion / avgCompletion : null;

  return {
    streamsVsAverage,
    budgetVsAverage,
    completionVsAverage,
    streamsMessage: formatRatioMessage(streamsVsAverage, 'streams', 'stream'),
    budgetMessage: formatBudgetMessage(budgetVsAverage),
    completionMessage: formatRatioMessage(
      completionVsAverage,
      'discipline checklist',
      'discipline'
    ),
  };
}

function formatRatioMessage(
  ratio: number | null,
  label: string,
  shortLabel: string
): string | null {
  if (ratio === null) return null;
  if (ratio >= 1.95) return `Cette release a fait ${Math.round(ratio)}x plus de ${shortLabel} que ta moyenne`;
  if (ratio >= 1.05) return `Cette release a fait ${Math.round((ratio - 1) * 100)}% de plus de ${shortLabel} que ta moyenne`;
  if (ratio <= 0.55) return `Cette release a fait ${Math.round((1 - ratio) * 100)}% moins de ${shortLabel} que ta moyenne`;
  return `Performance ${label} proche de ta moyenne`;
}

function formatBudgetMessage(ratio: number | null): string | null {
  if (ratio === null) return null;
  if (ratio >= 1.2) {
    return `Tu as dépensé ${Math.round((ratio - 1) * 100)}% de plus que d'habitude en promo`;
  }
  if (ratio <= 0.8) {
    return `Tu as dépensé ${Math.round((1 - ratio) * 100)}% de moins que d'habitude en promo`;
  }
  return 'Budget promo proche de ta moyenne';
}

export interface GlobalStats {
  totalReleases: number;
  totalBudget: number;
  avgCompletion: number;
  bestRelease: Release | null;
  worstRelease: Release | null;
  streamsByRelease: { title: string; streams: number }[];
  followersEvolution: { title: string; gained: number }[];
}

export function computeGlobalStats(releases: Release[]): GlobalStats {
  const withPm = releases.filter((r) => r.postMortem?.filledAt);
  const streamsByRelease = withPm.map((r) => ({
    title: r.title,
    streams: streamsWeek1Total(r.postMortem!),
  }));

  const followersEvolution = withPm.map((r) => ({
    title: r.title,
    gained: (r.postMortem!.followersAfter || 0) - (r.postMortem!.followersBefore || 0),
  }));

  let bestRelease: Release | null = null;
  let worstRelease: Release | null = null;
  let bestStreams = -1;
  let worstStreams = Infinity;

  for (const r of withPm) {
    const s = streamsWeek1Total(r.postMortem!);
    if (s > bestStreams) {
      bestStreams = s;
      bestRelease = r;
    }
    if (s < worstStreams) {
      worstStreams = s;
      worstRelease = r;
    }
  }

  return {
    totalReleases: releases.length,
    totalBudget: releases.reduce((sum, r) => sum + totalActualBudget(r), 0),
    avgCompletion:
      releases.length > 0
        ? Math.round(
            releases.reduce((sum, r) => sum + releaseProgress(r), 0) / releases.length
          )
        : 0,
    bestRelease,
    worstRelease,
    streamsByRelease,
    followersEvolution,
  };
}

export function isPostMortemUnlocked(release: Release): boolean {
  const releaseDay = new Date(release.releaseDate);
  releaseDay.setHours(0, 0, 0, 0);
  const unlock = new Date(releaseDay);
  unlock.setDate(unlock.getDate() + 7);
  return new Date() >= unlock;
}

export function daysSinceRelease(release: Release): number {
  const releaseDay = new Date(release.releaseDate);
  releaseDay.setHours(0, 0, 0, 0);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return Math.round((today.getTime() - releaseDay.getTime()) / (1000 * 60 * 60 * 24));
}
