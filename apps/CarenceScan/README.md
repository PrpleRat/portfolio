# CarenceScan — Bilan carences & solutions

**Application iOS de santé** — questionnaire symptômes → carences probables → fiche PDF pour votre médecin.

> **100 % locale** — pas d'API, pas d'IA externe. Logique basée sur `carences_base.json` v1.2.

## Fonctionnalités (v1.2)

- **Profil** : sexe biologique, tranche d'âge, situation hormonale (femme)
- **Questionnaire** symptômes par catégories + **fréquence** (occasionnel / fréquent / constant)
- Médicaments dépleteurs + **10 contextes médicaux** (dépression, thyroïde, diabète…)
- Moteur de scoring : combinaisons, ajustements profil, coefficients fréquence, notes contexte
- Alertes médicales (grossesse, fer, ISRS/5-HTP)
- Export PDF partageable
- Persistance des derniers résultats (UserDefaults)

## Flux

`Accueil → Profil → Questionnaire → Médicaments → Contextes → Résultats`

## Prérequis

- macOS · **Xcode 15+** · **iOS 17+**
- iPhone (optimisé iOS first)

## Installation

```bash
brew install xcodegen
cd CarenceScan
python3 ci/generate-app-icons.py
xcodegen generate
open CarenceScan.xcodeproj
```

Bundle ID : `com.carencescan.app`

## Architecture

```
CarenceScan/
├── CarenceScanApp.swift
├── Config/AppConstants.swift
├── Theme/CarenceTheme.swift
├── Models/CarenceModels.swift
├── Services/          # Database, ScoringEngine, PDF, Storage
├── ViewModels/
├── Views/             # Home, Questionnaire, Medicaments, Results, Detail
└── Resources/carences_base.json
```

## Test de validation

Symptômes : gencives douloureuses, coins lèvres craquelés, crevasses doigts, peau sèche oreilles, fatigue intense, travail de nuit.

```bash
xcodebuild test -scheme CarenceScan -destination 'platform=iOS Simulator,name=iPhone 16'
```

## CI

| Workflow | Déclencheur |
|----------|-------------|
| `carencescan-ios.yml` | Manuel — build simulateur + tests scoring |

## Avertissement

CarenceScan est un **outil d'orientation**. Il ne remplace pas un avis médical. Consultez un professionnel de santé avant toute supplémentation.

## Licence

MIT — voir [LICENSE](LICENSE).
