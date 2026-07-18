import { Pressable } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { Ionicons } from '@expo/vector-icons';
import { AppDataProvider } from '@/hooks/useAppData';
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
    <AppDataProvider>
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
          name="new-split"
          options={{
            title: 'Nouveau split',
            headerShown: true,
            headerLeft: () => <HeaderHomeButton />,
          }}
        />
        <Stack.Screen
          name="split-preview"
          options={{
            title: 'Aperçu PDF',
            headerLeft: () => <HeaderHomeButton />,
          }}
        />
        <Stack.Screen name="split-detail" options={{ title: 'Détail split' }} />
      </Stack>
    </AppDataProvider>
  );
}
