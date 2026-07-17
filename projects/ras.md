# RAS — Fusée de détresse

**Sécurité personnelle — dead man’s switch iOS**

| | |
|---|---|
| Stack | Swift · SwiftUI · SwiftData · Face ID · notifications locales |
| Approche | 100 % on-device · pas de serveur |
| Bundle ID | `com.ras.fusee` |

## Concept

Tu confirmes régulièrement que tout va bien (**RAS** = *Rien À Signaler*). Sinon, tes contacts d’urgence sont alertés (SMS, email, position, 112).

## Fonctionnalités

- Sessions 15 min → 24 h (presets rando, trajet solo, travailleur isolé…)
- Vérification : Face ID, PIN, mot de passe, question secrète, bouton RAS
- Notifications planifiées + délai de grâce
- Contacts d’urgence + message personnalisé
- Historique local

## Pourquoi c’est intéressant

- Domaine **safety / privacy**
- Biométrie + notifications + SwiftData
- Produit clair, cas d’usage réel
