# CashTheTrain

**Monorepo iOS multi-apps + pipeline TestFlight unifié**

| | |
|---|---|
| Contenu | 10+ apps (SwiftUI, Expo, Flutter) |
| Repo | https://github.com/PrpleRat/CashTheTrain |
| CI | Un workflow TestFlight par app · secrets partagés |

## Apps du monorepo

| App | Techno | Rôle |
|-----|--------|------|
| BeatDeal | SwiftUI | Contrats de licence beats |
| BeatBill | Expo | Factures producteurs |
| DropDay | Expo | Planning de sorties |
| FactuTrain | SwiftUI | Facturation artisans |
| AgendaTrain | SwiftUI | Interventions terrain |
| TrainCRM | SwiftUI | CRM clients |
| TrainCA | SwiftUI | Comptabilité simplifiée |
| CarenceScan | SwiftUI | Bilan carences |
| Panium | SwiftUI | Handpan tactile |
| Noka / Noka Lite | Flutter | Apps complémentaires |

## Suite micro-entrepreneur

- App Group : `group.com.cashthetrain.suite`
- Sync événements JSON (factures payées, interventions → timeline CRM)
- Deep links : `factutrain://` · `agendatrain://` · `traincrm://` · `trainca://`

## Ingénierie CI

- Certificat Distribution + profils provisionnés une fois
- Scripts signing partagés dans `ci/`
- XcodeGen / `expo prebuild` en CI (projets Xcode non commités)
- Upload TestFlight via Fastlane / ASC API

## Pourquoi c’est intéressant

- Vision **écosystème produit**, pas une app isolée
- Compétence rare : industrialiser le release iOS multi-targets
- Architecture App Groups + deep links entre apps
