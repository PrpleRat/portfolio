import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';

import { CleanerProvider } from '../src/context/CleanerContext';
import { colors } from '../src/constants/theme';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1, backgroundColor: colors.bg }}>
      <CleanerProvider>
        <StatusBar style="light" />
        <Stack
          screenOptions={{
            headerStyle: { backgroundColor: colors.bg },
            headerTintColor: colors.text,
            headerTitleStyle: { fontWeight: '700' },
            contentStyle: { backgroundColor: colors.bg },
            headerShadowVisible: false,
          }}
        >
          <Stack.Screen name="index" options={{ title: 'Space Cleaner', headerLargeTitle: true }} />
          <Stack.Screen name="swipe" options={{ title: 'Trier' }} />
          <Stack.Screen name="heavy" options={{ title: 'Les plus lourds' }} />
          <Stack.Screen name="preview" options={{ title: 'Aperçu', presentation: 'modal' }} />
          <Stack.Screen name="queue" options={{ title: 'À supprimer' }} />
          <Stack.Screen name="files" options={{ title: 'Fichiers iPhone' }} />
        </Stack>
      </CleanerProvider>
    </GestureHandlerRootView>
  );
}
