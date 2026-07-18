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
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, radius, spacing } from '@/constants/theme';
import { useContracts, useProfile } from '@/hooks/useAppData';
import { uuid } from '@/utils/uuid';
import type { ContractTemplate } from '@/types';

export default function ContractsScreen() {
  const router = useRouter();
  const { contracts, saveContract, deleteContract } = useContracts();
  const { profile } = useProfile();
  const [fillModal, setFillModal] = useState<ContractTemplate | null>(null);
  const [client, setClient] = useState('');
  const [emailClient, setEmailClient] = useState('');
  const [projet, setProjet] = useState('');
  const [montant, setMontant] = useState('');
  const [streams, setStreams] = useState('50000');

  const openFill = (template: ContractTemplate) => {
    setFillModal(template);
    setClient('');
    setEmailClient('');
    setProjet('');
    setMontant('');
  };

  const generate = () => {
    if (!fillModal || !client.trim()) {
      Alert.alert('Champs requis', 'Nom du client obligatoire.');
      return;
    }
    router.push({
      pathname: '/contract-preview',
      params: {
        title: fillModal.title,
        body: fillModal.body,
        vars: JSON.stringify({
          producteur: profile.name || 'Producteur',
          email_producteur: profile.email,
          client: client.trim(),
          email_client: emailClient.trim(),
          projet: projet.trim() || '—',
          montant: montant.trim() || '—',
          streams: streams.trim(),
          date: new Date().toLocaleDateString('fr-FR'),
        }),
      },
    });
    setFillModal(null);
  };

  const handleAddCustom = () => {
    Alert.prompt?.(
      'Nouveau contrat',
      'Titre du modèle',
      (title) => {
        if (!title?.trim()) return;
        const contract: ContractTemplate = {
          id: uuid(),
          title: title.trim(),
          type: 'custom',
          body: `CONTRAT — {{projet}}

Entre {{producteur}} ({{email_producteur}})
Et {{client}} ({{email_client}})

Montant : {{montant}}

Fait le {{date}}`,
        };
        saveContract(contract);
      }
    );
    if (!Alert.prompt) {
      const contract: ContractTemplate = {
        id: uuid(),
        title: 'Mon contrat personnalisé',
        type: 'custom',
        body: `CONTRAT

Entre {{producteur}} et {{client}}
Objet : {{projet}}
Montant : {{montant}}

Fait le {{date}}`,
      };
      saveContract(contract);
      Alert.alert('Créé', 'Modèle « Mon contrat personnalisé » ajouté.');
    }
  };

  return (
    <>
      <ScrollView style={styles.container} contentContainerStyle={styles.content}>
        <Text style={styles.intro}>
          Modèles de contrats et riders pour beats, sessions et cessions exclusives.
        </Text>

        {contracts.map((c) => (
          <View key={c.id} style={styles.card}>
            <View style={styles.cardHeader}>
              <Ionicons name="document-attach-outline" size={22} color={colors.accent} />
              <View style={styles.cardInfo}>
                <Text style={styles.cardTitle}>{c.title}</Text>
                <Text style={styles.cardType}>
                  {c.isBuiltin ? 'Modèle intégré' : 'Personnalisé'}
                </Text>
              </View>
            </View>
            <View style={styles.cardActions}>
              <Pressable style={styles.btn} onPress={() => openFill(c)}>
                <Text style={styles.btnText}>Générer PDF</Text>
              </Pressable>
              {!c.isBuiltin && (
                <Pressable
                  style={[styles.btn, styles.btnDanger]}
                  onPress={() =>
                    Alert.alert('Supprimer', 'Supprimer ce modèle ?', [
                      { text: 'Annuler', style: 'cancel' },
                      { text: 'Supprimer', style: 'destructive', onPress: () => deleteContract(c.id) },
                    ])
                  }
                >
                  <Text style={styles.btnTextDanger}>Supprimer</Text>
                </Pressable>
              )}
            </View>
          </View>
        ))}

        <Pressable style={styles.addBtn} onPress={handleAddCustom}>
          <Ionicons name="add-circle-outline" size={22} color={colors.accentLight} />
          <Text style={styles.addBtnText}>Ajouter un modèle personnalisé</Text>
        </Pressable>
      </ScrollView>

      <Modal visible={!!fillModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <Text style={styles.modalTitle}>{fillModal?.title}</Text>
            <Field label="Client *" value={client} onChange={setClient} />
            <Field label="Email client" value={emailClient} onChange={setEmailClient} keyboardType="email-address" />
            <Field label="Projet / beat" value={projet} onChange={setProjet} />
            <Field label="Montant" value={montant} onChange={setMontant} placeholder="350 €" />
            {fillModal?.type === 'beat_lease' && (
              <Field label="Streams max" value={streams} onChange={setStreams} />
            )}
            <Pressable style={styles.generateBtn} onPress={generate}>
              <Text style={styles.generateBtnText}>Aperçu PDF</Text>
            </Pressable>
            <Pressable style={styles.modalClose} onPress={() => setFillModal(null)}>
              <Text style={styles.modalCloseText}>Annuler</Text>
            </Pressable>
          </View>
        </View>
      </Modal>
    </>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  keyboardType,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  keyboardType?: 'default' | 'email-address';
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        style={styles.input}
        value={value}
        onChangeText={onChange}
        placeholder={placeholder}
        placeholderTextColor={colors.textSecondary}
        keyboardType={keyboardType}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.lg, paddingBottom: spacing.xl * 2 },
  intro: { color: colors.textSecondary, fontSize: 14, marginBottom: spacing.lg, lineHeight: 20 },
  card: {
    backgroundColor: colors.card,
    borderRadius: radius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  cardHeader: { flexDirection: 'row', gap: spacing.md, marginBottom: spacing.md },
  cardInfo: { flex: 1 },
  cardTitle: { color: colors.text, fontSize: 16, fontWeight: '700' },
  cardType: { color: colors.textSecondary, fontSize: 12, marginTop: 2 },
  cardActions: { flexDirection: 'row', gap: spacing.sm },
  btn: {
    flex: 1,
    padding: spacing.sm,
    borderRadius: radius.sm,
    backgroundColor: colors.accent,
    alignItems: 'center',
  },
  btnText: { color: colors.background, fontWeight: '700', fontSize: 13 },
  btnDanger: { backgroundColor: 'transparent', borderWidth: 1, borderColor: colors.error },
  btnTextDanger: { color: colors.error, fontWeight: '600', fontSize: 13 },
  addBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.sm,
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.separator,
    borderRadius: radius.md,
    borderStyle: 'dashed',
  },
  addBtnText: { color: colors.accentLight, fontWeight: '600' },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.8)', justifyContent: 'flex-end' },
  modalSheet: {
    backgroundColor: colors.card,
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
    padding: spacing.lg,
  },
  modalTitle: { color: colors.text, fontSize: 18, fontWeight: '700', marginBottom: spacing.md },
  field: { marginBottom: spacing.md },
  label: { color: colors.textSecondary, fontSize: 12, marginBottom: spacing.xs },
  input: {
    backgroundColor: colors.section,
    borderRadius: radius.sm,
    padding: spacing.md,
    color: colors.text,
    borderWidth: 1,
    borderColor: colors.separator,
  },
  generateBtn: {
    backgroundColor: colors.accent,
    borderRadius: radius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.sm,
  },
  generateBtnText: { color: colors.background, fontWeight: '700' },
  modalClose: { padding: spacing.md, alignItems: 'center' },
  modalCloseText: { color: colors.textSecondary, fontWeight: '600' },
});
