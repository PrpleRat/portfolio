import type { Genre, Role } from '@/constants/theme';

export type SplitType = 'master_only' | 'master_and_publishing';
export type SplitStatus = 'pending' | 'complete';

export interface SplitCollaborator {
  id: string;
  name: string;
  role: Role | string;
  masterShare: number;
  publishingShare: number;
  sacem?: string;
  email?: string;
  signed: boolean;
}

export interface Split {
  id: string;
  ref: string;
  title: string;
  artist?: string;
  genre?: Genre | string;
  isrc?: string;
  createdAt: string;
  splitType: SplitType;
  collaborators: SplitCollaborator[];
  clauses: string[];
  notes?: string;
  status: SplitStatus;
  pdfUri?: string;
}

export interface Collaborator {
  id: string;
  name: string;
  role: Role | string;
  email?: string;
  sacem?: string;
  lastUsedAt: string;
  splitCount: number;
}

export interface UserProfile {
  name: string;
  role: string;
  email: string;
  sacem?: string;
  country: string;
  currency: 'EUR' | 'USD';
}

export interface SplitDraft {
  title: string;
  artist: string;
  genre: string;
  isrc: string;
  createdAt: Date;
  splitType: SplitType;
  collaborators: Omit<SplitCollaborator, 'id' | 'signed'>[];
  clauses: string[];
  notes: string;
}

export const defaultProfile: UserProfile = {
  name: '',
  role: 'Producteur',
  email: '',
  sacem: '',
  country: 'France',
  currency: 'EUR',
};

export function formatDate(iso: string | Date): string {
  const d = typeof iso === 'string' ? new Date(iso) : iso;
  return d.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
  });
}

export function computeTotals(collaborators: Pick<SplitCollaborator, 'masterShare' | 'publishingShare'>[]) {
  return collaborators.reduce(
    (acc, c) => ({
      master: acc.master + c.masterShare,
      publishing: acc.publishing + c.publishingShare,
    }),
    { master: 0, publishing: 0 }
  );
}

export function splitStatusFromCollaborators(collaborators: SplitCollaborator[]): SplitStatus {
  if (collaborators.length === 0) return 'pending';
  return collaborators.every((c) => c.signed) ? 'complete' : 'pending';
}
