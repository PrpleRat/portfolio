# BeatBill & DropDay

**Apps React Native / Expo pour la scène musicale indépendante**

## BeatBill — Facturation producteurs

| | |
|---|---|
| Stack | Expo · React Native · TypeScript · expo-print · AsyncStorage |
| Bundle ID | `com.cashthetrain.beatbill` |
| Repo | https://github.com/PrpleRat/BeatBill |

- Facture en 2 étapes + items audio pré-définis
- PDF local, devis, récurrentes, contrats, rapports
- Export JSON / CSV offline
- Deep link depuis BeatDeal : `beatbill://invoice?...`
- CI : `expo prebuild` → Xcode → TestFlight (**sans EAS**)

## DropDay — Planification de sorties

| | |
|---|---|
| Stack | Expo SDK · Expo Router · notifications locales · RevenueCat |
| Bundle ID | `com.cashthetrain.dropday` |

- Timeline inversée de release
- Budget promo, post-mortem, export PDF équipe
- 100 % offline · achat Pro unique

## Pourquoi c’est intéressant

- Même niveau de **rigueur release** que les apps Swift
- Preuve de polyvalence native + cross-platform
- Deep linking entre apps de l’écosystème
