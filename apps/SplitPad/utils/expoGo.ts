import Constants from 'expo-constants';

export function isExpoGo(): boolean {
  return Constants.executionEnvironment === 'storeClient';
}

export function isNativeModulesLimited(): boolean {
  return isExpoGo() || __DEV__;
}
