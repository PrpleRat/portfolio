import { useState } from 'react';
import {
  ScrollView,
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { useClients, useProfile } from '@/hooks/useAppData';
import { formatMoney } from '@/types';

export default function ClientsScreen() {
  const router = useRouter();
  const { clients, addClient } = useClients();
  const { profile } = useProfile();
  const [showForm, setShowForm] = useState(false);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');

  const handleAdd = async () => {
    if (!name.trim() || !email.trim()) {
      Alert.alert('Champs requis', 'Nom et email sont obligatoires.');
      return;
    }
    await addClient(name.trim(), email.trim());
    setName('');
    setEmail('');
    setShowForm(false);
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Pressable style={styles.addBtn} onPress={() => setShowForm(!showForm)}>
        <Ionicons name={showForm ? 'close' : 'person-add'} size={20} color={colors.accent} />
        <Text style={styles.addBtnText}>{showForm ? 'Annuler' : 'Ajouter un client'}</Text>
      </Pressable>

      {showForm && (
        <View style={styles.form}>
          <TextInput
            style={styles.input}
            value={name}
            onChangeText={setName}
            placeholder="Nom (artiste / label)"
            placeholderTextColor={colors.textSecondary}
          />
          <TextInput
            style={styles.input}
            value={email}
            onChangeText={setEmail}
            placeholder="Email"
            placeholderTextColor={colors.textSecondary}
            keyboardType="email-address"
            autoCapitalize="none"
          />
          <Pressable style={styles.saveBtn} onPress={handleAdd}>
            <Text style={styles.saveBtnText}>Enregistrer</Text>
          </Pressable>
        </View>
      )}

      {clients.length === 0 ? (
        <View style={styles.empty}>
          <Ionicons name="people-outline" size={48} color={colors.textSecondary} />
          <Text style={styles.emptyText}>Aucun client enregistré</Text>
          <Text style={styles.emptyHint}>
            Les clients sont ajoutés automatiquement lors de la création de factures
          </Text>
        </View>
      ) : (
        clients.map((client) => (
          <Pressable
            key={client.id}
            style={styles.card}
            onPress={() =>
              router.push({ pathname: '/client-detail', params: { id: client.id } })
            }
          >
            <View style={styles.cardHeader}>
              <Text style={styles.clientName}>{client.name}</Text>
              <Text style={styles.invoiceCount}>{client.invoiceCount} facture(s)</Text>
            </View>
            <Text style={styles.email}>{client.email}</Text>
            <Text style={styles.total}>
              Total encaissé : {formatMoney(client.totalCollected, profile.currency)}
            </Text>
          </Pressable>
        ))
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl },
  addBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.lg,
  },
  addBtnText: { color: colors.accentLight, fontSize: 15, fontWeight: '600' },
  form: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.lg,
    borderWidth: 1,
    borderColor: colors.separator,
    gap: spacing.sm,
  },
  input: {
    backgroundColor: colors.section,
    borderRadius: radius.sm,
    padding: spacing.md,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  saveBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.sm,
    padding: spacing.md,
    alignItems: 'center',
  },
  saveBtnText: { color: colors.background, fontWeight: '700' },
  empty: {
    alignItems: 'center',
    padding: spacing.xl,
    backgroundColor: colors.card,
    borderRadius: radius.md,
  },
  emptyText: {
    color: colors.text,
    fontSize: 16,
    fontWeight: '600',
    marginTop: spacing.md,
  },
  emptyHint: {
    color: colors.textSecondary,
    fontSize: 13,
    marginTop: spacing.xs,
    textAlign: 'center',
  },
  card: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  clientName: { color: colors.text, fontSize: 16, fontWeight: '600' },
  invoiceCount: { color: colors.textSecondary, fontSize: 12 },
  email: { color: colors.textSecondary, fontSize: 13, marginBottom: 4 },
  total: { color: colors.accentLight, fontSize: 13, fontWeight: '600' },
});
