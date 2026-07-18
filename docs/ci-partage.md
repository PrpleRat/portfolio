# Pipeline CI / build iOS partagé

Description **architecture uniquement** — aucune clé, certificat, Team ID ou secret n’est publié ici.

## Objectif

Livrer plusieurs apps iOS (SwiftUI et Expo) vers **TestFlight** avec le même schéma de CI, sans Mac local obligatoire.

## Schéma

```text
Push / workflow_dispatch
        │
        ▼
┌───────────────────┐
│ Runner macOS      │
│ - checkout        │
│ - XcodeGen ou     │
│   expo prebuild   │
│ - archive IPA     │
│ - upload TF       │
└───────────────────┘
        │
        ▼
   App Store Connect
   (TestFlight)
```

## Principes

1. **Projets Xcode générés en CI** — `project.yml` (XcodeGen) ou `ios/` via `expo prebuild` ; pas de `.xcodeproj` lourd versionné.
2. **Secrets hors repo** — certificats Distribution, clé API App Store Connect, mots de passe trousseau : uniquement dans les secrets GitHub du dépôt privé de build.
3. **Workflows par app** — un workflow TestFlight par application, même structure (checkout → deps → build → upload).
4. **Build simulateur séparé** — un workflow « ios » pour valider la compile sans signing Distribution.

## Stack CI typique

| Étape | Outils |
|-------|--------|
| Génération projet | XcodeGen / Expo prebuild |
| Build | `xcodebuild` archive |
| Signing | certificat + profils fournis au runner (secrets) |
| Upload | `xcrun altool` / Fastlane `upload_to_testflight` / ASC API |
| Orchestration | GitHub Actions (`macos-14` / `macos-15`) |

## Ce qui a été retiré de ce portfolio

Pour éviter toute fuite :

- fichiers `.p8` / `.p12` / profils `.mobileprovision`
- Team ID Apple réel (remplacé par `YOUR_TEAM_ID` là où un placeholder reste)
- scripts de bootstrap signing et Fastlane liés aux secrets
- `ExportOptions.plist` contenant l’identité de signing
- clés API runtime (ex. TrajOc : seul `APIKeys.example.swift` est fourni)

## Reproduire chez soi

1. Créer un Apple Developer Team
2. Ajouter les secrets nécessaires dans GitHub (jamais dans le code)
3. Adapter `DEVELOPMENT_TEAM` / `appleTeamId` à **ton** Team ID
4. Lancer le workflow TestFlight de l’app concernée

Les workflows restants dans `apps/*/`.github/workflows/` sont des **exemples de structure** ; les valeurs sensibles doivent venir de ton propre environnement.
