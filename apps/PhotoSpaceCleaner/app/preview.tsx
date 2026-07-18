import { Ionicons } from '@expo/vector-icons';
import { useEventListener } from 'expo';
import { Image } from 'expo-image';
import { router, useLocalSearchParams } from 'expo-router';
import { useVideoPlayer, VideoView } from 'expo-video';
import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { DownloadProgressBar } from '../src/components/DownloadProgressBar';
import { useCleaner } from '../src/context/CleanerContext';
import { colors } from '../src/constants/theme';
import {
  getLibraryAccess,
  openPhotoAccessSettings,
  prepareAssetForPreview,
  presentMorePhotosPicker,
} from '../src/services/mediaLibrary';
import type { EnrichedAsset } from '../src/types/media';
import { formatBytes, formatDate, formatDuration } from '../src/utils/format';

function VideoPlayer({
  uri,
  onLoadProgress,
  onError,
}: {
  uri: string;
  onLoadProgress: (progress: number, message: string) => void;
  onError: (message: string) => void;
}) {
  const player = useVideoPlayer(null, (p) => {
    p.loop = false;
  });

  useEffect(() => {
    let cancelled = false;

    (async () => {
      try {
        onLoadProgress(0.5, 'Préparation lecture…');
        await player.replaceAsync({ uri });
        if (!cancelled) {
          player.play();
        }
      } catch {
        if (!cancelled) {
          onError(
            Platform.OS === 'ios'
              ? 'Accès refusé à cette vidéo. Passe en « Accès complet » aux photos dans Réglages.'
              : 'Lecture impossible pour cette vidéo'
          );
        }
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [player, uri, onError, onLoadProgress]);

  useEventListener(player, 'statusChange', ({ status, error }) => {
    if (status === 'loading') {
      onLoadProgress(0.85, 'Buffer vidéo…');
    }
    if (status === 'readyToPlay') {
      onLoadProgress(1, 'Prêt');
    }
    if (status === 'error') {
      const msg = error?.message?.toLowerCase() ?? '';
      if (msg.includes('permission') || msg.includes('denied') || msg.includes('access')) {
        onError('Pas la permission de lire cette vidéo. Autorise l\'accès complet aux photos.');
      } else {
        onError(error?.message ?? 'Lecture impossible');
      }
    }
  });

  return (
    <VideoView
      player={player}
      style={styles.media}
      contentFit="contain"
      nativeControls
      fullscreenOptions={{ enable: true }}
    />
  );
}

export default function PreviewScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const insets = useSafeAreaInsets();
  const { addToQueue, queue } = useCleaner();
  const [item, setItem] = useState<EnrichedAsset | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [permissionIssue, setPermissionIssue] = useState(false);
  const [loadState, setLoadState] = useState({ progress: 0, message: 'Chargement…' });
  const [mediaReady, setMediaReady] = useState(false);

  const queued = item ? queue.some((q) => q.asset.id === item.asset.id) : false;
  const showProgress = loading || !mediaReady;

  const handleVideoError = useCallback((message: string) => {
    setPermissionIssue(
      message.toLowerCase().includes('permission') || message.toLowerCase().includes('accès')
    );
    setError(message);
    setMediaReady(false);
  }, []);

  useEffect(() => {
    let cancelled = false;

    (async () => {
      if (!id) {
        setError('Média introuvable');
        setLoading(false);
        return;
      }

      const access = await getLibraryAccess();
      if (!cancelled && access.accessPrivileges === 'limited') {
        setPermissionIssue(true);
      }

      const data = await prepareAssetForPreview(id, (state) => {
        if (!cancelled) setLoadState(state);
      });

      if (cancelled) return;

      if (!data) {
        setError('Impossible de charger ce média. Vérifie l\'accès aux photos.');
        setPermissionIssue(true);
        setLoading(false);
        return;
      }

      setItem(data);
      setLoading(false);

      if (data.asset.mediaType !== 'video') {
        setLoadState({ progress: 0.3, message: 'Affichage…' });
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [id]);

  const handleImageProgress = ({ loaded, total }: { loaded: number; total: number }) => {
    if (total <= 0) return;
    const fraction = 0.3 + 0.7 * (loaded / total);
    setLoadState({
      progress: fraction,
      message: loaded < total ? 'Téléchargement iCloud…' : 'Prêt',
    });
    if (loaded >= total) setMediaReady(true);
  };

  const handleVideoProgress = (progress: number, message: string) => {
    setLoadState({ progress, message });
    if (progress >= 1) setMediaReady(true);
  };

  if (error) {
    return (
      <View style={styles.center}>
        <Ionicons
          name={permissionIssue ? 'lock-closed-outline' : 'cloud-offline-outline'}
          size={48}
          color={colors.textMuted}
        />
        <Text style={styles.errorText}>{error}</Text>
        {permissionIssue && (
          <View style={styles.permissionActions}>
            <Pressable style={styles.permissionBtn} onPress={presentMorePhotosPicker}>
              <Text style={styles.permissionBtnText}>Ajouter cette vidéo à l'accès</Text>
            </Pressable>
            <Pressable style={styles.permissionBtnSecondary} onPress={openPhotoAccessSettings}>
              <Text style={styles.permissionBtnSecondaryText}>Accès complet (Réglages)</Text>
            </Pressable>
          </View>
        )}
        <Pressable style={styles.backBtn} onPress={() => router.back()}>
          <Text style={styles.backBtnText}>Retour</Text>
        </Pressable>
      </View>
    );
  }

  if (loading || !item) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={colors.accent} size="large" />
        <DownloadProgressBar progress={loadState.progress} label={loadState.message} />
      </View>
    );
  }

  const isVideo = item.asset.mediaType === 'video';

  return (
    <View style={[styles.container, { paddingBottom: insets.bottom }]}>
      {permissionIssue && (
        <Pressable style={styles.limitedBanner} onPress={openPhotoAccessSettings}>
          <Ionicons name="warning-outline" size={16} color={colors.warning} />
          <Text style={styles.limitedBannerText}>
            Accès photos limité — certaines vidéos peuvent être bloquées
          </Text>
        </Pressable>
      )}

      <View style={styles.mediaWrap}>
        {showProgress && (
          <View style={styles.progressOverlay}>
            <DownloadProgressBar progress={loadState.progress} label={loadState.message} />
          </View>
        )}

        {isVideo ? (
          <VideoPlayer
            uri={item.displayUri}
            onLoadProgress={handleVideoProgress}
            onError={handleVideoError}
          />
        ) : (
          <Image
            source={{ uri: item.displayUri }}
            style={styles.media}
            contentFit="contain"
            onProgress={handleImageProgress}
            onLoad={() => {
              setLoadState({ progress: 1, message: 'Prêt' });
              setMediaReady(true);
            }}
            onError={() => {
              setPermissionIssue(true);
              setError('Impossible d\'afficher cette photo — vérifie l\'accès complet aux photos');
            }}
          />
        )}
      </View>

      <View style={styles.meta}>
        <Text style={styles.size}>
          {formatBytes(item.sizeBytes)}
          {item.isEstimatedSize ? ' ≈' : ''}
        </Text>
        <Text style={styles.filename} numberOfLines={2}>
          {item.asset.filename}
        </Text>
        <Text style={styles.date}>
          {formatDate(item.asset.creationTime)}
          {isVideo ? ` · ${formatDuration(item.asset.duration)}` : ''}
          {item.isCloud ? ' · iCloud' : ''}
        </Text>
      </View>

      <View style={styles.actions}>
        <Pressable style={styles.secondaryAction} onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={20} color={colors.text} />
          <Text style={styles.secondaryActionText}>Retour</Text>
        </Pressable>
        <Pressable
          style={[styles.primaryAction, queued && styles.primaryActionDone]}
          onPress={() => {
            if (!queued) addToQueue(item);
          }}
        >
          <Ionicons name={queued ? 'checkmark' : 'trash'} size={20} color={colors.text} />
          <Text style={styles.primaryActionText}>
            {queued ? 'Dans la corbeille' : 'Supprimer'}
          </Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    gap: 16,
  },
  errorText: { color: colors.delete, textAlign: 'center', marginBottom: 8, lineHeight: 22 },
  permissionActions: { gap: 10, width: '100%', maxWidth: 320 },
  permissionBtn: {
    backgroundColor: colors.accent,
    padding: 14,
    borderRadius: 14,
    alignItems: 'center',
  },
  permissionBtnText: { color: colors.text, fontWeight: '700' },
  permissionBtnSecondary: {
    padding: 12,
    borderRadius: 14,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
  },
  permissionBtnSecondaryText: { color: colors.accent, fontWeight: '600' },
  limitedBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginHorizontal: 16,
    marginTop: 8,
    padding: 10,
    borderRadius: 10,
    backgroundColor: 'rgba(255,214,10,0.12)',
  },
  limitedBannerText: { color: colors.warning, fontSize: 12, flex: 1, fontWeight: '600' },
  backBtn: { padding: 12 },
  backBtnText: { color: colors.accent, fontWeight: '600' },
  mediaWrap: {
    flex: 1,
    backgroundColor: '#000',
    alignItems: 'center',
    justifyContent: 'center',
  },
  progressOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.75)',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 2,
    padding: 24,
  },
  media: { width: '100%', height: '100%' },
  meta: { padding: 16, gap: 4 },
  size: { color: colors.text, fontSize: 22, fontWeight: '800' },
  filename: { color: colors.textMuted, fontSize: 14 },
  date: { color: colors.textMuted, fontSize: 13 },
  actions: {
    flexDirection: 'row',
    gap: 12,
    paddingHorizontal: 16,
    paddingBottom: 8,
  },
  secondaryAction: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    padding: 14,
    borderRadius: 14,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
  },
  secondaryActionText: { color: colors.text, fontWeight: '600' },
  primaryAction: {
    flex: 1.4,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    padding: 14,
    borderRadius: 14,
    backgroundColor: colors.delete,
  },
  primaryActionDone: { backgroundColor: colors.surfaceLight },
  primaryActionText: { color: colors.text, fontWeight: '700' },
});
