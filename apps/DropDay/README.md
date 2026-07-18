# DropDay â€” planification de sorties musicales (React Native + Expo)

**Bundle ID :** `com.Enzo Jouet.dropday`

App iOS pour artistes indÃ©pendants : timeline inversÃ©e de release, budget promo, post-mortem et export PDF Ã©quipe. **100 % offline** Â· achat unique Pro.

## Stack

- Expo SDK 56 + Expo Router
- AsyncStorage (donnÃ©es locales)
- Notifications locales contextuelles
- RevenueCat (`dropday_pro`) â€” 1 release gratuite
- PDF via `expo-print`

## Dev local

```bash
npm install
npm start
```

## CI / TestFlight

MÃªme pipeline que **BeatBill** / **BeatDeal** : GitHub Actions sur `macos-15`, `expo prebuild`, archive Xcode, upload TestFlight â€” **sans EAS**.

Voir [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md).

## Licence

MIT â€” Enzo Jouet
