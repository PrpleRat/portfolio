# Panium

Application iOS native (Swift/SwiftUI) — handpan tactile minimaliste.

Port Swift du projet Flutter `panium` : 7 gammes, 3 niveaux de reverb, accord 440/432 Hz, layout standard (centre + anneau).

## Fonctionnalités

- 7 gammes sélectionnables (Minor Aeolian par défaut)
- 3 niveaux de reverb (variantes WAV `_v0` / `_v1` / `_v2`)
- Accord 440 Hz ou 432 Hz
- Labels pads : off / numéro / nom de note
- Vélocité optionnelle selon la position du toucher
- Polyphonie jusqu'à 32 notes simultanées (`AVAudioPlayer`)
- 100 % offline — aucun serveur

## Prérequis

- macOS avec **Xcode 15+**
- iPhone physique recommandé (latence audio)
- iOS **17+**
- Fichiers WAV dans `Panium/Resources/Sounds/` (voir README du dossier)

## Import GitHub

**Pousse ce dossier comme racine du repo** (pas de dossier parent).

```
Panium/                 ← racine du dépôt Git
├── .github/workflows/
├── project.yml
├── Panium/             ← code app
└── PaniumTests/
```

`Panium.xcodeproj` est généré par XcodeGen — ne pas le committer (`.gitignore`).

## Installation (Mac)

### Option A — XcodeGen (recommandé)

```bash
brew install xcodegen
cd Panium
python3 ci/generate-app-icons.py
xcodegen generate
open Panium.xcodeproj
```

1. Copier les WAV : `sons_en_wave/*.wav` → `Panium/Resources/Sounds/`
2. Sélectionner ta **Team** dans Signing & Capabilities
3. Bundle ID : `com.prple.panium`
4. Build & Run sur iPhone

### Option B — Sans Mac (Windows)

1. Pousser le repo sur GitHub
2. Configurer Apple Developer + secrets GitHub (voir [docs/APPLE-DEVELOPER-SETUP.md](docs/APPLE-DEVELOPER-SETUP.md))
3. Lancer **Panium TestFlight** depuis GitHub Actions

## CI GitHub Actions

| Workflow | Rôle |
|----------|------|
| `panium-ios.yml` | Build simulateur (manuel) |
| `panium-bootstrap-signing.yml` | Cert + profils (sans Mac, une fois) |
| `panium-testflight.yml` | IPA + TestFlight |

Guide détaillé : [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md)

## Structure

```
./
├── .github/               # CI
├── Panium/                # App principale
│   ├── Config/
│   ├── Data/
│   ├── Models/
│   ├── Services/          # Audio + playback glow
│   ├── Theme/
│   ├── Views/
│   └── Resources/Sounds/  # WAV (à copier)
├── PaniumTests/
├── ci/
├── fastlane/
├── project.yml
└── README.md
```

## App Store

| Champ | Valeur |
|-------|--------|
| **Nom** | Panium |
| **Sous-titre** | Handpan tactile |
| **Bundle ID** | `com.prple.panium` |
| **Catégorie** | Musique |

## Tests

```bash
xcodebuild test -scheme Panium -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Licence

MIT — voir [LICENSE](LICENSE).
