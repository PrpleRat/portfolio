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
  type ArtistProfile,
  type PostMortem,
  type Release,
  type ReleaseFormat,
  type ArtistLevel,
  type Task,
  type TeamMember,
  defaultProfile,
  getReleaseStatus,
} from '@/types';
import { uuid } from '@/utils/uuid';
import { generateTasksFromTemplate } from '@/utils/templateEngine';
import { scheduleReleaseNotifications, cancelReleaseNotifications } from '@/hooks/useNotifications';

const ARTWORK_COLORS = ['#6366f1', '#8b5cf6', '#ec4899', '#14b8a6', '#f97316', '#22c55e'];

interface ReleasesContextValue {
  releases: Release[];
  profile: ArtistProfile;
  loading: boolean;
  refresh: () => Promise<void>;
  getRelease: (id: string) => Release | undefined;
  createRelease: (input: CreateReleaseInput) => Promise<Release | null>;
  updateRelease: (id: string, patch: Partial<Release>) => Promise<void>;
  deleteRelease: (id: string) => Promise<void>;
  toggleTask: (releaseId: string, taskId: string) => Promise<void>;
  updateTask: (releaseId: string, taskId: string, patch: Partial<Task>) => Promise<void>;
  postponeTask: (releaseId: string, taskId: string, days: number) => Promise<void>;
  assignTask: (releaseId: string, taskId: string, name: string | null) => Promise<void>;
  addTask: (releaseId: string, task: Omit<Task, 'id'>) => Promise<void>;
  removeTask: (releaseId: string, taskId: string) => Promise<void>;
  savePostMortem: (releaseId: string, data: PostMortem) => Promise<void>;
  saveTeam: (releaseId: string, team: TeamMember[]) => Promise<void>;
  saveProfile: (profile: ArtistProfile) => Promise<void>;
  setTaskActualCost: (releaseId: string, taskId: string, cost: number | null) => Promise<void>;
}

export interface CreateReleaseInput {
  title: string;
  format: ReleaseFormat;
  level: ArtistLevel;
  releaseDate: Date;
  tasks?: Task[];
  costOverrides?: Record<string, number>;
}

const ReleasesContext = createContext<ReleasesContextValue | null>(null);

async function readJson<T>(key: string, fallback: T): Promise<T> {
  const raw = await AsyncStorage.getItem(key);
  if (!raw) return fallback;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

async function persistReleases(releases: Release[]) {
  await AsyncStorage.setItem(STORAGE_KEYS.releases, JSON.stringify(releases));
}

function sortReleases(list: Release[]): Release[] {
  return [...list].sort(
    (a, b) => new Date(a.releaseDate).getTime() - new Date(b.releaseDate).getTime()
  );
}

export function ReleasesProvider({ children }: { children: ReactNode }) {
  const [releases, setReleases] = useState<Release[]>([]);
  const [profile, setProfile] = useState<ArtistProfile>(defaultProfile);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    const [storedReleases, storedProfile] = await Promise.all([
      readJson<Release[]>(STORAGE_KEYS.releases, []),
      readJson<ArtistProfile>(STORAGE_KEYS.profile, defaultProfile),
    ]);
    const normalized = storedReleases.map((r) => ({
      ...r,
      status: getReleaseStatus(r),
      postMortem: r.postMortem ?? null,
      team: r.team ?? [],
    }));
    setReleases(sortReleases(normalized));
    setProfile({ ...defaultProfile, ...storedProfile });
    setLoading(false);
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const getRelease = useCallback(
    (id: string) => releases.find((r) => r.id === id),
    [releases]
  );

  const updateReleaseInState = useCallback(
    async (id: string, updater: (r: Release) => Release) => {
      let updated: Release | undefined;
      const next = releases.map((r) => {
        if (r.id !== id) return r;
        const nextRelease = updater(r);
        updated = { ...nextRelease, status: getReleaseStatus(nextRelease) };
        return updated;
      });
      const sorted = sortReleases(next);
      setReleases(sorted);
      await persistReleases(sorted);
      if (updated) await scheduleReleaseNotifications(updated);
    },
    [releases]
  );

  const createRelease = useCallback(
    async (input: CreateReleaseInput): Promise<Release | null> => {
      const tasks =
        input.tasks ??
        generateTasksFromTemplate(
          input.format,
          input.level,
          input.releaseDate,
          input.costOverrides
        );

      const release: Release = {
        id: uuid(),
        title: input.title.trim(),
        format: input.format,
        level: input.level,
        releaseDate: input.releaseDate.toISOString(),
        createdAt: new Date().toISOString(),
        status: 'in_progress',
        tasks,
        team: [],
        postMortem: null,
        artworkColor: ARTWORK_COLORS[Math.floor(Math.random() * ARTWORK_COLORS.length)],
      };

      const next = sortReleases([...releases, release]);
      setReleases(next);
      await persistReleases(next);
      await scheduleReleaseNotifications(release);
      return release;
    },
    [releases]
  );

  const updateRelease = useCallback(
    async (id: string, patch: Partial<Release>) => {
      let updated: Release | undefined;
      const next = releases.map((r) => {
        if (r.id !== id) return r;
        updated = { ...r, ...patch, status: getReleaseStatus({ ...r, ...patch }) };
        return updated;
      });
      setReleases(sortReleases(next));
      await persistReleases(sortReleases(next));
      if (updated) await scheduleReleaseNotifications(updated);
    },
    [releases]
  );

  const deleteRelease = useCallback(
    async (id: string) => {
      const next = releases.filter((r) => r.id !== id);
      setReleases(next);
      await persistReleases(next);
      await cancelReleaseNotifications(id);
    },
    [releases]
  );

  const toggleTask = useCallback(
    async (releaseId: string, taskId: string) => {
      await updateReleaseInState(releaseId, (r) => ({
        ...r,
        tasks: r.tasks.map((t) =>
          t.id === taskId
            ? {
                ...t,
                completed: !t.completed,
                completedAt: !t.completed ? new Date().toISOString() : null,
              }
            : t
        ),
      }));
    },
    [updateReleaseInState]
  );

  const updateTask = useCallback(
    async (releaseId: string, taskId: string, patch: Partial<Task>) => {
      await updateReleaseInState(releaseId, (r) => ({
        ...r,
        tasks: r.tasks.map((t) => (t.id === taskId ? { ...t, ...patch } : t)),
      }));
    },
    [updateReleaseInState]
  );

  const postponeTask = useCallback(
    async (releaseId: string, taskId: string, days: number) => {
      await updateReleaseInState(releaseId, (r) => ({
        ...r,
        tasks: r.tasks.map((t) => {
          if (t.id !== taskId) return t;
          const due = new Date(t.dueDate);
          due.setDate(due.getDate() + days);
          return { ...t, dueDate: due.toISOString(), daysOffset: t.daysOffset + days };
        }),
      }));
    },
    [updateReleaseInState]
  );

  const assignTask = useCallback(
    async (releaseId: string, taskId: string, name: string | null) => {
      await updateTask(releaseId, taskId, { assignedTo: name });
    },
    [updateTask]
  );

  const addTask = useCallback(
    async (releaseId: string, task: Omit<Task, 'id'>) => {
      await updateReleaseInState(releaseId, (r) => ({
        ...r,
        tasks: [...r.tasks, { ...task, id: uuid() }],
      }));
    },
    [updateReleaseInState]
  );

  const removeTask = useCallback(
    async (releaseId: string, taskId: string) => {
      await updateReleaseInState(releaseId, (r) => ({
        ...r,
        tasks: r.tasks.filter((t) => t.id !== taskId),
      }));
    },
    [updateReleaseInState]
  );

  const savePostMortem = useCallback(
    async (releaseId: string, data: PostMortem) => {
      await updateRelease(releaseId, {
        postMortem: { ...data, filledAt: new Date().toISOString() },
        status: 'completed',
      });
    },
    [updateRelease]
  );

  const saveTeam = useCallback(
    async (releaseId: string, team: TeamMember[]) => {
      await updateRelease(releaseId, { team });
    },
    [updateRelease]
  );

  const saveProfile = useCallback(async (next: ArtistProfile) => {
    setProfile(next);
    await AsyncStorage.setItem(STORAGE_KEYS.profile, JSON.stringify(next));
  }, []);

  const setTaskActualCost = useCallback(
    async (releaseId: string, taskId: string, cost: number | null) => {
      await updateTask(releaseId, taskId, { actualCost: cost });
    },
    [updateTask]
  );

  const value = useMemo(
    () => ({
      releases,
      profile,
      loading,
      refresh,
      getRelease,
      createRelease,
      updateRelease,
      deleteRelease,
      toggleTask,
      updateTask,
      postponeTask,
      assignTask,
      addTask,
      removeTask,
      savePostMortem,
      saveTeam,
      saveProfile,
      setTaskActualCost,
    }),
    [
      releases,
      profile,
      loading,
      refresh,
      getRelease,
      createRelease,
      updateRelease,
      deleteRelease,
      toggleTask,
      updateTask,
      postponeTask,
      assignTask,
      addTask,
      removeTask,
      savePostMortem,
      saveTeam,
      saveProfile,
      setTaskActualCost,
    ]
  );

  return <ReleasesContext.Provider value={value}>{children}</ReleasesContext.Provider>;
}

export function useReleases() {
  const ctx = useContext(ReleasesContext);
  if (!ctx) throw new Error('useReleases must be used within ReleasesProvider');
  return ctx;
}

export function useActiveRelease() {
  const { releases } = useReleases();
  const now = new Date();
  now.setHours(0, 0, 0, 0);

  const inProgress = releases.filter((r) => {
    const d = new Date(r.releaseDate);
    d.setHours(0, 0, 0, 0);
    return d >= now && r.status !== 'completed';
  });

  const current = inProgress[0] ?? null;
  const upcoming = inProgress.slice(1);
  const past = releases.filter((r) => {
    const d = new Date(r.releaseDate);
    d.setHours(0, 0, 0, 0);
    return d < now || r.status === 'completed' || r.status === 'released';
  });

  return { current, upcoming, past };
}

export function useRelease(id: string | undefined) {
  const { getRelease, ...rest } = useReleases();
  const release = id ? getRelease(id) : undefined;
  return { release, ...rest };
}
