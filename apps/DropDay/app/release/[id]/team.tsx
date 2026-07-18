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
import { useLocalSearchParams } from 'expo-router';
import * as Sharing from 'expo-sharing';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { useRelease, useReleases } from '@/hooks/useReleases';
import { usePurchase } from '@/hooks/usePurchase';
import type { TeamMember } from '@/types';
import { generateTeamPDF } from '@/utils/generatePDF';

const DEFAULT_ROLES = ['Ingénieur son', 'Graphiste', 'Manager', 'Attaché de presse'];

export default function TeamScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { release, saveTeam, profile } = useRelease(id);
  const { releases } = useReleases();
  const { isPro } = usePurchase(releases.length);
  const [team, setTeam] = useState<TeamMember[]>(release?.team ?? []);
  const [exporting, setExporting] = useState(false);

  if (!release) return null;

  const updateMember = (index: number, patch: Partial<TeamMember>) => {
    setTeam((prev) => prev.map((m, i) => (i === index ? { ...m, ...patch } : m)));
  };

  const addMember = (role: string) => {
    setTeam((prev) => [...prev, { role, name: '', email: '' }]);
  };

  const removeMember = (index: number) => {
    setTeam((prev) => prev.filter((_, i) => i !== index));
  };

  const save = async () => {
    await saveTeam(release.id, team.filter((m) => m.name.trim()));
    Alert.alert('Enregistré', 'Équipe mise à jour.');
  };

  const exportPdf = async () => {
    if (!isPro && releases.length > 1) {
      Alert.alert('Pro requis', 'Export PDF disponible avec DropDay Pro.');
      return;
    }
    setExporting(true);
    try {
      const releaseWithTeam = { ...release, team: team.filter((m) => m.name.trim()) };
      const uri = await generateTeamPDF(releaseWithTeam, profile.currency);
      if (await Sharing.isAvailableAsync()) {
        await Sharing.shareAsync(uri, {
          mimeType: 'application/pdf',
          dialogTitle: `DropDay — ${release.title}`,
        });
      } else {
        Alert.alert('PDF généré', uri);
      }
    } catch {
      Alert.alert('Erreur', 'Impossible de générer le PDF.');
    }
    setExporting(false);
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.hint}>
        Contacts associés à cette release. Le PDF inclut la timeline + responsables.
      </Text>

      {team.map((member, index) => (
        <View key={index} style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.role}>{member.role}</Text>
            <Pressable onPress={() => removeMember(index)} hitSlop={8}>
              <Ionicons name="close-circle" size={22} color={colors.textSecondary} />
            </Pressable>
          </View>
          <TextInput
            style={styles.input}
            placeholder="Nom"
            placeholderTextColor={colors.textSecondary}
            value={member.name}
            onChangeText={(name) => updateMember(index, { name })}
          />
          <TextInput
            style={styles.input}
            placeholder="Email"
            placeholderTextColor={colors.textSecondary}
            value={member.email}
            onChangeText={(email) => updateMember(index, { email })}
            keyboardType="email-address"
            autoCapitalize="none"
          />
        </View>
      ))}

      <Text style={styles.addLabel}>Ajouter un rôle</Text>
      <View style={styles.roles}>
        {DEFAULT_ROLES.map((role) => (
          <Pressable key={role} style={styles.roleChip} onPress={() => addMember(role)}>
            <Ionicons name="add" size={16} color={colors.accentLight} />
            <Text style={styles.roleChipText}>{role}</Text>
          </Pressable>
        ))}
      </View>

      <Pressable style={styles.saveBtn} onPress={save}>
        <Text style={styles.saveText}>Enregistrer l'équipe</Text>
      </Pressable>

      <Pressable style={styles.exportBtn} onPress={exportPdf} disabled={exporting}>
        <Ionicons name="document-outline" size={20} color={colors.white} />
        <Text style={styles.exportText}>
          {exporting ? 'Génération…' : 'Exporter PDF équipe'}
        </Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
  hint: { color: colors.textSecondary, fontSize: 14, marginBottom: spacing.lg, lineHeight: 20 },
  card: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: spacing.sm },
  role: { color: colors.accentLight, fontWeight: '700', fontSize: 14 },
  input: {
    backgroundColor: colors.background,
    borderRadius: radius.sm,
    padding: spacing.sm,
    color: colors.text,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  addLabel: { color: colors.textSecondary, fontSize: 12, marginTop: spacing.md, marginBottom: spacing.sm },
  roles: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  roleChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: colors.card,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: radius.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  roleChipText: { color: colors.text, fontSize: 13 },
  saveBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.lg,
  },
  saveText: { color: colors.white, fontWeight: '700' },
  exportBtn: {
    backgroundColor: colors.section,
    borderRadius: radius.md,
    padding: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    marginTop: spacing.sm,
    borderWidth: 1,
    borderColor: colors.accent,
  },
  exportText: { color: colors.white, fontWeight: '600' },
});
