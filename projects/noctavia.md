# Noctavia (SleepLab)

**Suivi du sommeil avancé — iOS natif**

| | |
|---|---|
| Stack | Swift · SwiftUI · HealthKit · CoreMotion · AVFoundation · Widgets · Live Activities |
| Approche | Analyse on-device · export JSON local |
| iOS | 17+ |

## Problème résolu

Beaucoup d’apps sommeil se limitent à un score opaque. Noctavia croise capteurs iPhone, facteurs de vie (caféine, stress…) et corrélations locales pour proposer une **action concrète** le matin.

## Fonctionnalités clés

- HealthKit : FC, HRV, SpO2, respiration, sommeil, cycle
- Accéléromètre 10 Hz → phases de sommeil
- Surveillance audio / ronflements (AVFoundation)
- Réveil intelligent (fenêtre + sommeil léger)
- Corrélations Pearson locales (≥ 7 nuits)
- Dette de sommeil, Live Activity, widget score
- Nuit fractionnée, météo Open-Meteo

## Architecture

- Données et calculs sur l’appareil
- Widget + App Group
- CI : XcodeGen + GitHub Actions TestFlight

## Pourquoi c’est intéressant

- Projet **capteurs + HealthKit** (niveau senior iOS)
- Live Activities / widgets / CoreMotion
- Rigueur privacy (pas de cloud obligatoire)
