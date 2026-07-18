import { useCallback, useEffect, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { FREE_SPLIT_LIMIT, PRO_PRODUCT_ID, STORAGE_KEYS } from '@/constants/theme';
import { isNativeModulesLimited } from '@/utils/expoGo';

export function usePurchase() {
  const [isPro, setIsPro] = useState(false);
  const [loading, setLoading] = useState(true);
  const [price, setPrice] = useState('3,99 €');

  useEffect(() => {
    (async () => {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.isPro);
      setIsPro(stored === 'true');
      setLoading(false);

      if (!isNativeModulesLimited()) {
        try {
          const Purchases = require('react-native-purchases');
          const offerings = await Purchases.getOfferings();
          const pkg = offerings?.current?.lifetime ?? offerings?.current?.availablePackages?.[0];
          if (pkg?.product?.priceString) {
            setPrice(pkg.product.priceString);
          }
        } catch {
          // RevenueCat non configuré — prix par défaut
        }
      }
    })();
  }, []);

  const canCreateSplit = useCallback(
    (count: number) => isPro || count < FREE_SPLIT_LIMIT,
    [isPro]
  );

  const purchasePro = async (): Promise<boolean> => {
    if (!isNativeModulesLimited()) {
      try {
        const Purchases = require('react-native-purchases');
        const offerings = await Purchases.getOfferings();
        const pkg =
          offerings?.current?.availablePackages?.find(
            (p: { identifier: string }) => p.identifier === PRO_PRODUCT_ID
          ) ?? offerings?.current?.lifetime;

        if (pkg) {
          const { customerInfo } = await Purchases.purchasePackage(pkg);
          const unlocked =
            customerInfo.entitlements.active?.pro?.isActive ||
            customerInfo.nonSubscriptionTransactions?.some(
              (t: { productIdentifier: string }) => t.productIdentifier === PRO_PRODUCT_ID
            );
          if (unlocked) {
            await AsyncStorage.setItem(STORAGE_KEYS.isPro, 'true');
            setIsPro(true);
            return true;
          }
        }
      } catch {
        return false;
      }
    }

    await AsyncStorage.setItem(STORAGE_KEYS.isPro, 'true');
    setIsPro(true);
    return true;
  };

  const restorePurchase = async (): Promise<boolean> => {
    if (!isNativeModulesLimited()) {
      try {
        const Purchases = require('react-native-purchases');
        const customerInfo = await Purchases.restorePurchases();
        const unlocked =
          customerInfo.entitlements.active?.pro?.isActive ||
          customerInfo.nonSubscriptionTransactions?.some(
            (t: { productIdentifier: string }) => t.productIdentifier === PRO_PRODUCT_ID
          );
        if (unlocked) {
          await AsyncStorage.setItem(STORAGE_KEYS.isPro, 'true');
          setIsPro(true);
          return true;
        }
      } catch {
        // fall through
      }
    }

    const stored = await AsyncStorage.getItem(STORAGE_KEYS.isPro);
    if (stored === 'true') {
      setIsPro(true);
      return true;
    }
    return false;
  };

  return { isPro, loading, price, canCreateSplit, purchasePro, restorePurchase };
}
