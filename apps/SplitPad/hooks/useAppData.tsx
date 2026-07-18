import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { STORAGE_KEYS } from '@/constants/theme';
import {
  type Collaborator,
  type Split,
  type SplitCollaborator,
  type UserProfile,
  defaultProfile,
  splitStatusFromCollaborators,
} from '@/types';
import { uuid } from '@/utils/uuid';

interface AppDataContextValue {
  splits: Split[];
  collaborators: Collaborator[];
  profile: UserProfile;
  loading: boolean;
  refresh: () => Promise<void>;
  saveSplit: (split: Split) => Promise<void>;
  updateSplit: (id: string, patch: Partial<Split>) => Promise<void>;
  deleteSplit: (id: string) => Promise<void>;
  getSplitById: (id: string) => Split | undefined;
  upsertCollaboratorFromSplit: (collab: SplitCollaborator) => Promise<void>;
  saveCollaborator: (collaborator: Collaborator) => Promise<void>;
  deleteCollaborator: (id: string) => Promise<void>;
  saveProfile: (profile: UserProfile) => Promise<void>;
  splitCount: number;
}

const AppDataContext = createContext<AppDataContextValue | null>(null);

async function readJson<T>(key: string, fallback: T): Promise<T> {
  const raw = await AsyncStorage.getItem(key);
  if (!raw) return fallback;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

export function AppDataProvider({ children }: { children: ReactNode }) {
  const [splits, setSplits] = useState<Split[]>([]);
  const [collaborators, setCollaborators] = useState<Collaborator[]>([]);
  const [profile, setProfile] = useState<UserProfile>(defaultProfile);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    const [spl, collab, prof] = await Promise.all([
      readJson<Split[]>(STORAGE_KEYS.splits, []),
      readJson<Collaborator[]>(STORAGE_KEYS.collaborators, []),
      readJson<UserProfile>(STORAGE_KEYS.profile, defaultProfile),
    ]);
    setSplits(
      spl.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
    );
    setCollaborators(
      collab.sort((a, b) => new Date(b.lastUsedAt).getTime() - new Date(a.lastUsedAt).getTime())
    );
    setProfile(prof);
    setLoading(false);
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const persistSplits = async (next: Split[]) => {
    const sorted = next.sort(
      (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
    await AsyncStorage.setItem(STORAGE_KEYS.splits, JSON.stringify(sorted));
    setSplits(sorted);
  };

  const persistCollaborators = async (next: Collaborator[]) => {
    const sorted = next.sort(
      (a, b) => new Date(b.lastUsedAt).getTime() - new Date(a.lastUsedAt).getTime()
    );
    await AsyncStorage.setItem(STORAGE_KEYS.collaborators, JSON.stringify(sorted));
    setCollaborators(sorted);
  };

  const saveSplit = useCallback(
    async (split: Split) => {
      const next = [...splits.filter((s) => s.id !== split.id), split];
      await persistSplits(next);

      let currentCollabs = await readJson<Collaborator[]>(STORAGE_KEYS.collaborators, []);
      for (const c of split.collaborators) {
        currentCollabs = upsertCollaboratorInList(currentCollabs, c);
      }
      await persistCollaborators(currentCollabs);
    },
    [splits]
  );

  const updateSplit = useCallback(
    async (id: string, patch: Partial<Split>) => {
      const next = splits.map((s) => {
        if (s.id !== id) return s;
        const updated = { ...s, ...patch };
        if (patch.collaborators) {
          updated.status = splitStatusFromCollaborators(updated.collaborators);
        }
        return updated;
      });
      await persistSplits(next);
    },
    [splits]
  );

  const deleteSplit = useCallback(
    async (id: string) => {
      const next = splits.filter((s) => s.id !== id);
      await persistSplits(next);
    },
    [splits]
  );

  const getSplitById = useCallback((id: string) => splits.find((s) => s.id === id), [splits]);

  const upsertCollaboratorFromSplit = useCallback(async (collab: SplitCollaborator) => {
    const current = await readJson<Collaborator[]>(STORAGE_KEYS.collaborators, []);
    await persistCollaborators(upsertCollaboratorInList(current, collab));
  }, []);

  const saveCollaborator = useCallback(
    async (collaborator: Collaborator) => {
      const existing = collaborators.find((c) => c.id === collaborator.id);
      const next = existing
        ? collaborators.map((c) => (c.id === collaborator.id ? collaborator : c))
        : [...collaborators, collaborator];
      await persistCollaborators(next);
    },
    [collaborators]
  );

  const deleteCollaborator = useCallback(
    async (id: string) => {
      const next = collaborators.filter((c) => c.id !== id);
      await persistCollaborators(next);
    },
    [collaborators]
  );

  const saveProfile = useCallback(async (next: UserProfile) => {
    await AsyncStorage.setItem(STORAGE_KEYS.profile, JSON.stringify(next));
    setProfile(next);
  }, []);

  const value = useMemo(
    () => ({
      splits,
      collaborators,
      profile,
      loading,
      refresh,
      saveSplit,
      updateSplit,
      deleteSplit,
      getSplitById,
      upsertCollaboratorFromSplit,
      saveCollaborator,
      deleteCollaborator,
      saveProfile,
      splitCount: splits.length,
    }),
    [
      splits,
      collaborators,
      profile,
      loading,
      refresh,
      saveSplit,
      updateSplit,
      deleteSplit,
      getSplitById,
      upsertCollaboratorFromSplit,
      saveCollaborator,
      deleteCollaborator,
      saveProfile,
    ]
  );

  return <AppDataContext.Provider value={value}>{children}</AppDataContext.Provider>;
}

function upsertCollaboratorInList(collaborators: Collaborator[], collab: SplitCollaborator): Collaborator[] {
  const nameKey = collab.name.trim().toLowerCase();
  if (!nameKey) return collaborators;

  const existing = collaborators.find((c) => c.name.toLowerCase() === nameKey);
  const now = new Date().toISOString();

  if (existing) {
    const updated: Collaborator = {
      ...existing,
      name: collab.name.trim(),
      role: collab.role,
      email: collab.email || existing.email,
      sacem: collab.sacem || existing.sacem,
      lastUsedAt: now,
      splitCount: existing.splitCount + 1,
    };
    return collaborators.map((c) => (c.id === existing.id ? updated : c));
  }

  const created: Collaborator = {
    id: uuid(),
    name: collab.name.trim(),
    role: collab.role,
    email: collab.email,
    sacem: collab.sacem,
    lastUsedAt: now,
    splitCount: 1,
  };
  return [...collaborators, created];
}

export function useAppData() {
  const ctx = useContext(AppDataContext);
  if (!ctx) throw new Error('useAppData must be used within AppDataProvider');
  return ctx;
}

export function useSplits() {
  const {
    splits,
    saveSplit,
    updateSplit,
    deleteSplit,
    getSplitById,
    splitCount,
    loading,
  } = useAppData();

  const recentSplits = useMemo(() => splits.slice(0, 5), [splits]);

  const toggleSignature = async (splitId: string, collaboratorId: string, signed: boolean) => {
    const split = getSplitById(splitId);
    if (!split) return;
    const collaborators = split.collaborators.map((c) =>
      c.id === collaboratorId ? { ...c, signed } : c
    );
    await updateSplit(splitId, {
      collaborators,
      status: splitStatusFromCollaborators(collaborators),
    });
  };

  return {
    splits,
    recentSplits,
    splitCount,
    loading,
    saveSplit,
    updateSplit,
    deleteSplit,
    getSplitById,
    toggleSignature,
  };
}

export function useCollaborators() {
  const { collaborators, saveCollaborator, deleteCollaborator, splits } = useAppData();

  const frequentCollaborators = useMemo(() => collaborators.slice(0, 5), [collaborators]);

  const collaboratorsWithStats = useMemo(
    () =>
      collaborators.map((c) => ({
        ...c,
        sharedSplits: splits.filter((s) =>
          s.collaborators.some((col) => col.name.toLowerCase() === c.name.toLowerCase())
        ).length,
      })),
    [collaborators, splits]
  );

  return {
    collaborators: collaboratorsWithStats,
    frequentCollaborators,
    saveCollaborator,
    deleteCollaborator,
  };
}

export function useProfile() {
  const { profile, saveProfile } = useAppData();
  return { profile, saveProfile };
}
