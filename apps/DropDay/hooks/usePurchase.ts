import { useCallback, useEffect, useState } from 'react';
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Constants from 'expo-constants';
import { STORAGE_KEYS, FREE_RELEASE_LIMIT, PRO_PRODUCT_ID } from '@/constants/theme';
import { isExpoGo } from '@/utils/expoGo';

let Purchases: typeof import('react-native-purchases').default | null = null;

try {
  Purchases = require('react-native-purchases').default;
} catch {
  Purchases = null;
}

const RC_API_KEY_IOS = 'appl_DROPPLACEHOLDER';

export function usePurchase(releaseCount: number) {
  const [isPro, setIsPro] = useState(false);
  const [loading, setLoading] = useState(true);
  const [priceLabel, setPriceLabel] = useState('4,99 €');

  const refreshProStatus = useCallback(async () => {
    const stored = await AsyncStorage.getItem(STORAGE_KEYS.isPro);
    if (stored === 'true') {
      setIsPro(true);
      return true;
    }

    if (Purchases && Platform.OS === 'ios' && !isExpoGo()) {
      try {
        const info = await Purchases.getCustomerInfo();
        const active = info.entitlements.active['pro'] !== undefined;
        if (active) {
          await AsyncStorage.setItem(STORAGE_KEYS.isPro, 'true');
          setIsPro(true);
          return true;
        }
      } catch {
        // RevenueCat non configuré
      }
    }

    setIsPro(false);
    return false;
  }, []);

  useEffect(() => {
    (async () => {
      if (Purchases && Platform.OS === 'ios' && !isExpoGo()) {
        try {
          await Purchases.configure({ apiKey: RC_API_KEY_IOS });
          const offerings = await Purchases.getOfferings();
          const pkg = offerings.current?.availablePackages.find(
            (p) => p.product.identifier === PRO_PRODUCT_ID
          );
          if (pkg) setPriceLabel(pkg.product.priceString);
        } catch {
          // Dev / sandbox
        }
      }
      await refreshProStatus();
      setLoading(false);
    })();
  }, [refreshProStatus]);

  const canCreateRelease = releaseCount < FREE_RELEASE_LIMIT || isPro;

  const needsPaywall = releaseCount >= FREE_RELEASE_LIMIT && !isPro;

  const purchasePro = useCallback(async (): Promise<boolean> => {
    if (isExpoGo() || Constants.appOwnership === 'expo') {
      await AsyncStorage.setItem(STORAGE_KEYS.isPro, 'true');
      setIsPro(true);
      return true;
    }

    if (!Purchases) return false;

    try {
      const offerings = await Purchases.getOfferings();
      const pkg =
        offerings.current?.availablePackages.find(
          (p) => p.product.identifier === PRO_PRODUCT_ID
        ) ?? offerings.current?.availablePackages[0];

      if (!pkg) return false;

      const { customerInfo } = await Purchases.purchasePackage(pkg);
      const active = customerInfo.entitlements.active['pro'] !== undefined;
      if (active) {
        await AsyncStorage.setItem(STORAGE_KEYS.isPro, 'true');
        setIsPro(true);
      }
      return active;
    } catch {
      return false;
    }
  }, []);

  const restorePurchase = useCallback(async (): Promise<boolean> => {
    if (isExpoGo()) {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.isPro);
      setIsPro(stored === 'true');
      return stored === 'true';
    }

    if (!Purchases) return false;

    try {
      const info = await Purchases.restorePurchases();
      const active = info.entitlements.active['pro'] !== undefined;
      if (active) {
        await AsyncStorage.setItem(STORAGE_KEYS.isPro, 'true');
        setIsPro(true);
      }
      return active;
    } catch {
      return false;
    }
  }, []);

  return {
    isPro,
    loading,
    priceLabel,
    canCreateRelease,
    needsPaywall,
    purchasePro,
    restorePurchase,
    refreshProStatus,
  };
}
