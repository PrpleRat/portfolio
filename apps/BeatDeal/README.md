# BeatDeal

Application iOS native (Swift/SwiftUI) — générateur de contrats de licence de beats professionnels en moins de 60 secondes.

100 % offline · PDF local · App payante sur l'App Store.

## Fonctionnalités

- Générateur en 3 étapes : type de licence → infos artiste/beat/producteur → droits accordés
- 4 types de licence : MP3 Lease, WAV Lease, Trackout Lease, Exclusive
- PDF A4 généré localement (HTML → PDF via UIKit)
- Partage natif : iMessage, email, AirDrop
- Catalogue de beats, packs, calculateur de royalties
- Tracker de licences + notifications locales
- Split sheets, mode co-prod, DM kit
- Deep links : SplitPad → BeatDeal → BeatBill
- Zéro backend — UserDefaults + PDF temporaires

## Prérequis

- macOS avec Xcode 15+ (ou CI GitHub Actions)
- iOS 17+
- Compte Apple Developer pour TestFlight

## Installation (Mac)

```bash
brew install xcodegen
cd BeatDeal
xcodegen generate
open BeatDeal.xcodeproj
```

Sélectionner ta **Team** dans Signing & Capabilities, puis Build & Run.

## CI / TestFlight

Pipeline documenté dans le portfolio : `docs/ci-partage.md`  
(secrets hors repo — non inclus dans ce dossier)

## Licence

Voir [LICENSE](LICENSE).
