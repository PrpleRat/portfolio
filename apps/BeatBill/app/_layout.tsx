import { Pressable } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { Ionicons } from '@expo/vector-icons';
import { AppDataProvider } from '@/hooks/useAppData';
import { useBeatDealInvoiceLink } from '@/hooks/useDeepLink';
import { colors } from '@/constants/theme';

function DeepLinkListener() {
  useBeatDealInvoiceLink();
  return null;
}

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
      <DeepLinkListener />
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
          name="new-invoice"
          options={{
            title: 'Nouvelle facture',
            headerShown: true,
            headerLeft: () => <HeaderHomeButton />,
          }}
        />
        <Stack.Screen
          name="invoice-preview"
          options={{
            title: 'Aperçu PDF',
            headerLeft: () => <HeaderHomeButton />,
          }}
        />
        <Stack.Screen name="invoice-detail" options={{ title: 'Détail facture' }} />
        <Stack.Screen name="client-detail" options={{ title: 'Client' }} />
        <Stack.Screen
          name="new-quote"
          options={{ title: 'Nouveau devis', headerLeft: () => <HeaderHomeButton /> }}
        />
        <Stack.Screen
          name="quote-preview"
          options={{ title: 'Aperçu devis', headerLeft: () => <HeaderHomeButton /> }}
        />
        <Stack.Screen name="quote-detail" options={{ title: 'Détail devis' }} />
        <Stack.Screen name="search" options={{ title: 'Recherche' }} />
        <Stack.Screen name="contracts" options={{ title: 'Contrats & riders' }} />
        <Stack.Screen name="contract-preview" options={{ title: 'Aperçu contrat' }} />
        <Stack.Screen name="catalog" options={{ title: 'Catalogue services' }} />
        <Stack.Screen name="recurring" options={{ title: 'Factures récurrentes' }} />
      </Stack>
    </AppDataProvider>
  );
}
