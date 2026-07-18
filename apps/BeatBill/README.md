# BeatBill

Application iOS (React Native / Expo) pour producteurs — factures pro en moins de 60 secondes.

**Modèle :** app payante App Store (pas d'achats in-app) · 100 % offline

## Fonctionnalités

- Création de facture en 2 étapes (client → items)
- Items pré-définis audio (mixing, mastering, beat lease, session…)
- Génération PDF locale (`expo-print`)
- Historique, devis, récurrentes, contrats PDF, rapports
- Lien BeatDeal : `beatbill://invoice?...`
- Export JSON / CSV

## Structure

```
BeatBill/
├── app/
├── components/
└── package.json
```

Repo dédié : https://github.com/PrpleRat/BeatBill

## Dev local

```bash
npm install
npm start
```

## CI / TestFlight

Pipeline partagé documenté dans le portfolio : `docs/ci-partage.md`  
(secrets App Store hors repo — non inclus ici)

## Licence

MIT — voir [LICENSE](LICENSE).
