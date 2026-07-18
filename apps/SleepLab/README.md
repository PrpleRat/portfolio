# Noctavia

Application iOS native (Swift/SwiftUI) de suivi du sommeil — nom affiché **Noctavia** (projet Xcode interne : SleepLab).

## Fonctionnalités

- **HealthKit** : FC, HRV, SPO2, respiration, sommeil Apple, cycle menstruel
- **CoreMotion** : détection des phases via accéléromètre (10 Hz)
- **AVFoundation** : surveillance audio, ronflements, clips
- **Facteurs exogènes** : caféine, alcool, substances, stress, exercice, etc.
- **Réveil intelligent** : fenêtre + sommeil léger + mode secours
- **Corrélations locales** : Pearson on-device (7 nuits minimum)
- **Dette de sommeil** : cumul 7 nuits, objectif ajusté cycle, coucher conseillé
- **Action matinale** : une consigne concrète après chaque nuit (facteurs + dette + corrélations)
- **Sauvegarde JSON** : export / import local (nuits, journal, rêves, profil)
- **Nuit fractionnée** : pause réveil nocturne puis reprise (une seule nuit)
- **Live Activity** : phase + durée sur écran verrouillé, bouton Réveil
- **Météo** : Open-Meteo (gratuit)
- **Widget** : score de la dernière nuit
- **Zéro API payante** — données sur l’appareil

## Prérequis

- macOS avec **Xcode 15+**
- iPhone physique recommandé (capteurs + micro + HealthKit)
- iOS **17+**

## Import GitHub

**Pousse ce dossier comme racine du repo** (pas de dossier parent au-dessus).

```
SleepLab/                 ← racine du dépôt Git
├── .github/workflows/
├── project.yml
├── SleepLab/             ← code app
└── SleepLabWidget/
```

**Sans Mac (Windows)** : **[.github/SETUP-WINDOWS.md](.github/SETUP-WINDOWS.md)**  
Référence technique : **[.github/SETUP.md](.github/SETUP.md)**

## CI GitHub Actions

| Workflow | Rôle |
|----------|------|
| `sleeplab-ios.yml` | Build simulateur |
| `sleeplab-bootstrap-signing.yml` | Cert + profils (sans Mac, une fois) |
| `sleeplab-testflight.yml` | IPA + TestFlight |

Guide Windows : **[.github/SETUP-WINDOWS.md](.github/SETUP-WINDOWS.md)**

## Installation

### Option A — XcodeGen (recommandé)

```bash
brew install xcodegen   # si nécessaire
xcodegen
open SleepLab.xcodeproj
```

1. Sur [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list) :
   - **App Group** : `group.com.prple.sleeplab`
   - **App ID** app : `com.prple.sleeplab` (HealthKit + App Groups)
   - **App ID** widget : `com.prple.sleeplab.widget` (App Groups)
2. Sélectionne ta **Team** dans Signing & Capabilities (cibles SleepLab + widget).
3. Active **HealthKit** et **App Groups** (`group.com.prple.sleeplab`) sur les deux cibles — même identifiant de groupe que sur le portail.
4. Ajoute les fichiers MP3 de réveil dans `SleepLab/Resources/Sounds/` (voir README dans ce dossier).
5. Build & run sur iPhone.

### Option B — Projet Xcode manuel

1. **File → New → Project → App** (SwiftUI, SwiftData).
2. Nom : SleepLab, iOS 17.
3. Glisse le dossier `SleepLab/` (sources) dans le projet.
4. Remplace `Info.plist` et ajoute `SleepLab.entitlements`.
5. Ajoute une extension **Widget Extension** et copie `SleepLabWidget/`.
6. Capabilities : HealthKit, Background Modes (audio, processing), App Groups.

## Structure

```
./
├── .github/               # CI + SETUP.md
├── SleepLab/              # App principale
├── SleepLabWidget/        # Widget
├── project.yml
├── ExportOptions.plist
└── README.md
```

`SleepLab.xcodeproj` est généré par XcodeGen — ne pas le committer (`.gitignore`).

## Utilisation

1. Configure le **profil** (objectif de sommeil, cycle si besoin).
2. **Commencer la nuit** → saisie rapide des facteurs → tracking.
3. Pose l’iPhone sur le **matelas**, écran vers le bas.
4. Au réveil : rapport, hypnogramme, sons, insights (après 7 nuits).

## Avertissement

SleepLab est un **outil de bien-être**, pas un dispositif médical. En cas de troubles du sommeil (apnée, insomnie chronique), consulte un professionnel de santé.

## Tests sur simulateur

- HealthKit et micro sont limités sur simulateur.
- Le motion tracking fonctionne partiellement ; privilégie un **appareil réel** pour valider une nuit complète.
