# BeatDeal

**Contrats de licence de beats professionnels — iOS natif**

| | |
|---|---|
| Stack | Swift · SwiftUI · UIKit (PDF) · UserDefaults |
| Modèle | App payante App Store · 100 % offline |
| Bundle ID | `com.cashthetrain.beatdeal` |
| Repo | https://github.com/PrpleRat/BeatDeal |
| iOS | 17+ |

## Problème résolu

Les producteurs de beats enchaînent les contrats (lease / exclusive) à la main. BeatDeal génère un PDF juridique en 3 étapes, en moins d’une minute, sans compte ni serveur.

## Fonctionnalités clés

- Générateur en 3 étapes : type de licence → infos → droits
- 4 licences : MP3 Lease, WAV Lease, Trackout, Exclusive
- PDF A4 local + partage natif (AirDrop, Mail, Messages)
- Catalogue de beats, packs, calculateurs royalties
- Tracker de streams / expiration + notifications locales
- Split sheets studio, mode co-prod, DM kit
- Deep links : reçoit SplitPad (`beatdeal://split`) · exporte BeatBill (`beatbill://invoice`)

## Architecture

- Zéro backend — persistance locale
- HTML → PDF via UIKit
- Projet généré avec XcodeGen (`project.yml`)
- CI GitHub Actions : build simulateur + TestFlight (signing, Fastlane)

## Pourquoi c’est intéressant pour un recruteur

- App **produit réelle** (pas un tutoriel)
- Maîtrise SwiftUI + partage / PDF / deep links
- Pipeline release iOS industriel (Actions → TestFlight)
