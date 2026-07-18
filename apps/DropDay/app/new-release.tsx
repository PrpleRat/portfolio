import { useMemo, useState } from 'react';
import {
  ScrollView,
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
  Platform,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import DateTimePicker from '@react-native-community/datetimepicker';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing, FORMAT_OPTIONS, LEVEL_OPTIONS } from '@/constants/theme';
import { useReleases } from '@/hooks/useReleases';
import type { ReleaseFormat, ArtistLevel, Task } from '@/types';
import { formatMoney } from '@/types';
import { generateTasksFromTemplate, getTemplateWeeks } from '@/utils/templateEngine';

type Step = 1 | 2 | 3;

export default function NewReleaseScreen() {
  const router = useRouter();
  const { createRelease, profile } = useReleases();

  const [step, setStep] = useState<Step>(1);
  const [title, setTitle] = useState('');
  const [format, setFormat] = useState<ReleaseFormat>('single');
  const [level, setLevel] = useState<ArtistLevel>('beginner');
  const [releaseDate, setReleaseDate] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() + 56);
    return d;
  });
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [costs, setCosts] = useState<Record<string, string>>({});
  const [busy, setBusy] = useState(false);

  const weeks = getTemplateWeeks(format, level);

  const totalBudget = useMemo(
    () => tasks.reduce((sum, t) => sum + (t.estimatedCost || 0), 0),
    [tasks]
  );

  const goToStep2 = () => {
    if (!title.trim()) {
      Alert.alert('Titre requis', 'Donne un nom à ta release.');
      return;
    }
    const generated = generateTasksFromTemplate(format, level, releaseDate);
    if (generated.length === 0) {
      Alert.alert(
        'Template indisponible',
        'Pas de template pour cette combinaison. Essaie un autre niveau.'
      );
      return;
    }
    setTasks(generated);
    const initialCosts: Record<string, string> = {};
    generated.forEach((t) => {
      if (t.estimatedCost) initialCosts[t.title] = String(t.estimatedCost);
    });
    setCosts(initialCosts);
    setStep(2);
  };

  const removeTask = (id: string) => {
    setTasks((prev) => prev.filter((t) => t.id !== id));
  };

  const goToStep3 = () => {
    if (tasks.length === 0) {
      Alert.alert('Timeline vide', 'Garde au moins une étape.');
      return;
    }
    setStep(3);
  };

  const submit = async () => {
    setBusy(true);
    const costOverrides: Record<string, number> = {};
    Object.entries(costs).forEach(([k, v]) => {
      const n = parseFloat(v.replace(',', '.'));
      if (!Number.isNaN(n)) costOverrides[k] = n;
    });

    const finalTasks = tasks.map((t) => ({
      ...t,
      estimatedCost: costOverrides[t.title] ?? t.estimatedCost ?? 0,
    }));

    const release = await createRelease({
      title: title.trim(),
      format,
      level,
      releaseDate,
      tasks: finalTasks,
    });
    setBusy(false);

    if (release) {
      router.replace(`/release/${release.id}/timeline`);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.steps}>
        {[1, 2, 3].map((s) => (
          <View key={s} style={[styles.stepDot, step >= s && styles.stepDotActive]} />
        ))}
      </View>

      {step === 1 && (
        <>
          <Text style={styles.stepTitle}>Infos de base</Text>
          <Field label="Titre de la release" value={title} onChangeText={setTitle} />

          <Text style={styles.label}>Format</Text>
          <View style={styles.cards}>
            {FORMAT_OPTIONS.map((f) => (
              <Pressable
                key={f.value}
                style={[styles.formatCard, format === f.value && styles.formatCardActive]}
                onPress={() => setFormat(f.value)}
              >
                <Text style={styles.formatEmoji}>{f.emoji}</Text>
                <Text style={styles.formatLabel}>{f.label}</Text>
              </Pressable>
            ))}
          </View>

          <Text style={styles.label}>Niveau artistique</Text>
          {LEVEL_OPTIONS.map((l) => (
            <Pressable
              key={l.value}
              style={[styles.levelRow, level === l.value && styles.levelRowActive]}
              onPress={() => setLevel(l.value)}
            >
              <Text style={styles.levelEmoji}>{l.emoji}</Text>
              <View>
                <Text style={styles.levelLabel}>{l.label}</Text>
                <Text style={styles.levelHint}>{l.hint}</Text>
              </View>
            </Pressable>
          ))}

          <Text style={styles.label}>Date de sortie cible</Text>
          <Pressable style={styles.dateBtn} onPress={() => setShowDatePicker(true)}>
            <Ionicons name="calendar-outline" size={20} color={colors.accentLight} />
            <Text style={styles.dateText}>
              {releaseDate.toLocaleDateString('fr-FR')} · ~{weeks} semaines
            </Text>
          </Pressable>
          {showDatePicker && (
            <DateTimePicker
              value={releaseDate}
              mode="date"
              minimumDate={new Date()}
              display={Platform.OS === 'ios' ? 'spinner' : 'default'}
              onChange={(_, date) => {
                setShowDatePicker(Platform.OS === 'ios');
                if (date) setReleaseDate(date);
              }}
            />
          )}

          <Pressable style={styles.primaryBtn} onPress={goToStep2}>
            <Text style={styles.primaryText}>Générer le template →</Text>
          </Pressable>
        </>
      )}

      {step === 2 && (
        <>
          <Text style={styles.stepTitle}>Timeline générée</Text>
          <Text style={styles.hint}>
            {tasks.length} étapes · modifiable avant validation
          </Text>
          {tasks
            .sort((a, b) => a.daysOffset - b.daysOffset)
            .map((t) => (
              <View key={t.id} style={styles.taskRow}>
                <View style={styles.taskInfo}>
                  <Text style={styles.taskOffset}>
                    J{t.daysOffset >= 0 ? '+' : ''}
                    {t.daysOffset}
                  </Text>
                  <Text style={styles.taskTitle}>{t.title}</Text>
                </View>
                <Pressable onPress={() => removeTask(t.id)} hitSlop={8}>
                  <Ionicons name="trash-outline" size={18} color={colors.error} />
                </Pressable>
              </View>
            ))}

          <View style={styles.navRow}>
            <Pressable style={styles.secondaryBtn} onPress={() => setStep(1)}>
              <Text style={styles.secondaryText}>← Retour</Text>
            </Pressable>
            <Pressable style={styles.primaryBtn} onPress={goToStep3}>
              <Text style={styles.primaryText}>Budget →</Text>
            </Pressable>
          </View>
        </>
      )}

      {step === 3 && (
        <>
          <Text style={styles.stepTitle}>Budget promo (optionnel)</Text>
          {tasks
            .filter((t) => t.category !== 'release' && t.category !== 'post_release')
            .map((t) => (
              <View key={t.id} style={styles.costRow}>
                <Text style={styles.costLabel} numberOfLines={1}>
                  {t.title}
                </Text>
                <TextInput
                  style={styles.costInput}
                  keyboardType="numeric"
                  placeholder="0"
                  placeholderTextColor={colors.textSecondary}
                  value={costs[t.title] ?? ''}
                  onChangeText={(v) => setCosts({ ...costs, [t.title]: v })}
                />
                <Text style={styles.costSym}>{profile.currency === 'EUR' ? '€' : '$'}</Text>
              </View>
            ))}

          <View style={styles.totalBox}>
            <Text style={styles.totalLabel}>Total estimé</Text>
            <Text style={styles.totalValue}>{formatMoney(totalBudget, profile.currency)}</Text>
          </View>

          <View style={styles.navRow}>
            <Pressable style={styles.secondaryBtn} onPress={() => setStep(2)}>
              <Text style={styles.secondaryText}>← Retour</Text>
            </Pressable>
            <Pressable style={styles.primaryBtn} onPress={submit} disabled={busy}>
              <Text style={styles.primaryText}>
                {busy ? 'Création…' : 'Générer la release 🎉'}
              </Text>
            </Pressable>
          </View>
        </>
      )}
    </ScrollView>
  );
}

function Field({
  label,
  value,
  onChangeText,
}: {
  label: string;
  value: string;
  onChangeText: (v: string) => void;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        style={styles.input}
        value={value}
        onChangeText={onChangeText}
        placeholderTextColor={colors.textSecondary}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
  steps: { flexDirection: 'row', gap: spacing.sm, marginBottom: spacing.lg },
  stepDot: {
    flex: 1,
    height: 4,
    borderRadius: 2,
    backgroundColor: colors.future,
  },
  stepDotActive: { backgroundColor: colors.accent },
  stepTitle: { color: colors.text, fontSize: 22, fontWeight: '700', marginBottom: spacing.md },
  field: { marginBottom: spacing.md },
  label: { color: colors.textSecondary, fontSize: 13, marginBottom: spacing.sm, marginTop: spacing.sm },
  input: {
    backgroundColor: colors.card,
    borderRadius: radius.sm,
    padding: spacing.md,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  cards: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  formatCard: {
    width: '47%',
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.separator,
  },
  formatCardActive: { borderColor: colors.accent, backgroundColor: colors.accent + '18' },
  formatEmoji: { fontSize: 28 },
  formatLabel: { color: colors.text, fontSize: 13, marginTop: spacing.xs, fontWeight: '600' },
  levelRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    backgroundColor: colors.card,
    padding: spacing.md,
    borderRadius: radius.md,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  levelRowActive: { borderColor: colors.accent },
  levelEmoji: { fontSize: 24 },
  levelLabel: { color: colors.text, fontWeight: '600' },
  levelHint: { color: colors.textSecondary, fontSize: 12 },
  dateBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    backgroundColor: colors.card,
    padding: spacing.md,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  dateText: { color: colors.text, fontSize: 15 },
  primaryBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    flex: 1,
    marginTop: spacing.lg,
  },
  primaryText: { color: colors.white, fontWeight: '700', fontSize: 16 },
  hint: { color: colors.textSecondary, fontSize: 13, marginBottom: spacing.md },
  taskRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    padding: spacing.sm,
    borderRadius: radius.sm,
    marginBottom: spacing.xs,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  taskInfo: { flex: 1, flexDirection: 'row', gap: spacing.sm, alignItems: 'center' },
  taskOffset: { color: colors.accentLight, fontSize: 12, fontWeight: '700', width: 36 },
  taskTitle: { color: colors.text, fontSize: 14, flex: 1 },
  navRow: { flexDirection: 'row', gap: spacing.sm, marginTop: spacing.lg },
  secondaryBtn: {
    padding: spacing.md,
    justifyContent: 'center',
  },
  secondaryText: { color: colors.accentLight, fontSize: 16 },
  costRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.sm,
  },
  costLabel: { flex: 1, color: colors.text, fontSize: 14 },
  costInput: {
    width: 72,
    backgroundColor: colors.card,
    borderRadius: radius.sm,
    padding: spacing.sm,
    color: colors.text,
    textAlign: 'right',
    borderWidth: 1,
    borderColor: colors.separator,
  },
  costSym: { color: colors.textSecondary, width: 16 },
  totalBox: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  totalLabel: { color: colors.textSecondary },
  totalValue: { color: colors.text, fontWeight: '800', fontSize: 18 },
});
