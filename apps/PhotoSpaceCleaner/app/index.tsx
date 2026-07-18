import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import * as FileSystem from 'expo-file-system/legacy';

import { ActionCard } from '../src/components/ActionCard';
import { useCleaner } from '../src/context/CleanerContext';
import { colors } from '../src/constants/theme';
import { loadLibraryStats, openPhotoAccessSettings, presentMorePhotosPicker, requestLibraryAccess, getLibraryAccess } from '../src/services/mediaLibrary';
import { formatBytes } from '../src/utils/format';

export default function HomeScreen() {
  const { queue, queueSizeBytes } = useCleaner();
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [permissionDenied, setPermissionDenied] = useState(false);
  const [stats, setStats] = useState<{
    photoCount: number;
    videoCount: number;
    albumCount: number;
    cloudOnDevice: number;
    cloudScanned: number;
  } | null>(null);
  const [accessLimited, setAccessLimited] = useState(false);
  const [disk, setDisk] = useState<{ free: number; total: number } | null>(null);

  const load = useCallback(async () => {
    const granted = await requestLibraryAccess();
    if (!granted) {
      setPermissionDenied(true);
      setLoading(false);
      return;
    }
    setPermissionDenied(false);

    const access = await getLibraryAccess();
    setAccessLimited(access.accessPrivileges === 'limited');

    const [libraryStats, free, total] = await Promise.all([
      loadLibraryStats(),
      FileSystem.getFreeDiskStorageAsync(),
      FileSystem.getTotalDiskCapacityAsync(),
    ]);

    setStats(libraryStats);
    setDisk({ free, total });
    setLoading(false);
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const onRefresh = async () => {
    setRefreshing(true);
    await load();
    setRefreshing(false);
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.accent} />
        <Text style={styles.loadingText}>Analyse de ta photothèque…</Text>
      </View>
    );
  }

  if (permissionDenied) {
    return (
      <View style={styles.center}>
        <Ionicons name="images-outline" size={56} color={colors.textMuted} />
        <Text style={styles.deniedTitle}>Accès photos requis</Text>
        <Text style={styles.deniedBody}>
          Pour trier et libérer de l'espace, autorise l'accès à toutes tes photos dans les réglages iOS.
        </Text>
        <Pressable style={styles.primaryBtn} onPress={load}>
          <Text style={styles.primaryBtnText}>Réessayer</Text>
        </Pressable>
      </View>
    );
  }

  const usedPercent = disk ? Math.round(((disk.total - disk.free) / disk.total) * 100) : 0;

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={colors.accent} />}
    >
      {accessLimited && (
        <Pressable style={styles.warningBanner} onPress={openPhotoAccessSettings}>
          <Ionicons name="warning-outline" size={22} color={colors.warning} />
          <View style={styles.warningTextWrap}>
            <Text style={styles.warningTitle}>Accès photos limité</Text>
            <Text style={styles.warningBody}>
              iOS ne montre qu'une sélection. Passe en « Accès complet » pour voir toute la photothèque iCloud.
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={18} color={colors.warning} />
        </Pressable>
      )}

      {disk && (
        <LinearGradient colors={['#1a1a2e', colors.surface]} style={styles.diskCard}>
          <Text style={styles.diskLabel}>Stockage iPhone</Text>
          <Text style={styles.diskFree}>{formatBytes(disk.free)} libres</Text>
          <Text style={styles.diskSub}>
            {formatBytes(disk.total - disk.free)} utilisés sur {formatBytes(disk.total)} ({usedPercent}%)
          </Text>
          <View style={styles.progressTrack}>
            <View style={[styles.progressFill, { width: `${usedPercent}%` }]} />
          </View>
        </LinearGradient>
      )}

      {stats && (
        <>
          <View style={styles.statsRow}>
            <StatBox label="Photos" value={stats.photoCount.toLocaleString('fr-FR')} />
            <StatBox label="Vidéos" value={stats.videoCount.toLocaleString('fr-FR')} />
            <StatBox label="Albums" value={stats.albumCount.toLocaleString('fr-FR')} />
          </View>
          {stats.cloudOnDevice > 0 && (
            <View style={styles.cloudStat}>
              <Ionicons name="cloud-outline" size={18} color={colors.cloud} />
              <Text style={styles.cloudStatText}>
                {stats.cloudOnDevice} sur iCloud uniquement (échantillon {stats.cloudScanned} photos)
              </Text>
            </View>
          )}
        </>
      )}

      <Text style={styles.section}>À la une</Text>
      <ActionCard
        title="Mode aléatoire"
        subtitle="Découvre des photos au hasard — comme Tinder pour ta galerie"
        icon="shuffle"
        filter="random"
        accent="#FF6B9D"
      />
      <ActionCard
        title="Doublons probables"
        subtitle="Même taille + prises à quelques secondes d'écart"
        icon="copy-outline"
        filter="duplicates"
        accent="#FF9F0A"
      />
      <ActionCard
        title="iCloud uniquement"
        subtitle="Pas stockées sur l'iPhone — gros levier d'espace"
        icon="cloud-outline"
        filter="icloud"
        accent={colors.cloud}
      />

      <Text style={styles.section}>Trier en swipant</Text>
      <ActionCard
        title="Tout trier"
        subtitle="Swipe gauche = supprimer, droite = garder"
        icon="swap-horizontal"
        filter="all"
        shuffle
        accent={colors.accent}
      />
      <ActionCard
        title="Ce mois-ci"
        subtitle="Photos & vidéos des 30 derniers jours"
        icon="calendar-outline"
        filter="recent"
        accent="#30D158"
      />
      <ActionCard
        title="Captures d'écran"
        subtitle="Souvent les plus faciles à virer"
        icon="phone-portrait-outline"
        filter="screenshots"
        accent={colors.warning}
      />
      <ActionCard
        title="Vidéos"
        subtitle="Les vidéos prennent le plus de place"
        icon="videocam-outline"
        filter="videos"
        accent={colors.delete}
      />
      <ActionCard
        title="Grosses vidéos"
        subtitle="45 s+ ou ~40 Mo+ — priorité espace"
        icon="film-outline"
        filter="large_videos"
        accent="#FF453A"
      />
      <ActionCard
        title="Live Photos"
        subtitle="Photo + vidéo courte = double poids"
        icon="aperture-outline"
        filter="live"
        accent={colors.cloud}
      />
      <ActionCard
        title="Panoramas"
        subtitle="Images très larges, souvent lourdes"
        icon="scan-outline"
        filter="panoramas"
        accent="#64D2FF"
      />
      <ActionCard
        title="Timelapse"
        subtitle="Vidéos accélérées souvent oubliées"
        icon="timer-outline"
        filter="timelapse"
        accent="#BF5AF2"
      />
      <ActionCard
        title="Enregistrements écran"
        subtitle="Screen recordings iOS"
        icon="desktop-outline"
        filter="screen_recordings"
        accent="#AC8E68"
      />
      <ActionCard
        title="Plus d'1 an"
        subtitle="Souvenirs anciens — tri nostalgique"
        icon="time-outline"
        filter="old"
        accent={colors.textMuted}
      />
      <ActionCard
        title="Photos seules"
        subtitle="Sans les vidéos"
        icon="image-outline"
        filter="photos"
        shuffle
        accent="#5E5CE6"
      />

      <Text style={styles.section}>Libérer vite</Text>
      <ActionCard
        title="Les fichiers les plus lourds"
        subtitle="Top photos & vidéos par taille"
        icon="bar-chart-outline"
        route="/heavy"
        accent="#BF5AF2"
      />
      <ActionCard
        title="Corbeille de suppression"
        subtitle={
          queue.length
            ? `${queue.length} élément(s) · ~${formatBytes(queueSizeBytes)} à libérer`
            : "Rien en attente pour l'instant"
        }
        icon="trash-outline"
        route="/queue"
        accent={colors.delete}
        badge={queue.length ? String(queue.length) : undefined}
      />
      <ActionCard
        title="Fichiers iPhone (limites iOS)"
        subtitle="Ce qu'on peut (et ne peut pas) nettoyer"
        icon="folder-open-outline"
        route="/files"
        accent={colors.textMuted}
      />

      <Pressable style={styles.linkBtn} onPress={presentMorePhotosPicker}>
        <Ionicons name="add-circle-outline" size={18} color={colors.accent} />
        <Text style={styles.linkText}>Donner accès à plus de photos</Text>
      </Pressable>

      <View style={styles.tip}>
        <Text style={styles.tipTitle}>💡 iCloud</Text>
        <Text style={styles.tipBody}>
          Avec « Optimiser le stockage iPhone » activé, beaucoup de photos sont sur iCloud seulement. L'app les
          télécharge temporairement pour les afficher. Les supprimer les retire de ta bibliothèque (iCloud inclus).
        </Text>
      </View>
    </ScrollView>
  );
}

function StatBox({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.statBox}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: { padding: 16, paddingBottom: 40 },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 32,
    backgroundColor: colors.bg,
  },
  loadingText: { color: colors.textMuted, marginTop: 16 },
  deniedTitle: { color: colors.text, fontSize: 22, fontWeight: '700', marginTop: 16, textAlign: 'center' },
  deniedBody: { color: colors.textMuted, textAlign: 'center', marginTop: 8, lineHeight: 22 },
  primaryBtn: {
    marginTop: 24,
    backgroundColor: colors.accent,
    paddingHorizontal: 24,
    paddingVertical: 14,
    borderRadius: 14,
  },
  primaryBtnText: { color: colors.text, fontWeight: '700', fontSize: 16 },
  warningBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: 'rgba(255,214,10,0.12)',
    borderRadius: 14,
    padding: 14,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: 'rgba(255,214,10,0.35)',
  },
  warningTextWrap: { flex: 1 },
  warningTitle: { color: colors.warning, fontWeight: '800', marginBottom: 4 },
  warningBody: { color: colors.textMuted, fontSize: 13, lineHeight: 18 },
  cloudStat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 8,
    paddingHorizontal: 4,
  },
  cloudStatText: { color: colors.cloud, fontSize: 13, fontWeight: '600' },
  diskCard: {
    borderRadius: 20,
    padding: 20,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: colors.border,
  },
  diskLabel: { color: colors.textMuted, fontSize: 13, marginBottom: 4 },
  diskFree: { color: colors.text, fontSize: 32, fontWeight: '800' },
  diskSub: { color: colors.textMuted, marginTop: 4, marginBottom: 12 },
  progressTrack: {
    height: 8,
    backgroundColor: colors.surfaceLight,
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.accent,
    borderRadius: 4,
  },
  statsRow: { flexDirection: 'row', gap: 10, marginBottom: 8 },
  statBox: {
    flex: 1,
    backgroundColor: colors.surface,
    borderRadius: 14,
    padding: 14,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
  },
  statValue: { color: colors.text, fontSize: 18, fontWeight: '700' },
  statLabel: { color: colors.textMuted, fontSize: 12, marginTop: 2 },
  section: {
    color: colors.textMuted,
    fontSize: 13,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 0.8,
    marginTop: 20,
    marginBottom: 10,
  },
  linkBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    marginTop: 8,
    padding: 12,
  },
  linkText: { color: colors.accent, fontWeight: '600' },
  tip: {
    marginTop: 16,
    padding: 16,
    backgroundColor: colors.surface,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: colors.border,
  },
  tipTitle: { color: colors.text, fontWeight: '700', marginBottom: 6 },
  tipBody: { color: colors.textMuted, lineHeight: 20, fontSize: 14 },
});
