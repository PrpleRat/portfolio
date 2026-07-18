# TrajOc

Application iOS native (Swift/SwiftUI) — **planificateur de trajets Occitanie** (transports, vélo partagé, itinéraires multi-étapes).

## Fonctionnalités

- **Navitia** : horaires et itinéraires TC (SNCF, TER, métro, bus)
- **OpenRouteService** : calcul piéton / vélo
- **JCDecaux** : stations vélo partagé (Toulouse, Montpellier, Nîmes, Perpignan…)
- **Carte Occitanie** : recherche d’adresses (Nominatim), favoris
- **Alertes perturbations** : notifications + tâche en arrière-plan
- **Widget** : trajet favori sur l’écran d’accueil
- **App Group** : données partagées app ↔ widget

## Prérequis

- macOS avec **Xcode 15+**
- iPhone physique recommandé (localisation, notifications)
- iOS **17+**

## Import GitHub

**Pousse ce dossier comme racine du repo** (pas de dossier parent au-dessus).

```
TrajOc/                   ← racine du dépôt Git
├── .github/workflows/
├── project.yml
├── TrajOc/               ← code app
└── TrajOcWidget/
```

## CI GitHub Actions

| Workflow | Rôle |
|----------|------|
| `trajoc-ios.yml` | Build simulateur |
| `trajoc-bootstrap-signing.yml` | Cert + profils (sans Mac, une fois) |
| `trajoc-testflight.yml` | IPA + TestFlight |

## Installation

### Option A — XcodeGen (recommandé)

```bash
brew install xcodegen   # si nécessaire
bash ci/ensure-release-xcconfig.sh   # requis une fois (fichiers Release pour XcodeGen)
xcodegen
open TrajOc.xcodeproj
```

1. Sur [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list) :
   - **App Group** : `group.com.trajoc.shared`
   - **App ID** app : `com.trajoc.app` (App Groups, Push Notifications, Background Modes)
   - **App ID** widget : `com.trajoc.app.widget` (App Groups)
2. Sélectionne ta **Team** dans Signing & Capabilities (cibles TrajOc + widget).
3. Active **App Groups** (`group.com.trajoc.shared`) sur les deux cibles.
4. Copie `TrajOc/Config/APIKeys.example.swift` → `TrajOc/Config/APIKeys.swift` et renseigne tes clés API.
5. Build & run sur iPhone.

### Option B — Projet Xcode manuel

1. **File → New → Project → App** (SwiftUI).
2. Nom : TrajOc, iOS 17.
3. Glisse le dossier `TrajOc/` (sources) dans le projet.
4. Remplace `Info.plist` et ajoute `TrajOc.entitlements`.
5. Ajoute une extension **Widget Extension** et copie `TrajOcWidget/`.
6. Capabilities : Background Modes (fetch, processing), App Groups, Location.

## Structure

```
./
├── .github/workflows/
├── TrajOc/               # App principale
├── TrajOcWidget/         # Widget
├── ci/                   # Scripts signing + icônes
├── project.yml
├── ExportOptions.plist
└── README.md
```

`TrajOc.xcodeproj` est généré par XcodeGen — ne pas le committer (`.gitignore`).

## Clés API (obligatoire pour TestFlight fonctionnel)

Inscription gratuite, puis ajoute ces **secrets GitHub** (Settings → Secrets → Actions) :

| Secret | Où l'obtenir |
|--------|----------------|
| `SNCF_API_KEY` | [numerique.sncf.com/startup/api](https://numerique.sncf.com/startup/api/) — **gratuit** 150k req/mois (trains, TER) |
| `ORS_API_KEY` | [account.heigit.org](https://account.heigit.org/manage/key) — voiture, vélo, marche |
| `JCDECAUX_API_KEY` | [developer.jcdecaux.com](https://developer.jcdecaux.com) — vélos |

(`NAVITIA_API_KEY` accepté en alias de `SNCF_API_KEY` si tu en as déjà un.)

Le workflow **TestFlight** injecte ces clés dans l'app au build. Sans elles, l'app s'installe mais les itinéraires échouent.

En local : copie `TrajOc/Config/APIKeys.example.swift` → `APIKeys.swift` et renseigne tes clés.

## Avertissement

TrajOc est un **outil d’aide à la mobilité**. Les horaires et perturbations proviennent de services tiers — vérifie toujours les informations officielles des transporteurs avant un déplacement.
