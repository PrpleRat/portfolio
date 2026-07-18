import { useCallback, useEffect, useState } from 'react';
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Notifications from 'expo-notifications';
import type { Release, Task } from '@/types';
import { formatDate } from '@/types';
import { getDaysUntilDue } from '@/utils/urgencyLevel';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

export async function ensureNotificationPermission(): Promise<boolean> {
  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('dropday', {
      name: 'Rappels DropDay',
      importance: Notifications.AndroidImportance.HIGH,
    });
  }
  const { status: existing } = await Notifications.getPermissionsAsync();
  if (existing === 'granted') return true;
  const { status } = await Notifications.requestPermissionsAsync();
  return status === 'granted';
}

function taskIdentifier(releaseId: string, taskId: string, kind: string): string {
  return `dropday-${releaseId}-${taskId}-${kind}`;
}

async function scheduleAt(
  id: string,
  date: Date,
  title: string,
  body: string,
  data: Record<string, string>
) {
  if (date <= new Date()) return;
  await Notifications.scheduleNotificationAsync({
    content: { title, body, data },
    trigger: { type: Notifications.SchedulableTriggerInputTypes.DATE, date },
    identifier: id,
  });
}

export async function scheduleReleaseNotifications(release: Release) {
  try {
    const granted = await ensureNotificationPermission();
    if (!granted) return;

    await cancelReleaseNotifications(release.id);

    for (const task of release.tasks) {
      if (task.completed) continue;

      const due = new Date(task.dueDate);
      due.setHours(9, 0, 0, 0);

      const j7 = new Date(due);
      j7.setDate(j7.getDate() - 7);
      await scheduleAt(
        taskIdentifier(release.id, task.id, 'j7'),
        j7,
        `📅 Dans 7 jours — ${task.title}`,
        `Pour « ${release.title} »`,
        { releaseId: release.id, taskId: task.id }
      );

      const j3 = new Date(due);
      j3.setDate(j3.getDate() - 3);
      await scheduleAt(
        taskIdentifier(release.id, task.id, 'j3'),
        j3,
        `⚠️ Dans 3 jours — ${task.title}`,
        `Pour « ${release.title} ». Fais-le maintenant.`,
        { releaseId: release.id, taskId: task.id }
      );

      await scheduleAt(
        taskIdentifier(release.id, task.id, 'j0'),
        due,
        `🚨 AUJOURD'HUI — ${task.title}`,
        `Devait être faite pour « ${release.title} ». Agis maintenant.`,
        { releaseId: release.id, taskId: task.id }
      );

      const jPlus1 = new Date(due);
      jPlus1.setDate(jPlus1.getDate() + 1);
      await scheduleAt(
        taskIdentifier(release.id, task.id, 'late'),
        jPlus1,
        `🔴 EN RETARD — ${task.title}`,
        `Ça impacte ta sortie du ${formatDate(release.releaseDate)}.`,
        { releaseId: release.id, taskId: task.id }
      );
    }

    await scheduleCriticalDependencyAlert(release);

    const releaseDay = new Date(release.releaseDate);
    releaseDay.setHours(9, 0, 0, 0);
    const pm7 = new Date(releaseDay);
    pm7.setDate(pm7.getDate() + 7);
    await scheduleAt(
      `dropday-${release.id}-postmortem-7`,
      pm7,
      `📊 « ${release.title} » est sortie il y a 7 jours`,
      'Fais ton bilan post-mortem !',
      { releaseId: release.id, type: 'postmortem' }
    );

    const pm30 = new Date(releaseDay);
    pm30.setDate(pm30.getDate() + 30);
    await scheduleAt(
      `dropday-${release.id}-postmortem-30`,
      pm30,
      `📊 30 jours après « ${release.title} »`,
      'Complète tes stats finales.',
      { releaseId: release.id, type: 'postmortem30' }
    );
  } catch {
    // Non bloquant en Expo Go
  }
}

async function scheduleCriticalDependencyAlert(release: Release) {
  const distribTask = release.tasks.find(
    (t) =>
      !t.completed &&
      (t.title.toLowerCase().includes('distrib') || t.category === 'distribution')
  );
  if (!distribTask) return;

  const daysUntilRelease = getDaysUntilDue({
    ...distribTask,
    dueDate: release.releaseDate,
  } as Task);

  if (daysUntilRelease <= 21 && getDaysUntilDue(distribTask) < 0) {
    await Notifications.scheduleNotificationAsync({
      content: {
        title: '⚠️ Date de sortie en danger',
        body: `Les distributeurs prennent 7-10 jours. Ta date du ${formatDate(release.releaseDate)} est en danger si tu n'agis pas maintenant.`,
        data: { releaseId: release.id, taskId: distribTask.id, type: 'critical' },
      },
      trigger: null,
    });
  }
}

export async function cancelReleaseNotifications(releaseId: string) {
  const scheduled = await Notifications.getAllScheduledNotificationsAsync();
  const toCancel = scheduled
    .filter((n) => n.identifier.startsWith(`dropday-${releaseId}-`))
    .map((n) => n.identifier);
  await Promise.all(toCancel.map((id) => Notifications.cancelScheduledNotificationAsync(id)));
}

export function useNotifications() {
  const [enabled, setEnabled] = useState(true);

  useEffect(() => {
    AsyncStorage.getItem('@dropday/notifications').then((v) => {
      if (v !== null) setEnabled(v === 'true');
    });
  }, []);

  const setNotificationsEnabled = useCallback(async (value: boolean) => {
    setEnabled(value);
    await AsyncStorage.setItem('@dropday/notifications', String(value));
    if (!value) {
      const all = await Notifications.getAllScheduledNotificationsAsync();
      await Promise.all(
        all
          .filter((n) => n.identifier.startsWith('dropday-'))
          .map((n) => Notifications.cancelScheduledNotificationAsync(n.identifier))
      );
    }
  }, []);

  const scheduleForRelease = useCallback(
    async (release: Release) => {
      if (!enabled) return;
      await scheduleReleaseNotifications(release);
    },
    [enabled]
  );

  const cancelForRelease = useCallback(async (releaseId: string) => {
    await cancelReleaseNotifications(releaseId);
  }, []);

  const requestPermission = useCallback(async () => ensureNotificationPermission(), []);

  return {
    enabled,
    setNotificationsEnabled,
    scheduleForRelease,
    cancelForRelease,
    requestPermission,
  };
}
