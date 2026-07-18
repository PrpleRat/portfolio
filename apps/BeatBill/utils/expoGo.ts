import Constants from 'expo-constants';

/** True when running inside the Expo Go app (not a dev/production build). */
export function isExpoGo(): boolean {
  return Constants.executionEnvironment === 'storeClient';
}

/** Dev / Expo Go: skip native-only features and use local mocks. */
export function isNativeModulesLimited(): boolean {
  return isExpoGo() || __DEV__;
}
