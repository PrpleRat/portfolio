import { Pressable } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { Ionicons } from '@expo/vector-icons';
import { ReleasesProvider } from '@/hooks/useReleases';
import { colors } from '@/constants/theme';

function HeaderHomeButton() {
  const router = useRouter();
  return (
    <Pressable
      onPress={() => router.replace('/')}
      hitSlop={12}
      style={{ flexDirection: 'row', alignItems: 'center', gap: 2, marginLeft: 4 }}
    >
      <Ionicons name="chevron-back" size={22} color={colors.accentLight} />
      <Ionicons name="home-outline" size={18} color={colors.accentLight} />
    </Pressable>
  );
}

export default function RootLayout() {
  return (
    <ReleasesProvider>
      <StatusBar style="light" />
      <Stack
        screenOptions={{
          headerStyle: { backgroundColor: colors.background },
          headerTintColor: colors.text,
          headerTitleStyle: { fontWeight: '600' },
          contentStyle: { backgroundColor: colors.background },
          headerBackTitle: 'Retour',
        }}
      >
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen
          name="new-release"
          options={{
            title: 'Nouvelle release',
            headerLeft: () => <HeaderHomeButton />,
          }}
        />
        <Stack.Screen name="release/[id]" options={{ headerShown: false }} />
      </Stack>
    </ReleasesProvider>
  );
}
