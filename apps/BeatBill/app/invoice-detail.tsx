import { useMemo } from 'react';
import {
  ScrollView,
  View,
  Text,
  Pressable,
  StyleSheet,
  Alert,
  ActionSheetIOS,
  Platform,
  Linking,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import * as Sharing from 'expo-sharing';
import * as Clipboard from 'expo-clipboard';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { StatusBadge } from '@/components/StatusBadge';
import { useInvoices, useProfile } from '@/hooks/useAppData';
import { useNotifications } from '@/hooks/useServices';
import {
  effectiveStatus,
  formatDate,
  formatMoney,
  generateReminderMessage,
  type InvoiceStatus,
} from '@/types';

export default function InvoiceDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { getInvoiceById, changeStatus, saveInvoice, deleteInvoice } = useInvoices();
  const { profile } = useProfile();
  const { cancelInvoiceReminders } = useNotifications();

  const invoice = getInvoiceById(id);
  const status = invoice ? effectiveStatus(invoice) : 'pending';

  const actionLabels = useMemo(() => {
    if (!invoice) return [];
    return invoice.actions.map((a) => {
      const date = formatDate(a.date);
      switch (a.type) {
        case 'created':
          return `Générée le ${date}`;
        case 'reminded':
          return `Relancée le ${date}`;
        case 'paid':
          return `Payée le ${date}`;
        case 'status_changed':
          return `Statut changé le ${date}${a.note ? ` → ${a.note}` : ''}`;
        case 'shared':
          return `Partagée le ${date}`;
        default:
          return date;
      }
    });
  }, [invoice]);

  if (!invoice) {
    return (
      <View style={styles.centered}>
        <Text style={styles.notFound}>Facture introuvable</Text>
      </View>
    );
  }

  const handleStatusChange = () => {
    const options = ['EN ATTENTE', 'PAYÉE', 'EN RETARD', 'Annuler'];
    const apply = async (index: number) => {
      if (index === 3) return;
      const statuses: InvoiceStatus[] = ['pending', 'paid', 'overdue'];
      const newStatus = statuses[index];
      await changeStatus(invoice.id, newStatus);
      if (newStatus === 'paid') {
        await cancelInvoiceReminders(invoice.id);
      }
    };

    if (Platform.OS === 'ios') {
      ActionSheetIOS.showActionSheetWithOptions(
        { options, cancelButtonIndex: 3, title: 'Changer le statut' },
        apply
      );
    } else {
      Alert.alert('Changer le statut', undefined, [
        { text: 'EN ATTENTE', onPress: () => apply(0) },
        { text: 'PAYÉE', onPress: () => apply(1) },
        { text: 'EN RETARD', onPress: () => apply(2) },
        { text: 'Annuler', style: 'cancel' },
      ]);
    }
  };

  const handleShare = async () => {
    let uri = invoice.pdfUri;
    if (!uri) {
      const { generatePDF } = await import('@/utils/generatePDF');
      uri = await generatePDF(invoice, profile);
      await saveInvoice({ ...invoice, pdfUri: uri });
    }
    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(uri, { mimeType: 'application/pdf' });
      await saveInvoice({
        ...invoice,
        pdfUri: uri,
        actions: [...invoice.actions, { type: 'shared', date: new Date().toISOString() }],
      });
    }
  };

  const handleDuplicate = () => {
    router.push({
      pathname: '/new-invoice',
      params: {
        duplicate: JSON.stringify({
          clientName: invoice.clientName,
          clientEmail: invoice.clientEmail,
          project: invoice.project ?? '',
          items: invoice.items,
          vatRate: invoice.vatRate,
          notes: invoice.notes ?? '',
        }),
      },
    });
  };

  const handleRemind = async () => {
    const message = generateReminderMessage(invoice, profile.name || 'Producteur');
    await Clipboard.setStringAsync(message);
    await saveInvoice({
      ...invoice,
      actions: [...invoice.actions, { type: 'reminded', date: new Date().toISOString() }],
    });
    Alert.alert('Relance', 'Message copié. Envoyer par email ?', [
      { text: 'Non', style: 'cancel' },
      {
        text: 'Email',
        onPress: () => {
          const subject = encodeURIComponent(`Relance facture ${invoice.number}`);
          const body = encodeURIComponent(message);
          const mailto = `mailto:${invoice.clientEmail}?subject=${subject}&body=${body}`;
          Linking.openURL(mailto).catch(() => {
            Alert.alert('Erreur', 'Impossible d\'ouvrir l\'app Mail.');
          });
        },
      },
    ]);
  };

  const handleEdit = () => {
    router.push({
      pathname: '/new-invoice',
      params: {
        import: JSON.stringify({
          clientName: invoice.clientName,
          clientEmail: invoice.clientEmail,
          project: invoice.project ?? '',
          items: invoice.items,
          vatRate: invoice.vatRate,
          notes: invoice.notes ?? '',
          number: invoice.number,
          issueDate: invoice.createdAt,
          dueDate: invoice.dueDate,
          currency: invoice.currency,
          paymentMode: invoice.paymentMode,
          paymentRef: invoice.paymentRef,
          startStep: 2,
        }),
        editId: invoice.id,
      },
    });
  };

  const handleDelete = () => {
    Alert.alert('Supprimer la facture', `Supprimer ${invoice.number} ? Cette action est irréversible.`, [
      { text: 'Annuler', style: 'cancel' },
      {
        text: 'Supprimer',
        style: 'destructive',
        onPress: async () => {
          await cancelInvoiceReminders(invoice.id);
          await deleteInvoice(invoice.id);
          router.replace('/history');
        },
      },
    ]);
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <View>
          <Text style={styles.number}>{invoice.number}</Text>
          <Text style={styles.client}>{invoice.clientName}</Text>
        </View>
        <StatusBadge status={status} />
      </View>

      <View style={styles.amountBox}>
        <Text style={styles.amount}>{formatMoney(invoice.total, invoice.currency)}</Text>
        <Text style={styles.dates}>
          Émise le {formatDate(invoice.createdAt)} · Échéance {formatDate(invoice.dueDate)}
        </Text>
      </View>

      {invoice.project && (
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Projet</Text>
          <Text style={styles.sectionValue}>{invoice.project}</Text>
        </View>
      )}

      <View style={styles.section}>
        <Text style={styles.sectionLabel}>Items</Text>
        {invoice.items.map((item, i) => (
          <View key={i} style={styles.itemRow}>
            <Text style={styles.itemDesc}>{item.description}</Text>
            <Text style={styles.itemTotal}>{formatMoney(item.total, invoice.currency)}</Text>
          </View>
        ))}
        <View style={styles.itemRow}>
          <Text style={styles.itemDesc}>TVA ({invoice.vatRate}%)</Text>
          <Text style={styles.itemTotal}>{formatMoney(invoice.vatAmount, invoice.currency)}</Text>
        </View>
      </View>

      {invoice.notes && (
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Notes</Text>
          <Text style={styles.sectionValue}>{invoice.notes}</Text>
        </View>
      )}

      <View style={styles.actions}>
        <ActionButton icon="swap-horizontal" label="Statut" onPress={handleStatusChange} />
        <ActionButton icon="share-outline" label="Renvoyer" onPress={handleShare} />
        <ActionButton icon="create-outline" label="Modifier" onPress={handleEdit} />
        <ActionButton icon="copy-outline" label="Dupliquer" onPress={handleDuplicate} />
        <ActionButton icon="mail-outline" label="Relancer" onPress={handleRemind} />
        <ActionButton icon="trash-outline" label="Supprimer" onPress={handleDelete} />
      </View>

      <View style={styles.history}>
        <Text style={styles.sectionLabel}>Historique</Text>
        {actionLabels.map((label, i) => (
          <Text key={i} style={styles.historyItem}>
            · {label}
          </Text>
        ))}
      </View>
    </ScrollView>
  );
}

function ActionButton({
  icon,
  label,
  onPress,
}: {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  onPress: () => void;
}) {
  return (
    <Pressable style={styles.actionBtn} onPress={onPress}>
      <Ionicons name={icon} size={22} color={colors.accent} />
      <Text style={styles.actionLabel}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl },
  centered: {
    flex: 1,
    backgroundColor: colors.background,
    alignItems: 'center',
    justifyContent: 'center',
  },
  notFound: { color: colors.textSecondary },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing.lg,
  },
  number: { color: colors.textSecondary, fontSize: 13 },
  client: { color: colors.text, fontSize: 22, fontWeight: '700', marginTop: 4 },
  amountBox: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.lg,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  amount: { color: colors.accentLight, fontSize: 32, fontWeight: '800' },
  dates: { color: colors.textSecondary, fontSize: 13, marginTop: spacing.sm },
  section: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  sectionLabel: {
    color: colors.textSecondary,
    fontSize: 11,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing.sm,
  },
  sectionValue: { color: colors.text, fontSize: 14 },
  itemRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: spacing.xs,
  },
  itemDesc: { color: colors.text, flex: 1, fontSize: 14 },
  itemTotal: { color: colors.accentLight, fontWeight: '600' },
  actions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
    marginBottom: spacing.lg,
  },
  actionBtn: {
    width: '47%',
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.separator,
    gap: spacing.xs,
  },
  actionLabel: { color: colors.text, fontSize: 13, fontWeight: '600' },
  history: {
    backgroundColor: colors.section,
    borderRadius: radius.md,
    padding: spacing.md,
  },
  historyItem: { color: colors.textSecondary, fontSize: 13, marginBottom: 4 },
});
