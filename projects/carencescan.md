# CarenceScan

**Bilan de carences nutritionnelles — iOS**

| | |
|---|---|
| Stack | Swift · SwiftUI · moteur de scoring JSON · PDF |
| Approche | 100 % local · pas d’API externe |
| Bundle ID | `com.carencescan.app` |
| Repo | https://github.com/PrpleRat/CarenceScan |

## Flux

`Accueil → Profil → Questionnaire → Médicaments → Contextes → Résultats → PDF`

## Points techniques

- Base de règles versionnée (`carences_base.json`)
- Scoring : combinaisons, coefficients de fréquence, contextes médicaux
- Alertes (grossesse, fer, interactions)
- Export PDF partageable avec le médecin

## Pourquoi c’est intéressant

- Logique métier structurée (pas seulement UI)
- Santé + responsabilité produit (disclaimers, alertes)
- Offline-first
