import { useCallback, useEffect, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import type { Invoice } from '@/types';
import { formatMoney } from '@/types';

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
    await Notifications.setNotificationChannelAsync('reminders', {
      name: 'Relances factures',
      importance: Notifications.AndroidImportance.DEFAULT,
    });
  }
  const { status: existing } = await Notifications.getPermissionsAsync();
  if (existing === 'granted') return true;
  const { status } = await Notifications.requestPermissionsAsync();
  return status === 'granted';
}

export async function scheduleInvoiceRemindersFor(invoice: Invoice, delayDays: number) {
  try {
    const granted = await ensureNotificationPermission();
    if (!granted) return;

    const due = new Date(invoice.dueDate);
    const delays = [delayDays, delayDays + 4, delayDays + 11];

    for (const days of delays) {
      const triggerDate = new Date(due);
      triggerDate.setDate(triggerDate.getDate() + days);
      if (triggerDate <= new Date()) continue;

      const emoji = days >= delayDays + 11 ? '⚠️' : '💰';
      const title =
        days >= delayDays + 11
          ? `${emoji} Facture ${invoice.number} en retard de ${days} jours`
          : `${emoji} Facture ${invoice.number} impayée — ${invoice.clientName} · ${formatMoney(invoice.total, invoice.currency)}`;

      await Notifications.scheduleNotificationAsync({
        content: {
          title,
          body: `Relance automatique BeatBill · ${invoice.clientName}`,
          data: { invoiceId: invoice.id, type: 'reminder', days },
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DATE,
          date: triggerDate,
        },
        identifier: `beatbill-${invoice.id}-${days}`,
      });
    }
  } catch {
    // Expo Go / simulateur : notifications parfois indisponibles — non bloquant
  }
}

export async function cancelInvoiceRemindersFor(invoiceId: string) {
  const scheduled = await Notifications.getAllScheduledNotificationsAsync();
  const toCancel = scheduled
    .filter((n) => n.identifier.startsWith(`beatbill-${invoiceId}-`))
    .map((n) => n.identifier);
  await Promise.all(toCancel.map((id) => Notifications.cancelScheduledNotificationAsync(id)));
}

export function useNotifications() {
  const requestPermission = useCallback(async () => ensureNotificationPermission(), []);

  const scheduleInvoiceReminders = useCallback(
    async (invoice: Invoice, delayDays = 7) => {
      await scheduleInvoiceRemindersFor(invoice, delayDays);
    },
    []
  );

  const cancelInvoiceReminders = useCallback(async (invoiceId: string) => {
    await cancelInvoiceRemindersFor(invoiceId);
  }, []);

  return { requestPermission, scheduleInvoiceReminders, cancelInvoiceReminders };
}

/** Nettoie l'ancien flag IAP (app payante à l'achat). */
export async function clearLegacyPurchaseFlag(): Promise<void> {
  await AsyncStorage.removeItem('@beatbill/is_pro');
}
