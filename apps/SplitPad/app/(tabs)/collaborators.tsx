import { useState } from 'react';
import {
  ScrollView,
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
  Alert,
  Modal,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { RolePicker } from '@/components/RolePicker';
import { useCollaborators } from '@/hooks/useAppData';
import { uuid } from '@/utils/uuid';
import type { Collaborator } from '@/types';

export default function CollaboratorsScreen() {
  const { collaborators, saveCollaborator, deleteCollaborator } = useCollaborators();
  const [modalVisible, setModalVisible] = useState(false);
  const [editing, setEditing] = useState<Collaborator | null>(null);
  const [name, setName] = useState('');
  const [role, setRole] = useState('Producteur');
  const [email, setEmail] = useState('');
  const [sacem, setSacem] = useState('');

  const openAdd = () => {
    setEditing(null);
    setName('');
    setRole('Producteur');
    setEmail('');
    setSacem('');
    setModalVisible(true);
  };

  const openEdit = (c: Collaborator) => {
    setEditing(c);
    setName(c.name);
    setRole(c.role);
    setEmail(c.email ?? '');
    setSacem(c.sacem ?? '');
    setModalVisible(true);
  };

  const handleSave = async () => {
    if (!name.trim()) {
      Alert.alert('Nom requis', 'Le nom du collaborateur est obligatoire.');
      return;
    }

    const collab: Collaborator = {
      id: editing?.id ?? uuid(),
      name: name.trim(),
      role,
      email: email.trim() || undefined,
      sacem: sacem.trim() || undefined,
      lastUsedAt: editing?.lastUsedAt ?? new Date().toISOString(),
      splitCount: editing?.splitCount ?? 0,
    };

    await saveCollaborator(collab);
    setModalVisible(false);
  };

  const handleDelete = (c: Collaborator) => {
    Alert.alert('Supprimer', `Retirer ${c.name} du carnet ?`, [
      { text: 'Annuler', style: 'cancel' },
      {
        text: 'Supprimer',
        style: 'destructive',
        onPress: () => deleteCollaborator(c.id),
      },
    ]);
  };

  return (
    <>
      <ScrollView style={styles.container} contentContainerStyle={styles.content}>
        <Pressable style={styles.addBtn} onPress={openAdd}>
          <Ionicons name="person-add-outline" size={20} color={colors.text} />
          <Text style={styles.addBtnText}>Ajouter manuellement</Text>
        </Pressable>

        {collaborators.length === 0 ? (
          <View style={styles.empty}>
            <Ionicons name="people-outline" size={48} color={colors.textSecondary} />
            <Text style={styles.emptyText}>Ton carnet se remplit automatiquement</Text>
            <Text style={styles.emptyHint}>
              Chaque split enregistre tes collaborateurs pour les réutiliser en 1 tap
            </Text>
          </View>
        ) : (
          collaborators.map((c) => (
            <Pressable key={c.id} style={styles.card} onPress={() => openEdit(c)}>
              <View style={styles.avatar}>
                <Text style={styles.avatarText}>{c.name.charAt(0).toUpperCase()}</Text>
              </View>
              <View style={styles.info}>
                <Text style={styles.name}>{c.name}</Text>
                <Text style={styles.role}>{c.role}</Text>
                {c.sacem ? <Text style={styles.sacem}>SACEM {c.sacem}</Text> : null}
                {c.email ? <Text style={styles.email}>{c.email}</Text> : null}
                <Text style={styles.stats}>
                  {c.sharedSplits} split{c.sharedSplits > 1 ? 's' : ''} en commun
                </Text>
              </View>
              <Pressable onPress={() => handleDelete(c)} hitSlop={12}>
                <Ionicons name="trash-outline" size={20} color={colors.error} />
              </Pressable>
            </Pressable>
          ))
        )}
      </ScrollView>

      <Modal visible={modalVisible} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <Text style={styles.modalTitle}>
              {editing ? 'Modifier' : 'Nouveau'} collaborateur
            </Text>

            <Text style={styles.label}>Nom / alias *</Text>
            <TextInput
              style={styles.input}
              value={name}
              onChangeText={setName}
              placeholder="Nom de scène"
              placeholderTextColor={colors.textSecondary}
            />

            <Text style={styles.label}>Rôle habituel</Text>
            <RolePicker value={role} onChange={setRole} />

            <Text style={styles.label}>Email</Text>
            <TextInput
              style={styles.input}
              value={email}
              onChangeText={setEmail}
              placeholder="optionnel"
              placeholderTextColor={colors.textSecondary}
              keyboardType="email-address"
              autoCapitalize="none"
            />

            <Text style={styles.label}>SACEM / PRO</Text>
            <TextInput
              style={styles.input}
              value={sacem}
              onChangeText={setSacem}
              placeholder="Numéro d'adhérent"
              placeholderTextColor={colors.textSecondary}
              keyboardType="number-pad"
            />

            <Pressable style={styles.saveBtn} onPress={handleSave}>
              <Text style={styles.saveBtnText}>Enregistrer</Text>
            </Pressable>
            <Pressable style={styles.cancelBtn} onPress={() => setModalVisible(false)}>
              <Text style={styles.cancelBtnText}>Annuler</Text>
            </Pressable>
          </View>
        </View>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl },
  addBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.lg,
  },
  addBtnText: { color: colors.text, fontWeight: '700', fontSize: 15 },
  empty: {
    alignItems: 'center',
    padding: spacing.xl,
    backgroundColor: colors.card,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  emptyText: {
    color: colors.text,
    fontSize: 16,
    fontWeight: '600',
    marginTop: spacing.md,
    textAlign: 'center',
  },
  emptyHint: {
    color: colors.textSecondary,
    fontSize: 13,
    marginTop: spacing.xs,
    textAlign: 'center',
  },
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
    gap: spacing.md,
  },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: { color: colors.text, fontSize: 18, fontWeight: '700' },
  info: { flex: 1 },
  name: { color: colors.text, fontSize: 16, fontWeight: '600' },
  role: { color: colors.textSecondary, fontSize: 12, marginTop: 2 },
  sacem: { color: colors.accentLight, fontSize: 11, marginTop: 2 },
  email: { color: colors.textSecondary, fontSize: 11 },
  stats: { color: colors.textSecondary, fontSize: 11, marginTop: 4 },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.85)',
    justifyContent: 'flex-end',
  },
  modalSheet: {
    backgroundColor: colors.card,
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
    padding: spacing.lg,
    paddingBottom: spacing.xl,
  },
  modalTitle: {
    color: colors.text,
    fontSize: 20,
    fontWeight: '700',
    marginBottom: spacing.lg,
  },
  label: {
    color: colors.textSecondary,
    fontSize: 12,
    marginBottom: spacing.xs,
    marginTop: spacing.sm,
  },
  input: {
    backgroundColor: colors.section,
    borderRadius: radius.sm,
    padding: spacing.md,
    color: colors.text,
    fontSize: 16,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  saveBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.lg,
  },
  saveBtnText: { color: colors.text, fontWeight: '700', fontSize: 16 },
  cancelBtn: { padding: spacing.md, alignItems: 'center' },
  cancelBtnText: { color: colors.accentLight },
});
