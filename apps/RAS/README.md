# RAS — Fusée de détresse

**Application iOS de sécurité personnelle** — dead man's switch : tu confirmes régulièrement que tout va bien ; sinon, tes proches sont alertés (SMS, email, GPS, 112).

> **RAS** = *Rien À Signaler* — un appui, une fusée de détresse numérique pour ceux qui attendent de tes nouvelles.

## Fonctionnalités

- Sessions de 15 min à 24 h · presets rando, trajet solo, personne seule, travailleur isolé…
- Vérification : Face ID, PIN, mot de passe, question secrète, bouton **RAS**
- Notifications locales planifiées (rappel → échéance → alerte + délai de grâce)
- Contacts d'urgence · message personnalisé · SMS / email / position / Siri / 112
- Historique des sessions · **100 % on-device**, sans serveur

## Prérequis

- macOS · **Xcode 15+** · **iOS 17+**
- iPhone réel recommandé (biométrie, notifications)

## Installation

### XcodeGen

```bash
brew install xcodegen
cd RAS
xcodegen generate
open RAS.xcodeproj
```

### Manuel

1. Nouveau projet iOS **RAS** (SwiftUI + SwiftData)
2. Copier le dossier `RAS/` dans le target
3. `Info.plist`, `Resources/`
4. Bundle ID : `com.ras.fusee`

Ajoute `alert_sound.mp3` dans `RAS/Resources/` (voir `ALERT_SOUND.md`).

## App Store

| Champ | Valeur |
|-------|--------|
| **Nom** | RAS |
| **Sous-titre** | Fusée de détresse |
| **Bundle ID** | `com.ras.fusee` |
| **URL scheme** | `ras://checkin?sessionId=…&cycle=…` |

## Architecture

```
RAS/
├── RASApp.swift
├── Config/AppConstants.swift      # appName, appTagline
├── Models/ · Services/ · ViewModels/ · Views/
└── Resources/
```

## TestFlight (CI GitHub Actions)

Même pipeline que SleepLab / TrajOc :

1. **Une fois** : workflow `RAS — Bootstrap signing (sans Mac)` → secrets signing
2. **Chaque release** : workflow `RAS TestFlight` (manuel uniquement)

Guide détaillé : [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md)

| Workflow | Déclencheur |
|----------|-------------|
| `ras-ios.yml` | Manuel — build simulateur |
| `ras-bootstrap-signing.yml` | Manuel — certificat + profil |
| `ras-testflight.yml` | Manuel — IPA + TestFlight |

## Tests

```bash
xcodebuild test -scheme RAS -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Note marque

Le sigle **RAS** est aussi utilisé par [RandoAmisSecours](https://randoamissecours.org) (rando, web). Positionnement distinct : **app iOS**, check-in récurrent, fusée de détresse pour le grand public.

## Licence

MIT — voir [LICENSE](LICENSE).

## Avertissement

RAS est un outil de bien-être personnel. Il ne remplace pas un PLB, SPOT ou Garmin inReach. En urgence réelle : **112**.
