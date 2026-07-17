# Portfolio — Développeur iOS · Mobile · Full-stack

> Apps natives iOS, React Native et sites web en production.  
> Toulouse · France · Disponible pour CDI / freelance / stage long

---

## Qui je suis

Développeur **produit** : je conçois, code, livre et maintiens des applications de bout en bout — du SwiftUI au pipeline TestFlight, du Next.js au déploiement Vercel.

Je construis surtout des apps **local-first** (données sur l’appareil, zéro serveur obligatoire) et des outils métier pour micro-entrepreneurs et créateurs.

| | |
|---|---|
| **Focus** | iOS (Swift / SwiftUI) · React Native (Expo) · Next.js |
| **Zone** | Toulouse / Occitanie · remote OK |
| **GitHub** | [github.com/PrpleRat](https://github.com/PrpleRat) |
| **Site live** | [voisintech.fr](https://www.voisintech.fr) |
| **Contact** | *à compléter : email / LinkedIn / téléphone* |

---

## Stack

```text
Mobile natif     Swift · SwiftUI · SwiftData · HealthKit · CoreMotion · AVFoundation · Widgets · Live Activities
Cross-platform   React Native · Expo · Expo Router · TypeScript
Web              Next.js · React · Prisma · Turso (SQLite) · Resend · Tailwind / Radix
CI / Release     GitHub Actions · Fastlane · XcodeGen · TestFlight · App Store Connect
Infra            Docker · Docker Compose · PWA · Vercel
```

---

## Projets phares

### 1. BeatDeal — Contrats de licence beats (iOS)

Application **Swift / SwiftUI** 100 % offline pour producteurs de musique : générateur de contrats PDF en moins de 60 secondes.

- 4 types de licence · PDF local · partage natif · catalogue beats · tracker de licences · royalties
- Deep links vers BeatBill / SplitPad · App Store (achat unique)
- CI : GitHub Actions → archive Xcode → TestFlight (sans Mac local)

**Repo :** [PrpleRat/BeatDeal](https://github.com/PrpleRat/BeatDeal) · [Détail](./projects/beatdeal.md)

---

### 2. Noctavia — Suivi du sommeil (iOS)

App **Swift / SwiftUI** basée sur les capteurs iPhone : HealthKit, CoreMotion, audio, corrélations locales, réveil intelligent, Live Activity, widget.

- Analyse on-device (Pearson, dette de sommeil, facteurs exogènes)
- Export / import JSON · météo Open-Meteo · zéro API payante

**Repo :** *SleepLab / Noctavia* · [Détail](./projects/noctavia.md)

---

### 3. TrajOc — Trajets Occitanie (iOS)

Planificateur multimodal : transports (Navitia), vélo partagé (JCDecaux), piéton / vélo (OpenRouteService), widget, alertes perturbations.

**Repo :** [PrpleRat/TrajOc](https://github.com/PrpleRat/TrajOc) · [Détail](./projects/trajoc.md)

---

### 4. BeatBill & DropDay — Productivité musique (React Native)

- **BeatBill** — factures / devis PDF pour producteurs (Expo, offline, deep link BeatDeal)  
  → [PrpleRat/BeatBill](https://github.com/PrpleRat/BeatBill)
- **DropDay** — planification de sorties musicales, budget promo, post-mortem PDF  

Même pipeline CI que les apps natives : `expo prebuild` → Xcode → TestFlight.

[Détail](./projects/beatbill-dropday.md)

---

### 5. CashTheTrain — Suite d’apps iOS + CI partagée

Monorepo de **10+ apps** (SwiftUI, Expo, Flutter) avec un seul jeu de secrets App Store Connect et des workflows TestFlight par app.

Inclut aussi une suite micro-entrepreneur : FactuTrain · AgendaTrain · TrainCRM · TrainCA (App Group + sync événements + deep links).

**Repo :** [PrpleRat/CashTheTrain](https://github.com/PrpleRat/CashTheTrain) · [Détail](./projects/cashthetrain.md)

---

### 6. VoisinTech — Site & back-office (Next.js)

Site vitrine + devis multi-étapes + admin pour une activité de dépannage informatique (Toulouse / Lourdes).

- Next.js · Prisma · Turso · Resend · formulaires accessibles (seniors)
- En production : [www.voisintech.fr](https://www.voisintech.fr)

**Repo :** [PrpleRat/voisintech-site](https://github.com/PrpleRat/voisintech-site) · [Détail](./projects/voisintech.md)

---

### 7. Autres apps iOS livrables

| App | Stack | Idée |
|-----|--------|------|
| **RAS** | SwiftUI · SwiftData | Dead man’s switch / alerte proches (GPS, SMS, Face ID) |
| **CarenceScan** | SwiftUI | Questionnaire symptômes → carences → PDF médecin, 100 % local |
| **Panium** | SwiftUI · AVAudio | Handpan tactile, polyphonie, reverb, offline |
| **Photo Space Cleaner** | Expo | Tri swipe de la photothèque, taille réelle, corbeille |

Fiches : [RAS](./projects/ras.md) · [CarenceScan](./projects/carencescan.md) · [Panium](./projects/panium.md)

---

## Ce que je cherche

- **Poste :** développeur iOS, mobile (RN), ou full-stack TypeScript
- **Environnement :** produit qui ship, ownership, qualité > volume de features
- **Points forts à exploiter :** apps offline / privacy, CI iOS, UX métier, shipping autonome

---

## Comment lire ce repo

1. Ce **README** = vue d’ensemble pour un recruteur (2 minutes)
2. Dossier [`projects/`](./projects/) = fiches techniques (stack, architecture, livrables)
3. Les repos liés = code réel, pipelines CI, README de prod

---

## Contact

```text
Email     : __________________
LinkedIn  : __________________
Téléphone : __________________
GitHub    : https://github.com/PrpleRat
```

*Remplace les lignes ci-dessus avant d’envoyer le lien aux recruteurs.*
