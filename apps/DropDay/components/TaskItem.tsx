import { View, Text, Pressable, StyleSheet, Modal, TextInput, Alert } from 'react-native';
import { useState } from 'react';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import type { Task } from '@/types';
import { formatDate } from '@/types';
import { UrgencyBadge } from '@/components/UrgencyBadge';
import { getUrgencyLevel, urgencyLabel } from '@/utils/urgencyLevel';

interface TaskItemProps {
  task: Task;
  releaseTitle: string;
  onToggle: () => void;
  onAssign: (name: string | null) => void;
  onPostpone: (days: number) => void;
}

export function TaskItem({ task, releaseTitle, onToggle, onAssign, onPostpone }: TaskItemProps) {
  const [detailOpen, setDetailOpen] = useState(false);
  const [assignOpen, setAssignOpen] = useState(false);
  const [assignName, setAssignName] = useState(task.assignedTo ?? '');
  const level = getUrgencyLevel(task);

  return (
    <>
      <Pressable style={styles.row} onPress={() => setDetailOpen(true)}>
        <Pressable style={styles.check} onPress={onToggle} hitSlop={8}>
          <Ionicons
            name={task.completed ? 'checkmark-circle' : 'ellipse-outline'}
            size={24}
            color={task.completed ? colors.success : colors.textSecondary}
          />
        </Pressable>
        <View style={styles.content}>
          <View style={styles.titleRow}>
            {!task.completed && level !== 'future' && level !== 'done' && (
              <UrgencyBadge level={level} />
            )}
            {task.completed && <UrgencyBadge level="done" />}
            <Text
              style={[styles.title, task.completed && styles.titleDone]}
              numberOfLines={2}
            >
              {task.title}
            </Text>
          </View>
          <Text style={styles.meta}>
            Prévu {formatDate(task.dueDate)}
            {!task.completed && ` · ${urgencyLabel(task)}`}
            {task.completed && task.completedAt && ` · Complété le ${formatDate(task.completedAt)}`}
          </Text>
          {task.assignedTo && (
            <Text style={styles.assignee}>👤 {task.assignedTo}</Text>
          )}
        </View>
      </Pressable>

      <Modal visible={detailOpen} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modal}>
            <Text style={styles.modalTitle}>{task.title}</Text>
            <Text style={styles.modalRelease}>{releaseTitle}</Text>
            <Text style={styles.modalDesc}>{task.description}</Text>
            <Text style={styles.modalMeta}>
              Échéance : {formatDate(task.dueDate)}
              {task.daysOffset !== 0 &&
                ` · J${task.daysOffset >= 0 ? '+' : ''}${task.daysOffset}`}
            </Text>

            <Pressable style={styles.actionBtn} onPress={onToggle}>
              <Ionicons
                name={task.completed ? 'close-circle-outline' : 'checkmark-circle-outline'}
                size={20}
                color={colors.success}
              />
              <Text style={styles.actionText}>
                {task.completed ? 'Marquer non fait' : 'Marquer comme fait'}
              </Text>
            </Pressable>

            <Pressable
              style={styles.actionBtn}
              onPress={() => {
                setDetailOpen(false);
                setAssignOpen(true);
              }}
            >
              <Ionicons name="person-outline" size={20} color={colors.accentLight} />
              <Text style={styles.actionText}>Assigner un responsable</Text>
            </Pressable>

            <Pressable
              style={styles.actionBtn}
              onPress={() => {
                Alert.alert('Reporter', 'De combien de jours ?', [
                  { text: '3 jours', onPress: () => onPostpone(3) },
                  { text: '7 jours', onPress: () => onPostpone(7) },
                  { text: 'Annuler', style: 'cancel' },
                ]);
                setDetailOpen(false);
              }}
            >
              <Ionicons name="calendar-outline" size={20} color={colors.warning} />
              <Text style={styles.actionText}>Reporter</Text>
            </Pressable>

            <Pressable style={styles.closeBtn} onPress={() => setDetailOpen(false)}>
              <Text style={styles.closeText}>Fermer</Text>
            </Pressable>
          </View>
        </View>
      </Modal>

      <Modal visible={assignOpen} animationType="fade" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modal}>
            <Text style={styles.modalTitle}>Assigner</Text>
            <TextInput
              style={styles.input}
              value={assignName}
              onChangeText={setAssignName}
              placeholder="Nom (ingé, graphiste…)"
              placeholderTextColor={colors.textSecondary}
            />
            <Pressable
              style={styles.primaryBtn}
              onPress={() => {
                onAssign(assignName.trim() || null);
                setAssignOpen(false);
              }}
            >
              <Text style={styles.primaryText}>Enregistrer</Text>
            </Pressable>
            <Pressable style={styles.closeBtn} onPress={() => setAssignOpen(false)}>
              <Text style={styles.closeText}>Annuler</Text>
            </Pressable>
          </View>
        </View>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    gap: spacing.sm,
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.separator,
  },
  check: { paddingTop: 2 },
  content: { flex: 1 },
  titleRow: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.xs, alignItems: 'center' },
  title: { color: colors.text, fontSize: 15, fontWeight: '600', flex: 1 },
  titleDone: { textDecorationLine: 'line-through', color: colors.textSecondary },
  meta: { color: colors.textSecondary, fontSize: 12, marginTop: 4 },
  assignee: { color: colors.accentLight, fontSize: 12, marginTop: 4 },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.7)',
    justifyContent: 'flex-end',
  },
  modal: {
    backgroundColor: colors.card,
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
    padding: spacing.lg,
    maxHeight: '85%',
  },
  modalTitle: { color: colors.text, fontSize: 20, fontWeight: '700' },
  modalRelease: { color: colors.textSecondary, fontSize: 14, marginTop: 4 },
  modalDesc: { color: colors.text, fontSize: 15, lineHeight: 22, marginTop: spacing.md },
  modalMeta: { color: colors.textSecondary, fontSize: 13, marginTop: spacing.sm },
  actionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.separator,
  },
  actionText: { color: colors.text, fontSize: 16 },
  closeBtn: { alignItems: 'center', paddingVertical: spacing.md },
  closeText: { color: colors.textSecondary, fontSize: 16 },
  input: {
    backgroundColor: colors.background,
    borderRadius: radius.sm,
    padding: spacing.md,
    color: colors.text,
    marginTop: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  primaryBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.md,
  },
  primaryText: { color: colors.white, fontWeight: '700', fontSize: 16 },
});
