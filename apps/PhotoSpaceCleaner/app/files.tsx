import { Ionicons } from '@expo/vector-icons';
import { Linking, ScrollView, StyleSheet, Text, View } from 'react-native';

import { colors } from '../src/constants/theme';

const LIMITATIONS = [
  {
    icon: 'checkmark-circle' as const,
    color: colors.keep,
    title: 'Ce que l\'app peut faire',
    items: [
      'Parcourir photos & vidéos (locale + iCloud dans la photothèque)',
      'Afficher la taille estimée ou réelle de chaque média',
      'Supprimer définitivement après validation',
      'Cibler captures d\'écran, vidéos, Live Photos',
    ],
  },
  {
    icon: 'close-circle' as const,
    color: colors.delete,
    title: 'Ce qu\'iOS bloque (toutes les apps)',
    items: [
      'Scanner les fichiers des autres apps (WhatsApp, Safari, Mail…)',
      'Vider le cache système ou des apps tierces',
      'Accéder au dossier Fichiers / Downloads sans que tu les sélectionnes',
      'Voir la taille exacte des médias uniquement sur iCloud (sans les télécharger)',
    ],
  },
];

const TIPS = [
  'Réglages → Général → Stockage iPhone : voir quelles apps prennent le plus de place',
  'Réglages → Photos → Optimiser le stockage : garde des miniatures, full résolution sur iCloud',
  'Messages : supprimer vieilles pièces jointes dans une conversation',
  'Safari : effacer historique et données (Réglages → Safari)',
  'Offloader des apps inutilisées (garde les données, enlève l\'app)',
];

export default function FilesScreen() {
  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.hero}>
        <Ionicons name="shield-checkmark-outline" size={40} color={colors.accent} />
        <Text style={styles.heroTitle}>Nettoyage réel vs promesses marketing</Text>
        <Text style={styles.heroBody}>
          Les apps « cleaner » du App Store ne peuvent pas magiquement tout scanner. Apple verrouille l'accès aux
          fichiers internes. Cette app se concentre sur ce qui marche vraiment : ta photothèque — souvent 30 à 70 %
          du stockage.
        </Text>
      </View>

      {LIMITATIONS.map((block) => (
        <View key={block.title} style={styles.block}>
          <View style={styles.blockHeader}>
            <Ionicons name={block.icon} size={22} color={block.color} />
            <Text style={styles.blockTitle}>{block.title}</Text>
          </View>
          {block.items.map((item) => (
            <Text key={item} style={styles.bullet}>
              · {item}
            </Text>
          ))}
        </View>
      ))}

      <View style={styles.block}>
        <Text style={styles.blockTitle}>Astuces manuelles iPhone</Text>
        {TIPS.map((tip) => (
          <Text key={tip} style={styles.bullet}>
            · {tip}
          </Text>
        ))}
      </View>

      <Text
        style={styles.link}
        onPress={() => Linking.openURL('App-prefs:STORAGE_MGMT')}
      >
        Ouvrir Réglages → Stockage (si iOS le permet)
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: { padding: 16, paddingBottom: 40 },
  hero: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 18,
    borderWidth: 1,
    borderColor: colors.border,
    marginBottom: 16,
    alignItems: 'flex-start',
  },
  heroTitle: { color: colors.text, fontSize: 18, fontWeight: '800', marginTop: 10 },
  heroBody: { color: colors.textMuted, lineHeight: 22, marginTop: 8, fontSize: 14 },
  block: {
    backgroundColor: colors.surface,
    borderRadius: 14,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: colors.border,
  },
  blockHeader: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 10 },
  blockTitle: { color: colors.text, fontWeight: '700', fontSize: 16 },
  bullet: { color: colors.textMuted, lineHeight: 22, marginBottom: 4, fontSize: 14 },
  link: {
    color: colors.accent,
    textAlign: 'center',
    marginTop: 8,
    fontWeight: '600',
    textDecorationLine: 'underline',
  },
});
