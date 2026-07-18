import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import * as Haptics from 'expo-haptics';
import { useEventListener } from 'expo';
import { useVideoPlayer, VideoView } from 'expo-video';
import React, { useEffect, useState } from 'react';
import { Dimensions, Pressable, StyleSheet, Text, View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  Extrapolation,
  interpolate,
  runOnJS,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

import { colors } from '../constants/theme';
import type { EnrichedAsset } from '../types/media';
import { formatBytes, formatDate, formatDuration } from '../utils/format';

const { width: SCREEN_W } = Dimensions.get('window');
const CARD_W = SCREEN_W - 32;
const SWIPE_THRESHOLD = SCREEN_W * 0.28;

type Props = {
  item: EnrichedAsset;
  onDelete: () => void;
  onKeep: () => void;
  isTop: boolean;
};

function SwipeVideo({ uri, active }: { uri: string; active: boolean }) {
  const [ready, setReady] = useState(false);
  const [error, setError] = useState(false);
  const player = useVideoPlayer(null, (p) => {
    p.loop = false;
    p.muted = false;
  });

  useEffect(() => {
    let cancelled = false;
    setReady(false);
    setError(false);

    if (!active) return;

    (async () => {
      try {
        await player.replaceAsync({ uri });
        if (!cancelled) {
          setReady(true);
          player.play();
        }
      } catch {
        if (!cancelled) setError(true);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [uri, active, player]);

  useEventListener(player, 'statusChange', ({ status }) => {
    if (status === 'readyToPlay') setReady(true);
    if (status === 'error') setError(true);
  });

  if (error) {
    return (
      <View style={styles.videoFallback}>
        <Ionicons name="videocam-off-outline" size={40} color={colors.textMuted} />
        <Text style={styles.videoFallbackText}>Vidéo inaccessible</Text>
      </View>
    );
  }

  return (
    <View style={styles.videoWrap}>
      {!ready && (
        <View style={styles.videoLoading}>
          <Ionicons name="hourglass-outline" size={28} color={colors.textMuted} />
        </View>
      )}
      <VideoView
        player={player}
        style={styles.image}
        contentFit="cover"
        nativeControls={active}
        fullscreenOptions={{ enable: active }}
      />
    </View>
  );
}

export function SwipeCard({ item, onDelete, onKeep, isTop }: Props) {
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);
  const [resolved, setResolved] = useState(item);
  const [videoPlaying, setVideoPlaying] = useState(false);

  useEffect(() => {
    setResolved(item);
    setVideoPlaying(false);
    translateX.value = 0;
    translateY.value = 0;
  }, [item.asset.id, translateX, translateY]);

  const finish = (direction: 'left' | 'right') => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    if (direction === 'left') onDelete();
    else onKeep();
  };

  const pan = Gesture.Pan()
    .enabled(isTop && !videoPlaying)
    .onUpdate((e) => {
      translateX.value = e.translationX;
      translateY.value = e.translationY * 0.15;
    })
    .onEnd((e) => {
      if (e.translationX < -SWIPE_THRESHOLD) {
        translateX.value = withTiming(-SCREEN_W * 1.2, { duration: 220 }, () => {
          runOnJS(finish)('left');
        });
        return;
      }
      if (e.translationX > SWIPE_THRESHOLD) {
        translateX.value = withTiming(SCREEN_W * 1.2, { duration: 220 }, () => {
          runOnJS(finish)('right');
        });
        return;
      }
      translateX.value = withSpring(0);
      translateY.value = withSpring(0);
    });

  const cardStyle = useAnimatedStyle(() => ({
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value },
      {
        rotate: `${interpolate(translateX.value, [-SCREEN_W, 0, SCREEN_W], [-12, 0, 12], Extrapolation.CLAMP)}deg`,
      },
    ],
  }));

  const deleteOverlay = useAnimatedStyle(() => ({
    opacity: interpolate(translateX.value, [-SWIPE_THRESHOLD, -40], [1, 0], Extrapolation.CLAMP),
  }));

  const keepOverlay = useAnimatedStyle(() => ({
    opacity: interpolate(translateX.value, [40, SWIPE_THRESHOLD], [0, 1], Extrapolation.CLAMP),
  }));

  const { asset } = resolved;
  const isVideo = asset.mediaType === 'video';
  const videoUri = asset.uri;

  return (
    <GestureDetector gesture={pan}>
      <Animated.View style={[styles.card, cardStyle, !isTop && styles.cardBehind]}>
        {isVideo ? (
          videoPlaying && isTop ? (
            <SwipeVideo uri={videoUri} active={isTop} />
          ) : (
            <Pressable
              style={styles.videoPoster}
              onPress={() => {
                if (isTop) {
                  Haptics.selectionAsync();
                  setVideoPlaying(true);
                }
              }}
            >
              <Image source={{ uri: videoUri }} style={styles.image} contentFit="cover" />
              <View style={styles.playOverlay}>
                <Ionicons name="play-circle" size={72} color="rgba(255,255,255,0.92)" />
                <Text style={styles.playLabel}>Lire la vidéo</Text>
              </View>
            </Pressable>
          )
        ) : (
          <Image source={{ uri: resolved.displayUri }} style={styles.image} contentFit="cover" />
        )}

        <Animated.View style={[styles.badge, styles.deleteBadge, deleteOverlay]}>
          <Text style={styles.badgeText}>SUPPRIMER</Text>
        </Animated.View>
        <Animated.View style={[styles.badge, styles.keepBadge, keepOverlay]}>
          <Text style={styles.badgeText}>GARDER</Text>
        </Animated.View>

        <View style={styles.infoBar}>
          <View style={styles.infoRow}>
            <Text style={styles.sizeText}>{formatBytes(resolved.sizeBytes)}</Text>
            {resolved.isEstimatedSize && <Text style={styles.estimated}>≈</Text>}
            {resolved.isCloud && (
              <View style={styles.cloudPill}>
                <Text style={styles.cloudText}>iCloud</Text>
              </View>
            )}
            {isVideo && (
              <View style={styles.videoPill}>
                <Text style={styles.videoText}>{formatDuration(asset.duration)}</Text>
              </View>
            )}
          </View>
          <Text style={styles.meta} numberOfLines={1}>
            {formatDate(asset.creationTime)} · {asset.filename}
          </Text>
        </View>
      </Animated.View>
    </GestureDetector>
  );
}

const styles = StyleSheet.create({
  card: {
    position: 'absolute',
    width: CARD_W,
    height: CARD_W * 1.35,
    borderRadius: 24,
    overflow: 'hidden',
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    alignSelf: 'center',
  },
  cardBehind: {
    transform: [{ scale: 0.96 }],
    opacity: 0.7,
  },
  image: {
    flex: 1,
    width: '100%',
  },
  videoWrap: {
    flex: 1,
    backgroundColor: '#000',
  },
  videoPoster: {
    flex: 1,
    backgroundColor: '#000',
  },
  videoLoading: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 1,
  },
  videoFallback: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: colors.surface,
  },
  videoFallbackText: { color: colors.textMuted },
  playOverlay: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(0,0,0,0.35)',
    gap: 8,
  },
  playLabel: {
    color: colors.text,
    fontWeight: '700',
    fontSize: 15,
  },
  badge: {
    position: 'absolute',
    top: 24,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 10,
    borderWidth: 3,
  },
  deleteBadge: {
    left: 20,
    borderColor: colors.delete,
    backgroundColor: 'rgba(255,69,58,0.15)',
  },
  keepBadge: {
    right: 20,
    borderColor: colors.keep,
    backgroundColor: 'rgba(48,209,88,0.15)',
  },
  badgeText: {
    color: colors.text,
    fontWeight: '800',
    fontSize: 15,
    letterSpacing: 1,
  },
  infoBar: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    padding: 16,
    backgroundColor: 'rgba(10,10,15,0.82)',
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 4,
  },
  sizeText: {
    color: colors.text,
    fontSize: 22,
    fontWeight: '700',
  },
  estimated: {
    color: colors.textMuted,
    fontSize: 16,
  },
  cloudPill: {
    backgroundColor: 'rgba(100,210,255,0.2)',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  cloudText: {
    color: colors.cloud,
    fontSize: 12,
    fontWeight: '600',
  },
  videoPill: {
    backgroundColor: 'rgba(255,214,10,0.2)',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  videoText: {
    color: colors.warning,
    fontSize: 12,
    fontWeight: '600',
  },
  meta: {
    color: colors.textMuted,
    fontSize: 13,
  },
});
