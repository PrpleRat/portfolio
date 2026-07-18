export type ReleaseFormat = 'single' | 'double_single' | 'ep' | 'album' | 'clip';
export type ArtistLevel = 'beginner' | 'intermediate' | 'advanced';
export type ReleaseStatus = 'in_progress' | 'released' | 'completed';

export interface Task {
  id: string;
  title: string;
  description: string;
  dueDate: string;
  completed: boolean;
  completedAt: string | null;
  assignedTo: string | null;
  estimatedCost: number;
  actualCost: number | null;
  category: string;
  daysOffset: number;
}

export interface TeamMember {
  role: string;
  name: string;
  email: string;
}

export interface PostMortem {
  streamsWeek1Spotify: number;
  streamsWeek1Apple: number;
  streamsMonth1Spotify: number;
  streamsMonth1Apple: number;
  playlistsObtained: number;
  mediasCovered: number;
  followersBefore: number;
  followersAfter: number;
  totalBudgetSpent: number;
  whatWorked: string;
  whatDidnt: string;
  nextTime: string;
  rating: number;
  filledAt: string | null;
}

export interface Release {
  id: string;
  title: string;
  format: ReleaseFormat;
  level: ArtistLevel;
  releaseDate: string;
  createdAt: string;
  status: ReleaseStatus;
  tasks: Task[];
  team: TeamMember[];
  postMortem: PostMortem | null;
  artworkColor?: string;
}

export interface ArtistProfile {
  name: string;
  genre: string;
  currency: 'EUR' | 'USD';
  notificationsEnabled: boolean;
}

export interface TemplateStep {
  daysOffset: number;
  title: string;
  description: string;
  category: string;
  defaultCost?: number;
}

export interface TemplateDefinition {
  format: ReleaseFormat;
  level: ArtistLevel;
  weeks: number;
  steps: TemplateStep[];
}

export const defaultProfile: ArtistProfile = {
  name: '',
  genre: '',
  currency: 'EUR',
  notificationsEnabled: true,
};

export const emptyPostMortem = (): PostMortem => ({
  streamsWeek1Spotify: 0,
  streamsWeek1Apple: 0,
  streamsMonth1Spotify: 0,
  streamsMonth1Apple: 0,
  playlistsObtained: 0,
  mediasCovered: 0,
  followersBefore: 0,
  followersAfter: 0,
  totalBudgetSpent: 0,
  whatWorked: '',
  whatDidnt: '',
  nextTime: '',
  rating: 3,
  filledAt: null,
});

export function formatMoney(amount: number, currency: 'EUR' | 'USD' = 'EUR'): string {
  const symbol = currency === 'EUR' ? '€' : '$';
  return `${amount.toFixed(0)} ${symbol}`;
}

export function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}

export function daysUntil(iso: string): number {
  const target = new Date(iso);
  target.setHours(0, 0, 0, 0);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return Math.round((target.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
}

export function releaseProgress(release: Release): number {
  if (release.tasks.length === 0) return 0;
  const done = release.tasks.filter((t) => t.completed).length;
  return Math.round((done / release.tasks.length) * 100);
}

export function getReleaseStatus(release: Release): ReleaseStatus {
  const releaseDay = new Date(release.releaseDate);
  releaseDay.setHours(0, 0, 0, 0);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  if (release.postMortem?.filledAt) return 'completed';
  if (today >= releaseDay) return 'released';
  return 'in_progress';
}

export function totalEstimatedBudget(release: Release): number {
  return release.tasks.reduce((sum, t) => sum + (t.estimatedCost || 0), 0);
}

export function totalActualBudget(release: Release): number {
  return release.tasks.reduce((sum, t) => sum + (t.actualCost ?? 0), 0);
}

export function streamsWeek1Total(pm: PostMortem): number {
  return pm.streamsWeek1Spotify + pm.streamsWeek1Apple;
}

export function streamsMonth1Total(pm: PostMortem): number {
  return pm.streamsMonth1Spotify + pm.streamsMonth1Apple;
}
