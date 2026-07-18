import { useEffect, useMemo, useState } from 'react';
import {
  ScrollView,
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
  Alert,
  Modal,
  FlatList,
  Platform,
} from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing, GENRES, DEFAULT_CLAUSES } from '@/constants/theme';
import { HELP } from '@/constants/help';
import { CollaboratorCard, type CollaboratorFormData } from '@/components/CollaboratorCard';
import { InfoTip } from '@/components/InfoTip';
import { TotalIndicator } from '@/components/TotalIndicator';
import { useCollaborators, useProfile } from '@/hooks/useAppData';
import { computeTotals, type SplitDraft, type SplitType } from '@/types';
import { uuid } from '@/utils/uuid';
import type { Collaborator } from '@/types';

function emptyCollaborator(profile?: { name: string; role: string; email: string; sacem?: string }): CollaboratorFormData {
  return {
    id: uuid(),
    name: profile?.name ?? '',
    role: profile?.role ?? 'Producteur',
    masterShare: 0,
    publishingShare: 0,
    sacem: profile?.sacem ?? '',
    email: profile?.email ?? '',
  };
}

export default function NewSplitScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{
    edit?: string;
    duplicate?: string;
    addCollab?: string;
  }>();
  const { profile } = useProfile();
  const { collaborators } = useCollaborators();

  const [title, setTitle] = useState('');
  const [artist, setArtist] = useState('');
  const [genre, setGenre] = useState('');
  const [isrc, setIsrc] = useState('');
  const [createdAt, setCreatedAt] = useState(new Date());
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [splitType, setSplitType] = useState<SplitType>('master_and_publishing');
  const [collaboratorsForm, setCollaboratorsForm] = useState<CollaboratorFormData[]>([
    emptyCollaborator(profile.name ? profile : undefined),
  ]);
  const [clauses, setClauses] = useState<string[]>([DEFAULT_CLAUSES[0], DEFAULT_CLAUSES[1]]);
  const [notes, setNotes] = useState('');
  const [frequentPickerVisible, setFrequentPickerVisible] = useState(false);
  const [generating, setGenerating] = useState(false);

  useEffect(() => {
    if (params.edit) {
      try {
        const data = JSON.parse(params.edit);
        setTitle(data.title ?? '');
        setArtist(data.artist ?? '');
        setGenre(data.genre ?? '');
        setIsrc(data.isrc ?? '');
        setCreatedAt(new Date(data.createdAt));
        setSplitType(data.splitType ?? 'master_and_publishing');
        setClauses(data.clauses ?? []);
        setNotes(data.notes ?? '');
        setCollaboratorsForm(
          data.collaborators?.map((c: CollaboratorFormData) => ({ ...c, id: c.id ?? uuid() })) ?? [
            emptyCollaborator(),
          ]
        );
      } catch {
        // ignore
      }
      return;
    }

    if (params.duplicate) {
      try {
        const data = JSON.parse(params.duplicate);
        setTitle('');
        setArtist(data.artist ?? '');
        setGenre(data.genre ?? '');
        setSplitType(data.splitType ?? 'master_and_publishing');
        setClauses(data.clauses ?? [DEFAULT_CLAUSES[0], DEFAULT_CLAUSES[1]]);
        setCollaboratorsForm(
          data.collaborators?.map((c: CollaboratorFormData) => ({
            ...c,
            id: uuid(),
            masterShare: c.masterShare,
            publishingShare: c.publishingShare,
          })) ?? [emptyCollaborator(profile.name ? profile : undefined)]
        );
      } catch {
        // ignore
      }
      return;
    }

    if (params.addCollab) {
      try {
        const c = JSON.parse(params.addCollab) as Collaborator;
        setCollaboratorsForm((prev) => [
          ...prev,
          {
            id: uuid(),
            name: c.name,
            role: c.role,
            masterShare: 0,
            publishingShare: 0,
            sacem: c.sacem ?? '',
            email: c.email ?? '',
          },
        ]);
      } catch {
        // ignore
      }
    }
  }, [params.edit, params.duplicate, params.addCollab]);

  const totals = useMemo(
    () => computeTotals(collaboratorsForm),
    [collaboratorsForm]
  );

  const isValid = useMemo(() => {
    if (!title.trim()) return false;
    if (!collaboratorsForm.some((c) => c.name.trim())) return false;
    if (totals.master !== 100) return false;
    if (splitType === 'master_and_publishing' && totals.publishing !== 100) return false;
    return true;
  }, [title, collaboratorsForm, totals, splitType]);

  const updateCollaborator = (index: number, data: CollaboratorFormData) => {
    setCollaboratorsForm((prev) => prev.map((c, i) => (i === index ? data : c)));
  };

  const addCollaborator = () => {
    setCollaboratorsForm((prev) => [...prev, emptyCollaborator()]);
  };

  const removeCollaborator = (index: number) => {
    setCollaboratorsForm((prev) => prev.filter((_, i) => i !== index));
  };

  const addFromFrequent = (c: Collaborator) => {
    setCollaboratorsForm((prev) => [
      ...prev,
      {
        id: uuid(),
        name: c.name,
        role: c.role,
        masterShare: 0,
        publishingShare: 0,
        sacem: c.sacem ?? '',
        email: c.email ?? '',
      },
    ]);
    setFrequentPickerVisible(false);
  };

  const toggleClause = (clause: string) => {
    setClauses((prev) =>
      prev.includes(clause) ? prev.filter((c) => c !== clause) : [...prev, clause]
    );
  };

  const handleGenerate = () => {
    if (!title.trim()) {
      Alert.alert('Titre requis', 'Le titre du morceau est obligatoire.');
      return;
    }
    const validCollabs = collaboratorsForm.filter((c) => c.name.trim());
    if (validCollabs.length === 0) {
      Alert.alert('Collaborateurs requis', 'Ajoute au moins un collaborateur.');
      return;
    }
    if (totals.master !== 100) {
      Alert.alert('Total Master', 'La répartition Master doit faire exactement 100%.');
      return;
    }
    if (splitType === 'master_and_publishing' && totals.publishing !== 100) {
      Alert.alert('Total Publishing', 'La répartition Publishing doit faire exactement 100%.');
      return;
    }

    setGenerating(true);

    const draft: SplitDraft = {
      title: title.trim(),
      artist: artist.trim(),
      genre,
      isrc: isrc.trim(),
      createdAt,
      splitType,
      collaborators: validCollabs.map((c) => ({
        name: c.name.trim(),
        role: c.role,
        masterShare: c.masterShare,
        publishingShare: splitType === 'master_only' ? 0 : c.publishingShare,
        sacem: c.sacem.trim() || undefined,
        email: c.email.trim() || undefined,
      })),
      clauses,
      notes: notes.trim(),
    };

    router.push({
      pathname: '/split-preview',
      params: { draft: JSON.stringify(draft) },
    });
    setGenerating(false);
  };

  return (
    <>
      <ScrollView style={styles.container} contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <Text style={styles.section}>Infos du morceau</Text>
        <View style={styles.sectionBox}>
          <Text style={styles.label}>Titre du morceau *</Text>
          <TextInput
            style={styles.input}
            value={title}
            onChangeText={setTitle}
            placeholder="Ex: Banlieue"
            placeholderTextColor={colors.textSecondary}
          />

          <Text style={styles.label}>Artiste principal</Text>
          <TextInput
            style={styles.input}
            value={artist}
            onChangeText={setArtist}
            placeholder="optionnel"
            placeholderTextColor={colors.textSecondary}
          />

          <Text style={styles.label}>Date de création</Text>
          <Pressable style={styles.dateBtn} onPress={() => setShowDatePicker(true)}>
            <Text style={styles.dateText}>
              {createdAt.toLocaleDateString('fr-FR', {
                day: '2-digit',
                month: 'long',
                year: 'numeric',
              })}
            </Text>
            <Ionicons name="calendar-outline" size={20} color={colors.accentLight} />
          </Pressable>
          {showDatePicker && (
            <DateTimePicker
              value={createdAt}
              mode="date"
              display={Platform.OS === 'ios' ? 'spinner' : 'default'}
              onChange={(_, date) => {
                setShowDatePicker(Platform.OS === 'ios');
                if (date) setCreatedAt(date);
              }}
            />
          )}

          <View style={styles.labelRow}>
            <Text style={styles.label}>ISRC</Text>
            <InfoTip title={HELP.isrc.title} text={HELP.isrc.text} />
          </View>
          <TextInput
            style={styles.input}
            value={isrc}
            onChangeText={setIsrc}
            placeholder="Obtenu via ta distrib"
            placeholderTextColor={colors.textSecondary}
          />

          <Text style={styles.label}>Genre</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            {GENRES.map((g) => (
              <Pressable
                key={g}
                style={[styles.chip, genre === g && styles.chipActive]}
                onPress={() => setGenre(genre === g ? '' : g)}
              >
                <Text style={[styles.chipText, genre === g && styles.chipTextActive]}>{g}</Text>
              </Pressable>
            ))}
          </ScrollView>
        </View>

        <View style={styles.sectionRow}>
          <Text style={styles.section}>Type de split</Text>
          <InfoTip title={HELP.splitType.title} text={HELP.splitType.text} />
        </View>
        <View style={styles.toggleRow}>
          <Pressable
            style={[styles.toggleBtn, splitType === 'master_only' && styles.toggleActive]}
            onPress={() => setSplitType('master_only')}
          >
            <Text style={[styles.toggleText, splitType === 'master_only' && styles.toggleTextActive]}>
              Master uniquement
            </Text>
          </Pressable>
          <Pressable
            style={[styles.toggleBtn, splitType === 'master_and_publishing' && styles.toggleActive]}
            onPress={() => setSplitType('master_and_publishing')}
          >
            <Text
              style={[
                styles.toggleText,
                splitType === 'master_and_publishing' && styles.toggleTextActive,
              ]}
            >
              Master + Publishing
            </Text>
          </Pressable>
        </View>

        <View style={styles.collabHeader}>
          <Text style={styles.section}>Collaborateurs</Text>
          <Pressable style={styles.frequentBtn} onPress={() => setFrequentPickerVisible(true)}>
            <Ionicons name="people-outline" size={16} color={colors.accentLight} />
            <Text style={styles.frequentBtnText}>Depuis mes fréquents</Text>
          </Pressable>
        </View>

        {collaboratorsForm.map((c, i) => (
          <CollaboratorCard
            key={c.id}
            index={i}
            data={c}
            splitType={splitType}
            onChange={(data) => updateCollaborator(i, data)}
            onRemove={() => removeCollaborator(i)}
            canRemove={collaboratorsForm.length > 1}
          />
        ))}

        <Pressable style={styles.addBtn} onPress={addCollaborator}>
          <Ionicons name="add-circle-outline" size={22} color={colors.accentLight} />
          <Text style={styles.addBtnText}>Ajouter un collaborateur</Text>
        </Pressable>

        <TotalIndicator label="Master" total={totals.master} />
        {splitType === 'master_and_publishing' && (
          <TotalIndicator label="Publishing" total={totals.publishing} />
        )}

        <Text style={styles.section}>Notes légales</Text>
        <View style={styles.sectionBox}>
          {DEFAULT_CLAUSES.map((clause) => (
            <Pressable key={clause} style={styles.clauseRow} onPress={() => toggleClause(clause)}>
              <Ionicons
                name={clauses.includes(clause) ? 'checkbox' : 'square-outline'}
                size={22}
                color={clauses.includes(clause) ? colors.accent : colors.textSecondary}
              />
              <Text style={styles.clauseText}>{clause}</Text>
            </Pressable>
          ))}
          <Text style={styles.label}>Notes libres</Text>
          <TextInput
            style={[styles.input, styles.multiline]}
            value={notes}
            onChangeText={setNotes}
            placeholder="Clauses spécifiques..."
            placeholderTextColor={colors.textSecondary}
            multiline
          />
        </View>

        <Pressable
          style={[styles.generateBtn, !isValid && styles.generateBtnDisabled]}
          onPress={handleGenerate}
          disabled={!isValid || generating}
        >
          <Text style={styles.generateBtnText}>
            {generating ? 'Génération...' : 'Générer le PDF'}
          </Text>
        </Pressable>
      </ScrollView>

      <Modal visible={frequentPickerVisible} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <Text style={styles.modalTitle}>Collaborateurs fréquents</Text>
            <FlatList
              data={collaborators}
              keyExtractor={(item) => item.id}
              ListEmptyComponent={
                <Text style={styles.emptyModal}>Aucun collaborateur enregistré</Text>
              }
              renderItem={({ item }) => (
                <Pressable style={styles.modalItem} onPress={() => addFromFrequent(item)}>
                  <Text style={styles.modalItemName}>{item.name}</Text>
                  <Text style={styles.modalItemRole}>{item.role}</Text>
                </Pressable>
              )}
            />
            <Pressable style={styles.modalClose} onPress={() => setFrequentPickerVisible(false)}>
              <Text style={styles.modalCloseText}>Fermer</Text>
            </Pressable>
          </View>
        </View>
      </Modal>

    </>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
  section: {
    color: colors.textSecondary,
    fontSize: 12,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: 0,
    marginTop: spacing.md,
  },
  sectionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.sm,
    marginTop: spacing.md,
  },
  labelRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing.sm,
    marginBottom: spacing.xs,
  },
  sectionBox: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
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
  multiline: { minHeight: 80, textAlignVertical: 'top' },
  dateBtn: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: colors.section,
    borderRadius: radius.sm,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  dateText: { color: colors.text, fontSize: 16 },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.sm,
    borderWidth: 1,
    borderColor: colors.separator,
    marginRight: spacing.sm,
    marginTop: spacing.xs,
  },
  chipActive: { backgroundColor: colors.accent, borderColor: colors.accent },
  chipText: { color: colors.textSecondary, fontSize: 13 },
  chipTextActive: { color: colors.text, fontWeight: '600' },
  toggleRow: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginBottom: spacing.md,
  },
  toggleBtn: {
    flex: 1,
    padding: spacing.md,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.separator,
    backgroundColor: colors.card,
    alignItems: 'center',
  },
  toggleActive: { backgroundColor: colors.accent, borderColor: colors.accent },
  toggleText: { color: colors.textSecondary, fontSize: 13, fontWeight: '600', textAlign: 'center' },
  toggleTextActive: { color: colors.text },
  collabHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  frequentBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  frequentBtnText: { color: colors.accentLight, fontSize: 12 },
  addBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    padding: spacing.md,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.accent,
    borderRadius: radius.md,
    borderStyle: 'dashed',
  },
  addBtnText: { color: colors.accentLight, fontWeight: '600' },
  generateBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.lg,
  },
  generateBtnDisabled: { opacity: 0.4 },
  generateBtnText: { color: colors.text, fontSize: 17, fontWeight: '700' },
  clauseRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing.sm,
    marginBottom: spacing.sm,
    paddingVertical: spacing.xs,
  },
  clauseText: { color: colors.text, fontSize: 14, flex: 1 },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.8)',
    justifyContent: 'flex-end',
  },
  modalSheet: {
    backgroundColor: colors.card,
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
    padding: spacing.lg,
    maxHeight: '60%',
  },
  modalTitle: {
    color: colors.text,
    fontSize: 18,
    fontWeight: '700',
    marginBottom: spacing.md,
  },
  modalItem: {
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.separator,
  },
  modalItemName: { color: colors.text, fontSize: 16, fontWeight: '600' },
  modalItemRole: { color: colors.textSecondary, fontSize: 12, marginTop: 2 },
  modalClose: { padding: spacing.md, alignItems: 'center' },
  modalCloseText: { color: colors.accentLight, fontWeight: '600' },
  emptyModal: { color: colors.textSecondary, textAlign: 'center', padding: spacing.lg },
});
