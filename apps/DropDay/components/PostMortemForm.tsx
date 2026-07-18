import { View, Text, TextInput, Pressable, StyleSheet, ScrollView } from 'react-native';
import { colors, radius, spacing } from '@/constants/theme';
import type { PostMortem } from '@/types';
import { Ionicons } from '@expo/vector-icons';

interface PostMortemFormProps {
  data: PostMortem;
  onChange: (data: PostMortem) => void;
  onSave: () => void;
  saving?: boolean;
}

function Field({
  label,
  value,
  onChangeText,
  keyboardType = 'default',
  multiline,
}: {
  label: string;
  value: string;
  onChangeText: (v: string) => void;
  keyboardType?: 'default' | 'numeric';
  multiline?: boolean;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        style={[styles.input, multiline && styles.multiline]}
        value={value}
        onChangeText={onChangeText}
        keyboardType={keyboardType}
        multiline={multiline}
        placeholderTextColor={colors.textSecondary}
      />
    </View>
  );
}

function NumField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: number;
  onChange: (n: number) => void;
}) {
  return (
    <Field
      label={label}
      value={value ? String(value) : ''}
      onChangeText={(v) => onChange(parseInt(v, 10) || 0)}
      keyboardType="numeric"
    />
  );
}

export function PostMortemForm({ data, onChange, onSave, saving }: PostMortemFormProps) {
  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.sectionTitle}>Chiffres J+7</Text>
      <NumField
        label="Streams Spotify (semaine 1)"
        value={data.streamsWeek1Spotify}
        onChange={(n) => onChange({ ...data, streamsWeek1Spotify: n })}
      />
      <NumField
        label="Streams Apple Music (semaine 1)"
        value={data.streamsWeek1Apple}
        onChange={(n) => onChange({ ...data, streamsWeek1Apple: n })}
      />

      <Text style={styles.sectionTitle}>Chiffres J+30</Text>
      <NumField
        label="Streams Spotify (30 jours)"
        value={data.streamsMonth1Spotify}
        onChange={(n) => onChange({ ...data, streamsMonth1Spotify: n })}
      />
      <NumField
        label="Streams Apple Music (30 jours)"
        value={data.streamsMonth1Apple}
        onChange={(n) => onChange({ ...data, streamsMonth1Apple: n })}
      />

      <NumField
        label="Playlists obtenues"
        value={data.playlistsObtained}
        onChange={(n) => onChange({ ...data, playlistsObtained: n })}
      />
      <NumField
        label="Médias / blogs"
        value={data.mediasCovered}
        onChange={(n) => onChange({ ...data, mediasCovered: n })}
      />
      <NumField
        label="Followers avant"
        value={data.followersBefore}
        onChange={(n) => onChange({ ...data, followersBefore: n })}
      />
      <NumField
        label="Followers après"
        value={data.followersAfter}
        onChange={(n) => onChange({ ...data, followersAfter: n })}
      />
      <NumField
        label="Budget total dépensé (réel)"
        value={data.totalBudgetSpent}
        onChange={(n) => onChange({ ...data, totalBudgetSpent: n })}
      />

      <Text style={styles.sectionTitle}>Qualitatif</Text>
      <Field
        label="Ce qui a bien marché"
        value={data.whatWorked}
        onChangeText={(v) => onChange({ ...data, whatWorked: v })}
        multiline
      />
      <Field
        label="Ce qui n'a pas marché"
        value={data.whatDidnt}
        onChangeText={(v) => onChange({ ...data, whatDidnt: v })}
        multiline
      />
      <Field
        label="À faire différemment"
        value={data.nextTime}
        onChangeText={(v) => onChange({ ...data, nextTime: v })}
        multiline
      />

      <Text style={styles.sectionTitle}>Note globale</Text>
      <View style={styles.stars}>
        {[1, 2, 3, 4, 5].map((n) => (
          <Pressable key={n} onPress={() => onChange({ ...data, rating: n })}>
            <Ionicons
              name={n <= data.rating ? 'star' : 'star-outline'}
              size={32}
              color={n <= data.rating ? colors.soon : colors.textSecondary}
            />
          </Pressable>
        ))}
      </View>

      <Pressable style={styles.saveBtn} onPress={onSave} disabled={saving}>
        <Text style={styles.saveText}>{saving ? 'Enregistrement…' : 'Enregistrer le bilan'}</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
  sectionTitle: {
    color: colors.accentLight,
    fontSize: 14,
    fontWeight: '700',
    marginTop: spacing.lg,
    marginBottom: spacing.sm,
    letterSpacing: 0.5,
  },
  field: { marginBottom: spacing.md },
  label: { color: colors.textSecondary, fontSize: 13, marginBottom: spacing.xs },
  input: {
    backgroundColor: colors.background,
    borderRadius: radius.sm,
    padding: spacing.md,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  multiline: { minHeight: 80, textAlignVertical: 'top' },
  stars: { flexDirection: 'row', gap: spacing.sm, marginVertical: spacing.sm },
  saveBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.xl,
  },
  saveText: { color: colors.white, fontWeight: '700', fontSize: 16 },
});
